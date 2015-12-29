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
source(paste0(PATH_SHARE, "/spotepi_variable_prep.R"))

# Load data
# NOTE: 2015-11-05 - [ ] removed from waf control
load(paste0(PATH_DATA, '/paper-spotepi.RData'))
wdt.original <- wdt
tdt <- prep.wdt(wdt)
tt <- list()                            # empty list to store rmd vars

#  ============
#  = Abstract =
#  ============

with(wdt, CrossTable(rxlimits))
with(wdt, CrossTable(icu_recommend))
with(wdt, CrossTable(icu_recommend, icu_accept))

with(wdt[icu_recommend==1 & icu_accept==0], CrossTable(icucmp,dead7))
(ff.mediqr('time2icu', data=wdt[icu_recommend==1 & icu_accept==0], dp=0))

with(wdt, CrossTable(icu_recommend, rxlimits))
with(wdt[icu_recommend==0 & rxlimits==1], CrossTable(dead7))
with(wdt[icu_recommend==0 & rxlimits==0], CrossTable(icucmp,dead7))
(ff.mediqr('time2icu', data=wdt[icu_recommend==0 & rxlimits==0], dp=0))

# 7 day mortality
with(wdt, CrossTable(dead90, rxlimits))

with(wdt[rxlimits==0], CrossTable(dead2))
with(wdt[rxlimits==0], CrossTable(dead7))
with(wdt[rxlimits==0], CrossTable(dead90))

with(wdt[rxlimits==0 & icu_recommend], CrossTable(dead7))

with(wdt[rxlimits==0 & icu_recommend & icu_accept==1], CrossTable(dead7))
with(wdt[rxlimits==0 & icu_recommend & icu_accept==0], CrossTable(dead7))

# 90 day mortality
with(wdt[rxlimits==0], CrossTable(dead90))
with(wdt[rxlimits==0 & icu_recommend], CrossTable(dead90))
with(wdt[rxlimits==0 & icu_recommend & icu_accept==1], CrossTable(dead90))
with(wdt[rxlimits==0 & icu_recommend & icu_accept==0], CrossTable(dead90))


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

with(wdt, CrossTable(room_cmp, prop.chisq=F, prop.t=F, chisq = T))
with(tdt, CrossTable(room_cmp2, prop.chisq=F, prop.t=F, chisq = T))

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
# - [ ] TODO(2015-12-17): convert to tdt
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
dead90 <- ff.np('dead90', dp=1)
dead1y <- ff.np('dead1y', dp=1)
dead90.wk1 <- ff.np('dead7', dp=1, data=wdt[dead90==1])

# NEWS risk category and mortality
with(tdt, CrossTable(dead7, news_risk))

# Associations with severity

#  =================================
#  = Pathways following assessment =
#  =================================
with(wdt, CrossTable(icu_recommend))
with(wdt, CrossTable(icu_recommend, rxlimits))
with(wdt[icu_recommend==0], CrossTable(icu_accept, rxlimits))

with(wdt, CrossTable(bedside.decision))
with(wdt, CrossTable(dead7, bedside.decision))
with(wdt, CrossTable(icucmp, bedside.decision))
with(wdt[bedside.decision=="ward"], CrossTable(dead7, icucmp))
with(wdt[bedside.decision=="ward"], CrossTable(icu_recommend))
with(wdt[bedside.decision=="ward" & icu_recommend==1], CrossTable(dead7, icucmp))
with(wdt, CrossTable(beds_none2, bedside.decision))
with(wdt, CrossTable(beds_none, bedside.decision))
with(wdt[icu_recommend==1], CrossTable(beds_none, bedside.decision))


#  ==================================
#  = Patients with treatment limits =
#  ==================================
rxlimits <- ff.np('rxlimits', data=wdt, dp=0)

age.by.rxlimits <- ff.t.test(wdt, 'age', 'rxlimits', dp=0)
age.by.rxlimits

sofa.by.rxlimits <- ff.t.test(wdt, 'sofa_score', 'rxlimits', dp=1)
sofa.by.rxlimits

dead7.rxlimits <- ff.np('dead7', dp=1, data=wdt[rxlimits==1])
dead90.rxlimits <- ff.np('dead90', dp=1, data=wdt[rxlimits==1])
dead1y.rxlimits <- ff.np('dead1y', dp=1, data=wdt[rxlimits==1])

#  ========================================================
#  = Patients without Rx limits recommended **WARD** care =
#  ========================================================
ward <- ff.np('ward', dp=1, data=wdt)

age.by.ward <- ff.t.test(wdt[rxlimits==0], 'age', 'ward', dp=1)
age.by.ward
sofa.by.ward <- ff.t.test(wdt[rxlimits==0], 'sofa_score', 'ward', dp=1)
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
age.by.accept <- ff.t.test(wdt[recommend==1], 'age', 'accept', dp=1)
age.by.accept

lookfor("age")
describe(wdt$age80_b)
ff.prop.test(var="age80", byvar="accept", data=wdt[rxlimits==0,.(accept,age80=age<=80)], )

sofa.by.accept <- ff.t.test(wdt[recommend==1], 'sofa_score', 'accept', dp=1)
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







