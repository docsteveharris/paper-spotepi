# author: Steve Harris
# date: 2015-12-15
# subject: Delay to admission amongst those recommended

# Readme
# ======


# Todo
# ====


# Log
# ===
# 2015-12-15
# - file created by duplicating from tb_model_icu_accept_vRecommended
# - initial version complete
# - dropped site level covariates

# Notes
# =====
rm(list=ls(all=TRUE))
ls()
# setwd('/Users/steve/aor/p-academic/paper-spotearly/src/analysis')
source("project_paths.r")

#  ==========================
#  = Set-up and development =
#  ==========================
# install.packages("cmprsk", type="source", dependencies=TRUE)
# install.packages("frailtypack", type="source", dependencies=TRUE)

library(Hmisc)
library(ggplot2)
library(data.table)
library(XLConnect)
library(assertthat)
library(survival)
library(coxme)
library(cmprsk)

# Format results table
# --------------------
# - [ ] NOTE(2015-12-16): move this to a package/library

format.results.table <- function(t, est.name="beta.exp", dp=2, p.dp=3) {
    # t must be a matrix of results in the following order
    # (est,L95,U95,p)
    # dp = number of decimal places for pretty printing
    # p.dp = number for p values
    dp.fmt <- paste0("%.", dp, "f")
    p.dp.fmt <- paste0("%.", p.dp, "f")

    t.fmt <- data.frame(cbind(vars = row.names(t), t))
    colnames(t.fmt)[2] <- est.name
    colnames(t.fmt)[3] <- 'L95'
    colnames(t.fmt)[4] <- 'U95'

    t.fmt$HR     <- sprintf(dp.fmt, round(as.numeric(as.character(t.fmt$HR)), dp))

    t.fmt$L95    <- sprintf(dp.fmt, round(as.numeric(as.character(t.fmt$L95)), dp))
    t.fmt$U95    <- sprintf(dp.fmt, round(as.numeric(as.character(t.fmt$U95)), dp))
    t.fmt$CI     <- paste('(', t.fmt$L95, '--', t.fmt$U95, ')', sep='')

    t.fmt$star   <- ifelse(as.numeric(as.character(t.fmt$p)) < 0.05, '*', '')
    t.fmt$star   <- ifelse(as.numeric(as.character(t.fmt$p)) < 0.01, '**', t.fmt$star)
    t.fmt$star   <- ifelse(as.numeric(as.character(t.fmt$p)) < 0.001, '***', t.fmt$star)
    t.fmt$p      <- sprintf(p.dp.fmt, round(as.numeric(as.character(t.fmt$p)), p.dp))
    t.fmt$p      <- ifelse(t.fmt$p == '0.000', '<0.001', t.fmt$p)

    # Now reorder columns and drop L95 U95
    (t.fmt        <- t.fmt[ ,c(1,2,6,5,7)])
    return(t.fmt)
}


load(paste0(PATH_DATA, '/paper-spotepi.RData'))
wdt.surv1.original <- wdt.surv1
wdt.surv1$sample_N <- 1
names(wdt.surv1)
nrow(wdt.surv1)

# Redefine working data
# ---------------------
wdt.surv1 <- wdt.surv1[rxlimits==0 & icu_recommend==1]
describe(wdt.surv1$icu_accept)

# Define file name
table.name <- "model_time2icu_vRecommended"
table.path <- paste0(PATH_TABLES, '/')
table.file <- paste(table.path, 'tb_', table.name, '.xlsx', sep='')
table.file
table.R <- paste(table.path, table.name, '.R', sep='')
table.R

# Redefine new vars
# -----------------
wdt.surv1[, room_cmp2 := cut2(open_beds_cmp, c(1,3), minmax=T )]

# Define your variables
# ---------------------
vars.patient    <- c('age_k', 'male', 'sepsis_dx', 'v_ccmds', 'delayed_referral', 'periarrest', 'icnarc_score')
vars.timing     <- c('out_of_hours', 'weekend', 'winter', 'room_cmp2')
vars.site       <- c('teaching_hosp', 'hes_overnight_c', 'hes_emergx_c',
                    'cmp_beds_max_c', 'cmp_throughput', 'patients_perhesadmx_c',
                    'ccot_shift_pattern')
vars            <- c(vars.site, vars.timing, vars.patient)

# Model specification
# -------------------
wdt.surv1[, `:=`(
    age_k               = relevel(factor(age_k), 2),
    v_ccmds             = relevel(factor(v_ccmds), 2),
    sepsis_dx           = relevel(factor(sepsis_dx), 1),
    room_cmp2            = relevel(factor(room_cmp2), 3),
    ccot_shift_pattern  = relevel(factor(ccot_shift_pattern), 4),
    icode               = factor(icode)
    )]

# R doesn't like leading underscores from stata 
# str(wdt.surv1[,.(id,_t,_d)])
str(wdt.surv1[,c("id","_t","_d"),with=FALSE])

#  =========================
#  = Competing risks model =
#  =========================

# Set up competing risks data
wdt.surv1[,.(id,site,dt1,dt2,dt3,dt4)]
setnames(wdt.surv1,"_t", "stata_t")
setnames(wdt.surv1,"_t0", "stata_t0")
setnames(wdt.surv1,"_d", "stata_d")
wdt.surv1[,.(id,site,stata_t0,stata_t,stata_d)]

# Minimum of time2icu or death
wdt.surv1[, t.cr :=
    ifelse(is.na(time2icu), 24*stata_t,
    ifelse(time2icu/24 < stata_t, time2icu, 24*stata_t))]
# Censor at 7d
wdt.surv1[,t.cr:=ifelse(t.cr>168,168,t.cr)]
wdt.surv1[,.(id,site,time2icu,stata_t,t.cr)]


wdt.surv1[, event := 
    ifelse(is.na(time2icu) & stata_t<=7 & stata_d==1, "dead",
    ifelse(is.na(time2icu) & stata_t>7, "survive",
    ifelse(time2icu/24 < stata_t, "icu", "survive")))]
wdt.surv1[, event := factor(event)]
wdt.surv1[,.(id,site,time2icu,stata_t,t.cr,icucmp,stata_d,event)]

# Try competing risks model
str(wdt.surv1$event)

tdt <- wdt.surv1
c <- (complete.cases(
        tdt[,c("t.cr", "event", "icu_accept",
                vars.patient, vars.timing), with=FALSE]))
nrow(tdt)
tdt <- tdt[c]
nrow(tdt)

(m0 <- coxph(Surv(t.cr, event=="dead") ~ 1, data=tdt))

# Create design matrix and drop the intercept
cov1 <- model.matrix(
    ~ icu_accept +
    age_k + male + sepsis_dx + v_ccmds + delayed_referral + periarrest +
    icnarc_score +
    out_of_hours + weekend + winter + room_cmp2,
data=tdt)[,-1]
assert_that(sum(complete.cases(cov1))==nrow(tdt))

# For reference, although you are not planning on using this
# Subdistribution hazard for death
# m1.cr.dead <- crr(ftime=tdt$t, fstatus=tdt$event, cov1=cov1, failcode="dead", cencode="survive" )

# Subdistribution hazard for ICU admission
m1.cr.icu <- crr(ftime=tdt$t.cr, fstatus=tdt$event,
        cov1=cov1, failcode="icu", cencode="survive",
        )
m1.cr.icu
# Extract confidence intervals etc
summary(m1.cr.icu)
str(summary(m1.cr.icu))

# Prepare the columns
(e <- summary(m1.cr.icu))
beta <- e$coef[,1]
beta.exp <- e$conf.int[,1]
se <- e$coef[,3]
p <- e$coef[,5]
CI.exp <- e$conf.int[,3:4]

# (m.eform <- cbind(beta.exp, se = exp(beta), CI.exp, p))
(m1.cr.icu.eform <- cbind(beta.exp, CI.exp, p))
(m1.cr.icu.fmt <- format.results.table(m1.cr.icu.eform, est.name="HR"))

#  =============
#  = Cox model =
#  =============

# Variable definitions for cox model
s <- with(tdt, Surv(time2icu, icucmp))
with(tdt, Surv(time2icu, time2icu > 0))
tdt[,`:=` (
    admit=ifelse(is.na(time2icu),0,1),
    t=ifelse(is.na(time2icu),168,time2icu)
    )]
describe(tdt$admit)
describe(tdt$t)

# Run your model
# --------------
Surv(tdt$t, tdt$admit)

# Null model
m0 <- coxph(Surv(t, admit) ~ 1, data=tdt)
m0$loglik

# Build model for those accepted else will just be reporting 'decision'
m1 <- coxph(Surv(t, admit) ~
    icu_accept +
    age_k + male + sepsis_dx + v_ccmds + delayed_referral + periarrest +
    icnarc_score +
    out_of_hours + weekend + winter + room_cmp2,
    data=tdt)
summary(m1)

# Log likelihood
m1$loglik

## Chi-squared value comparing this model to the null model
(-2 * (m0$loglik - logLik(m1)))

#  =========================================
#  = Cox model with random effect for site =
#  =========================================

# Model with frailty
require(coxme)
m0.xt <- coxme(Surv(t, admit) ~ 1 + (1|site), data=tdt)
m0.xt
m0.xt$loglik

m1.xt <- coxme(Surv(t, admit) ~
    icu_accept +
    age_k + male + sepsis_dx + v_ccmds + delayed_referral + periarrest +
    icnarc_score +
    out_of_hours + weekend + winter + room_cmp2 +
    (1|site),
    data=tdt)
summary(m1.xt)

## Log likelihood
m1.xtlogLik <- m1.xt$loglik + c(0, 0, m1.xt$penalty)
m1.xtlogLik

## -2 logLik difference
(-2 * (m1.xtlogLik["NULL"] - m1.xtlogLik["Penalized"]))

## -2 logLik difference
(logLikDiffNeg2 <- -2 * (logLik(m1.xt) - m1.xtlogLik["Integrated"]))

## Degree of freedom difference
(dfDiff <- m1.xt$df[1] - 1)

## P value for the random effects: significant random effects across centers
pchisq(q = as.numeric(logLikDiffNeg2), df = dfDiff, lower.tail = FALSE)

# Median Hazard ratio
# -------------------
summary(m1.xt)
VarCorr(m1.xt) # variance
# MHR <- exp(sqrt(2*var)*phi-1(0.75))
(MHR <- exp(sqrt(2*VarCorr(m1.xt)$site) * qnorm(0.75)))

# Prepare the columns
print(m1.xt)
# - [ ] NOTE(2015-12-16): no closed form solution for confidence
#   intervals - would need to bootstrap or similar
#   For now, just report the frailty model and ignore the clustering here
(beta <- fixef(m1.xt))
(beta.exp <- exp(fixef(m1.xt)))
(se   <- sqrt(diag(vcov(m1.xt))))
p    <- 1 - pchisq((beta/se)^2, 1)
CI   <- round(confint(m1.xt), 3)
CI.exp   <- exp(round(confint(m1.xt), 3))

# (m1.xt.eform <- cbind(beta.exp, se = exp(beta), CI.exp, p))
(m1.xt.eform <- cbind(beta.exp, CI.exp, p))

(m1.xt.eform.fmt <- format.results.table(m1.xt.eform, est.name="HR"))

# Now export to excel
# -------------------

ls()
wb <- loadWorkbook(table.file, create = TRUE)
setStyleAction(wb, XLC$"STYLE_ACTION.NONE") # no formatting applied

sheet1 <-'model_details'
removeSheet(wb, sheet1)
createSheet(wb, name = sheet1)
sheet1.df <- rbind(
    c('table name', table.name),
    c('observations', nrow(tdt)),
    c('observations analysed', nrow(tdt)),
    c("MHR", MHR)
    )
writeWorksheet(wb, sheet1.df, sheet1)

sheet2 <- 'raw.frailty'
removeSheet(wb, sheet2)
createSheet(wb, name = sheet2)
writeWorksheet(wb, cbind(vars = row.names(m1.xt.eform), m1.xt.eform), sheet2)

sheet3 <- 'results.frailty'
removeSheet(wb, sheet3)
createSheet(wb, name = sheet3)
writeWorksheet(wb, m1.xt.eform.fmt, sheet3)

sheet4 <- 'raw.cr.icu'
removeSheet(wb, sheet4)
createSheet(wb, name = sheet4)
writeWorksheet(wb, cbind(vars = row.names(m1.cr.icu.eform), m1.cr.icu.eform), sheet4)

sheet5 <- 'results.cr.icu'
removeSheet(wb, sheet5)
createSheet(wb, name = sheet5)
writeWorksheet(wb, m1.cr.icu.fmt, sheet5)

saveWorkbook(wb)


