# author: Steve Harris
# date: 2015-11-27
# subject: Results - numbers

# Todo
# ====
# TODO: 2015-11-05 - [ ] put back under waf control?

# Log
# ===
# 2015-10-09
# - duplicated from 150803
# 2015-11-05# 
# - moved from labbooks and renamed 
# - will now use this to keep track of numbers for the results
# 2015-11-27
# - cloned from paper-spotearly

# Readme
# ======
# - aim to move this into R markdown version of results
# - keep organised by paragraph

# Notes
# =====
# - redefine room_cmp as encourage with broader bands
# - use full population and focus on decision making

# Set-up 
# ======
rm(list=ls(all=TRUE))
setwd('/Users/steve/aor/academic/paper-spotepi/src/analysis')
source("project_paths.r")

# Load libraries
library(assertthat)
library(Hmisc)
library(foreign)
library(data.table)
library(gmodels)
library(datascibc)
library(boot)
library(dplyr)

source(paste0(PATH_SHARE, "/functions4rmd.R"))    # Rmd functions
source(paste0(PATH_SHARE, "/derive.R"))

# Load data
# NOTE: 2015-11-05 - [ ] removed from waf control
load(paste0(PATH_DATA, '/paper-spotepi.RData'))
wdt.original <- wdt
tt <- list()                            # empty list to store rmd vars


# Data defintions
wdt[, recommend := ifelse(icu_recommend==1 & rxlimits==0,1,0)]
wdt[, ward := ifelse(icu_recommend==0 & rxlimits==0,1,0)]
wdt[, accept := ifelse(icu_recommend==1 & rxlimits==0 & icu_accept,1,0)]
wdt[, room_cmp2 := cut2(open_beds_cmp, c(1,3), minmax=T )]

#  ===================
#  = Results - intro =
#  ===================
# - data linkage quality
# - consort/strobe diagram stuff

# How many patients and sites
dim(wdt)
nrow(wdt)
length(unique(wdt$icode))
# Data linkage
summary(wdt[,.(min(match_quality_by_site)),by=.(icode,studymonth)][,V1])
str(wdt.sites)

#  =======================
#  = Hospitals and sites =
#  =======================
teach <- ff.np('teaching', data=wdt.sites)
# same as above but using dplyr
tdt <- distinct(select(wdt,icode,teaching_hosp))
with(tdt, CrossTable(teaching_hosp, prop.chisq=F, prop.t=F))

summary(wdt.sites$patients)
pts_q <- ff.mediqr('patients', data=wdt.sites, dp=0)
pts_q
summary(wdt.sites$studymonths_n)
smonths <- ff.mediqr('studymonths_n', data=wdt.sites, dp=0)
smonths
summary(wdt.sites$pts_by_hes_n)
pts_overnight <- ff.mediqr('pts_by_hes_n', data=wdt.sites, dp=0)
pts_overnight
# Overnight admissions per month by CCOT provision
with(wdt.sites, tapply(pts_by_hes_n, ccot, summary))

# Critical care outreach
with(wdt.sites, CrossTable(ccot, prop.chisq=F, prop.t=F))
beds <- ff.mediqr('cmp_beds_persite', data=wdt.sites, dp=0)
beds
colocate <- ff.np('units_incmp', data=wdt.sites, dp=0)

tt$tails_all <- wdt.sites[,
    (cmp_patients_permonth*tails_all_percent/100)]
tails_all <- ff.mediqr('tails_all', data=tt, dp=0)
tails_all
tails_p <- ff.mediqr('tails_all_percent', data=wdt.sites, dp=0)
tails_p

#  ======================================
#  = Effects of critical care occupancy =
#  ======================================

with(wdt, CrossTable(room_cmp2, prop.chisq=F, prop.t=F, chisq = T))

# Occupancy and effects on Rx
with(wdt,
     CrossTable(room_cmp2, rxlimits,
                prop.chisq=F, prop.t=F, chisq = T))

with(wdt[rxlimits==0],
     CrossTable(room_cmp2, icu_recommend,
                prop.chisq=F, prop.t=F, chisq = T))


# Report model effect to compare ims_delta with baseline
# Using this as a factor loses the advantage of the ordered trend assessment
with(wdt[rxlimits==0 & recommend==1], tapply(ims_delta, room_cmp2, summary))
wdt[, room_cmp2 := relevel(room_cmp2, ref="[ 3,21]")]
m <- lm(ims_delta ~ room_cmp2, data=wdt[rxlimits==0 & recommend==1])
summary(m)


#  ===========================
#  = Patient characteristics =
#  ===========================
summary(wdt$age)
tt$sepsis <- data.table(sepsis = wdt[,ifelse(sepsis %in% c(3,4),1,0)])
sepsis <- ff.np('sepsis', data=tt$sepsis, dp=0)
ssite <- ff.np('sepsis_site', data=wdt[sepsis %in% c(3,4)], dp=0)

wdt[, sofa2.r := gen.sofa.r(pf, fio2_std)]
wdt[, odys := ifelse(
    (sofa_score>1 & sofa_r <= 1) |
    (!is.na(sofa2.r) & sofa2.r > 1),1,0)]
odys <- ff.np('odys', data=wdt, dp=0)

tt$rdys <- data.table(rdys=wdt[, ifelse(!is.na(sofa2.r) & sofa2.r>1, 1,0)])
rdys <- ff.np('rdys', data=tt$rdys, dp=0)
tt$kdys <- data.table(kdys = wdt[,ifelse(sofa_k>1,1,0)])
kdys <- ff.np('kdys', data=tt$kdys, dp=0)

tt$shock <- data.table(shock = wdt[,
    ifelse(   (!is.na(bpsys) & bpsys<90 )
            | (!is.na(bpmap) & bpmap<70 )
            | (!is.na(lactate) & lactate > 2.5 )
            | (!is.na(rxcvs_sofa) & rxcvs_sofa > 1)
            ,1,0)])
shock <- ff.np('shock', data=tt$shock, dp=0)
describe(wdt$sepsis_severity)
  # fname: sepsis_severity
  # sqltype: tinyint
  # varlab: Sepsis status
  # tablerowlabel:
  #   latex: Sepsis status
  # vallab:
  #   0: Neither SIRS nor sepsis
  #   1: SIRS
  #   2: Sepsis
  #   3: Severe sepsis
  #   4: Septic shock
describe(wdt[sepsis_severity==4]$sepsis2001)
  # vallab:
  #   0: No
  #   1: SIRS
  #   2: Sepsis
  #   3: Severe sepsis
  #   4: Septic shock - hypotension alone
  #   5: Septic shock - hypoperfusion alone
  #   6: Septic shock - hypotension and hypoperfusion


wdt[, osupp := ifelse( rxrrt==1 | rx_resp==2 | rxcvs == 2,1,0)]
osupp <- ff.np('osupp', data=wdt, dp=0)

#  =======================
#  = Severity of illness =
#  =======================
                     
aps.news <- ff.mediqr('news_score')
aps.news
aps.sofa <- ff.mediqr('sofa_score')
aps.sofa
aps.icnarc <- ff.mediqr('icnarc_score')
aps.icnarc

describe(wdt$news_risk)

dead2 <- ff.np('dead2', dp=1)
dead7.d2 <- ff.np('dead2', dp=1, data=wdt[dead7==1])
dead7 <- ff.np('dead7', dp=1)
dead1y <- ff.np('dead1y', dp=1)
dead90.wk1 <- ff.np('dead7', dp=1, data=wdt[dead90==1])

# Associations with severity

#  =================================
#  = Pathways following assessment =
#  =================================


#  ==================================
#  = Patients with treatment limits =
#  ==================================
rxlimits <- ff.np('rxlimits', data=wdt, dp=0)

age.by.rxlimits <- t.test.format(wdt, 'age', 'rxlimits', dp=0)
age.by.rxlimits

sofa.by.rxlimits <- t.test.format(wdt, 'sofa_score', 'rxlimits', dp=1)
sofa.by.rxlimits

dead7.rxlimits <- ff.np('dead7', dp=1, data=wdt[rxlimits==1])
dead90.rxlimits <- ff.np('dead90', dp=1, data=wdt[rxlimits==1])
dead1y.rxlimits <- ff.np('dead1y', dp=1, data=wdt[rxlimits==1])

#  ========================================================
#  = Patients without Rx limits recommended **WARD** care =
#  ========================================================
ward <- ff.np('ward', dp=1, data=wdt)

age.by.ward <- t.test.format(wdt[rxlimits==0], 'age', 'ward', dp=1)
age.by.ward
sofa.by.ward <- t.test.format(wdt[rxlimits==0], 'sofa_score', 'ward', dp=1)
sofa.by.ward

recommend <- ff.np('recommend', dp=1, data=wdt)
dead7.ward <- ff.np('dead7', dp=1, data=wdt[ward==1])
with(wdt[rxlimits==0], CrossTable(dead7, recommend, prop.chisq=F, prop.t=F, chisq=T))


wdt[,alive7noICU := ifelse(dead7==0 & icucmp==0,1,0)]
alive7noICU.ward <- ff.np('alive7noICU', dp=1, data=wdt[ward==1])
icucmp.ward <- ff.np('icucmp', dp=1, data=wdt[ward==1])
icucmp.reassess <- ff.np('icu_accept', dp=1, data=wdt[ward==1 & icucmp==1])
wdt[,dead7noICU := ifelse(dead7==1 & icucmp==0,1,0)]
dead7noicu.ward <- ff.np('dead7noICU', dp=1, data=wdt[ward==1])


#  =============================================
#  = Patients recommended to **CRITICAL** care =
#  =============================================
recommend <- ff.np('recommend', dp=1, data=wdt)
accept <- ff.np('accept', dp=1, data=wdt[recommend==1])

# characteristics of those accepted
with(wdt[recommend==1], tapply(age, accept, summary))
age.by.accept <- t.test.format(wdt[recommend==1], 'age', 'accept', dp=1)
age.by.accept
sofa.by.accept <- t.test.format(wdt[recommend==1], 'sofa_score', 'accept', dp=1)
sofa.by.accept
with(wdt[recommend==1], CrossTable(dead7, accept, prop.chisq=F, prop.t=F, chisq=T))
with(wdt[recommend==1 & accept==1], CrossTable(dead7, icucmp, prop.chisq=F, prop.t=F, chisq=T))

# outcomes for those recommended but not accepted
alive7noICU.rec1.acc0 <- ff.np('alive7noICU', dp=1, data=wdt[recommend==1 & accept==0])
icucmp.rec1.acc0 <- ff.np('icucmp', dp=1, data=wdt[recommend==1 & accept==0])
dead7noicu.rec1.acc0 <- ff.np('dead7noICU', dp=1, data=wdt[recommend==1 & accept==0])

#  =======================================
#  = Delay to admission to critical care =
#  =======================================
# TODO: 2015-11-12 - [ ] redo below after excluding deaths at assesment and theatre admissions

wdt[,.N,by=elgthtr]
wdt[,.N,by=v_disposal]
wdt.timing <- wdt[is.na(elgthtr) | elgthtr ==0]

time2icu <- ff.mediqr('time2icu', data=wdt.timing, dp=0)
time2icu
early4 <- ff.np('early4', wdt.timing[icucmp==1])

# Recommended and accepted
time2icu.acc1 <- ff.mediqr('time2icu', data=wdt.timing[recommend==1 & accept==1], dp=0)
time2icu.acc1
early4.acc1 <- ff.np('early4', wdt.timing[icucmp==1 & recommend==1 & accept==1])

# Recommended not accepted
time2icu.rec1.acc0 <- ff.mediqr('time2icu', data=wdt.timing[recommend==1 & accept==0], dp=0)
time2icu.rec1.acc0
early4.rec1.acc0 <- ff.np('early4', wdt.timing[icucmp==1 & recommend==1 & accept==0])

# Not recommended but later admitted
time2icu.ward <- ff.mediqr('time2icu', data=wdt.timing[ward==1], dp=0)
time2icu.ward
early4.ward <- ff.np('early4', wdt.timing[icucmp==1 & ward==1])







#  =======================
#  = END OF CURRENT WORK =
#  =======================


stop()
# Define your variables
# ---------------------
vars.patient    <- c("age80m", "age80p", "male", "sepsis_dx", "v_ccmds",
      "v_ccmds_rec",
      "delayed_referral", "periarrest", "icnarc_score")
vars.timing     <- c("out_of_hours", "weekend", "winter")
vars            <- c(vars.patient)

# Model specification
# -------------------
wdt[, `:=`(
age_k               = relevel(factor(age_k), 2),
v_ccmds             = relevel(factor(v_ccmds), 2),
sepsis_dx           = relevel(factor(sepsis_dx), 1),
room_cmp            = relevel(factor(room_cmp), 3),
icode               = factor(icode)
)]

tdt.reco[, `:=`(
age_k               = relevel(factor(age_k), 2),
v_ccmds             = relevel(factor(v_ccmds), 2),
sepsis_dx           = relevel(factor(sepsis_dx), 1),
room_cmp            = relevel(factor(room_cmp), 3),
icode               = factor(icode)
)]

f.icu_recommend <- reformulate(termlabels = c(vars), response = 'icu_recommend')
f.icu_accept <- reformulate(termlabels = c("icu_accept", vars), response = 'dead90')
f.early4 <- reformulate(termlabels = c("early4", vars), response = 'dead90')

# Run your model
# --------------
m <- glm(f.icu_recommend , family = 'binomial', data = wdt[rxlimits==0])
summary(m)
library(MASS)
library(lme4)
library(ggplot2)
install.packages("GGally")
library(GGally)
confint(m)

stop()
# Modelling should exclude patients with treatment limits
tdt <- wdt[rxlimits == 0]

# Redefine room_cmp
# -----------------
# cut2 intervals are [) specified (i.e. a <= x < b)
wdt[, room_max := cut2(open_beds_max, c(1,3), minmax=T )]
wdt[,.N,by=room_max]
str(wdt$room_max)
wdt[, room_max := factor(room_max, labels=c(0,1,2))]

wdt[, room_cmp2 := cut2(open_beds_cmp, c(1,3), minmax=T )]
wdt[,.N,by=room_cmp2]
wdt[, room_cmp2 := factor(room_cmp2, labels=c(0,1,2))]
wdt[,.N,by=room_cmp2]

# Redefine beds_none
# ------------------
wdt[,.N,by=beds_none]

# Patients offerec critical care sicker and younger
with(wdt, CrossTable(dead7, icu_recommend, prop.chisq=F, prop.t=F))
with(wdt, tapply(icnarc0, icu_recommend, summary))
with(wdt, tapply(age, icu_recommend, summary))

# Compare to room_cmp (which uses open_beds_cmp not open_beds_max)
with(wdt, CrossTable(room_cmp, room_max))
with(wdt, CrossTable(room_cmp2, room_cmp))

# Show that this defines recommendation, decision, delivery
with(wdt, CrossTable(icu_recommend, room_cmp, prop.chisq=F, prop.t=F))
with(wdt, CrossTable(icu_recommend, room_cmp2, prop.chisq=F, prop.t=F))
with(wdt, CrossTable(icu_recommend, beds_none, prop.chisq=F, prop.t=F))

with(wdt, CrossTable(icu_accept, room_cmp, prop.chisq=F, prop.t=F))
with(wdt, CrossTable(icu_accept, room_cmp2, prop.chisq=F, prop.t=F))
with(wdt, CrossTable(icu_accept, beds_none, prop.chisq=F, prop.t=F))

with(wdt, CrossTable(early4, room_cmp, prop.chisq=F, prop.t=F))
with(wdt, CrossTable(early4, room_cmp2, prop.chisq=F, prop.t=F))
with(wdt, CrossTable(early4, beds_none, prop.chisq=F, prop.t=F))

with(wdt, CrossTable(dead7, room_cmp, prop.chisq=F, prop.t=F))
with(wdt, CrossTable(dead7, room_cmp2, prop.chisq=F, prop.t=F))
with(wdt, CrossTable(dead7, beds_none, prop.chisq=F, prop.t=F))
with(wdt[icu_recommend==1 & rxlimits==0], CrossTable(dead7, room_cmp2, prop.chisq=F, prop.t=F))
with(wdt[icu_recommend==1 & rxlimits==0], CrossTable(dead7, beds_none, prop.chisq=F, prop.t=F))

with(wdt, CrossTable(dead90, room_cmp, prop.chisq=F, prop.t=F))
with(wdt, CrossTable(dead90, room_cmp2, prop.chisq=F, prop.t=F))
with(wdt, CrossTable(dead90, beds_none, prop.chisq=F, prop.t=F))
with(wdt[icu_recommend==1 & rxlimits==0], CrossTable(dead90, room_cmp2, prop.chisq=F, prop.t=F))
with(wdt[icu_recommend==1 & rxlimits==0], CrossTable(dead90, beds_none, prop.chisq=F, prop.t=F))

with(wdt, CrossTable(rxlimits, room_cmp, prop.chisq=F, prop.t=F))
with(wdt, CrossTable(rxlimits, room_cmp2, prop.chisq=F, prop.t=F))
with(wdt, CrossTable(rxlimits, beds_none, prop.chisq=F, prop.t=F))



with(wdt, tapply(time2icu, room_cmp, summary))
with(wdt, tapply(time2icu, room_cmp2, summary))
with(wdt, tapply(time2icu, beds_none, summary))


# Define your variables
# ---------------------
vars.patient    <- c("age80m", "age80p", "male", "sepsis_dx", "v_ccmds",
                "v_ccmds_rec",
                "delayed_referral", "periarrest", "icnarc_score")
vars.timing     <- c("out_of_hours", "weekend", "winter")
vars            <- c(vars.patient)

# Model specification
# -------------------
tdt[, `:=`(
    age_k               = relevel(factor(age_k), 2),
    v_ccmds             = relevel(factor(v_ccmds), 2),
    sepsis_dx           = relevel(factor(sepsis_dx), 1),
    room_cmp            = relevel(factor(room_cmp), 3),
    icode               = factor(icode)
    )]

f.early4 <- reformulate(termlabels = c("early4", vars), response = 'dead90')
f.icu_accept <- reformulate(termlabels = c("icu_accept", vars), response = 'dead90')

# Run your model
# --------------
m <- glm(f.icu_accept , family = 'binomial', data = tdt)
summary(m)
m <- glm(f.icu_accept , family = 'binomial', data = tdt[icu_recommend==1])
summary(m)

m <- glm(f.early4 , family = 'binomial', data = tdt.rec)
summary(m)

# TODO: 2015-08-04 - [ ] define steps in the pathway to be reported and followed
# ------------------------------------------------------------------------------
# - week one pathways
# - primary outcome
# - one year survival


# Pathway steps
# - report 7 day mortality as marker of severity
with(tdt.rec, CrossTable(grp, dead7))

# Pathway for potential admissions
#   - immediate offers
#   - late offers
#   - dead without critical care

# - all (no rxlimits - comparison of recommended and controls
with(tdt, CrossTable(icu_accept))
with(tdt, CrossTable(icu_accept, icucmp))
with(tdt, CrossTable(icu_accept, dead7.noicu)) # 953 patients died without ICU
with(tdt, CrossTable(grp, dead7))
with(tdt, CrossTable(grp, dead90))
with(tdt, CrossTable(grp, dead1y))

# - recommend grp
with(tdt.rec, CrossTable(icu_accept))
with(tdt.rec, CrossTable(icu_accept, icucmp))
with(tdt.rec, CrossTable(icu_accept, dead7.noicu))
with(tdt.rec, CrossTable(dead90))
with(tdt.rec, CrossTable(dead1y))

# - limited care grp: not recommended
# with(tdt.lim, CrossTable(icu_accept))
with(tdt.lim, CrossTable(icu_accept, icucmp))
with(tdt.lim, CrossTable(icu_accept, dead7.noicu))
with(tdt.lim, CrossTable(grp, dead7))
with(tdt.lim, CrossTable(grp, dead90))
with(tdt.lim, CrossTable(grp, dead1y))


# TODO: 2015-08-08 - [ ] build model icu_accept in 'full population'
# ------------------------------------------------------------------
# - decision making (who gets offered critical care) and ?site level variation


# NOTE: 2015-09-04 - [ ] redefine room_cmp
wdt[, encourage := ifelse(open_beds_max<=0, 0,
    ifelse(open_beds_max %in% c(1,2), 1,
    ifelse(open_beds_max>=3, 2
        ,NA)))]
with(wdt, CrossTable(encourage))
with(wdt, CrossTable(icu_accept, encourage))
with(wdt, CrossTable(early4, encourage))
with(wdt, CrossTable(dead7, encourage))
with(wdt, CrossTable(dead28, encourage))
with(wdt, CrossTable(dead90, encourage))

# when there are lots of beds, what proportion of patients recommended for critical care don't get it
with(wdt[cc_recommended==1], CrossTable(icucmp, encourage))
with(wdt[cc_recommended==1], CrossTable(icu_accept, encourage))
# NOTE: 2015-09-04 - [ ] mortality is lower for ICU admissions when beds available!!
with(wdt[cc_recommended==1 & encourage==2], t.test(icnarc0~icucmp))
# despite the severity of illness being higher!!!
with(wdt[cc_recommended==1 & encourage==0], CrossTable(dead7, icu_accept))
with(wdt[cc_recommended==1 & encourage==1], CrossTable(dead7, icu_accept))
with(wdt[cc_recommended==1 & encourage==2], CrossTable(dead7, icu_accept))
with(wdt[cc_recommended==1 & rxlimits==0 & encourage==2], CrossTable(dead7, icu_accept))
with(wdt[cc_recommended==1 & rxlimits==0 & encourage==2], CrossTable(dead90, icu_accept))
with(wdt[cc_recommended==1 & encourage==2], CrossTable(dead7, early4))
with(wdt[cc_recommended==1 & encourage==2], CrossTable(dead7, icucmp))
with(wdt[cc_recommended==1 & encourage==2], CrossTable(dead90, icucmp))

tdt <- wdt[cc_recommended==1 & rxlimits==0 & encourage==2]
m <- glm(dead90 ~ icu_accept + age + icnarc0 , family = 'binomial', data = tdt)
summary(m)
plot(m)
