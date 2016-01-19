# author: Steve Harris
# date: 2015-12-15
# subject: Time to ICU within competing risk for death without ICU

# Readme
# ======


# Todo
# ====
# - [ ] TODO(2016-01-19): competing risks model with frailty!


# Log
# ===
# 2015-12-15
# - file created by duplicating from tb_model_icu_accept_vRecommended
# - initial version complete
# - dropped site level covariates
# 2016-01-19
# - remove from waf control
# - update to standard predictors
# - include accept var
# - make sure MHR extracted OK
# - add in command line options via docopt if need subsetting etc

# Notes
# =====
rm(list=ls(all=TRUE))

#  ==========================
#  = Set-up and development =
#  ==========================

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

format.results.table <- function(t, est.name="beta.exp", dp=2, dp.p=3) {
    # t must be a matrix of results in the following order
    # (est,L95,U95,p)
    # dp = number of decimal places for pretty printing
    # dp.p = number for p values
    dp.fmt <- paste0("%.", dp, "f")
    dp.p.fmt <- paste0("%.", dp.p, "f")

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
    t.fmt$p      <- sprintf(dp.p.fmt, round(as.numeric(as.character(t.fmt$p)), dp.p))
    t.fmt$p      <- ifelse(t.fmt$p == '0.000', '<0.001', t.fmt$p)

    # Now reorder columns and drop L95 U95
    (t.fmt        <- t.fmt[ ,c(1,2,6,5,7)])
    return(t.fmt)
}

# Define output file names and paths
table.name <- paste0("model_time2icu")
table.path <- paste0("../write/tables/")
data.path <- "../data/"
table.xlsx  <- paste0(table.path, 'tb_', table.name, '.xlsx')
table.RData <- paste0(data.path, 'tb_', table.name, '.RData')

# Define vars in standardised manner
source("../share/spotepi_variable_prep.R")
load("../data/paper-spotepi.RData")
wdt.original <- wdt
wdt <- prep.wdt(wdt.surv1)
names(wdt)

# Merge stata survival variables into wdt
# R doesn't like leading underscores from stata 
setnames(wdt.surv1,"_t", "stata_t")
setnames(wdt.surv1,"_t0", "stata_t0")
setnames(wdt.surv1,"_d", "stata_d")
wdt.surv1[,.(id,stata_t0,stata_t,stata_d)]
wdt <- merge(wdt, wdt.surv1[,.(id,stata_t0,stata_t,stata_d)], by="id")

wdt$sample_N <- 1
wdt$all <- 1

# Redefine working data - drop rx limits
# ---------------------
wdt <- wdt[rxlimits==0]
assert_that(nrow(wdt)==13017)


#  ==========================
#  = Define your predictors =
#  ==========================
# - [ ] NOTE(2016-01-19): these are hand entered below - **BE CAREFUL**
# commented out here to avoid confusion
# vars.patient <- c(
#     "age_k",
#     "male",
#     "sepsis_dx",
#     "osupp2",
#     # "v_ccmds",
#     "icnarc_score",
#     "periarrest"
#     # - [ ] NOTE(2016-01-18): drop reco from model b/c will examine as subgrp
#     # "cc.reco"
#     )

# vars.timing <- c(
#     "out_of_hours",
#     "weekend",
#     "winter",
#     "room_cmp2"
#     )

# vars <- c(vars.timing, vars.patient)

# Check that relevelled correctly to biggest category
assert_that(table(wdt$room_cmp2)[1]==max(table(wdt$room_cmp2)))


#  =========================
#  = Competing risks model =
#  =========================
# Set up competing risks data

# Minimum of time2icu or death
wdt[, t.cr :=
    ifelse(is.na(time2icu), 24*stata_t,
    ifelse(time2icu/24 < stata_t, time2icu, 24*stata_t))]
# Censor at 7d
wdt[,t.cr:=ifelse(t.cr>168,168,t.cr)]
wdt[,.(id,site,time2icu,stata_t,t.cr)]

wdt[, event := 
    ifelse(is.na(time2icu) & stata_t<=7 & stata_d==1, "dead",
    ifelse(is.na(time2icu) & stata_t>7, "survive",
    ifelse(time2icu/24 < stata_t, "icu", "survive")))]
wdt[, event := factor(event)]
wdt[,.(id,site,time2icu,stata_t,t.cr,icucmp,stata_d,event)]

# Try competing risks model
str(wdt$event)

# Will only work with complete cases so filter
c <- (complete.cases(
        wdt[,c("t.cr", "event", "icu_accept",
                vars.patient, vars.timing), with=FALSE]))
nrow(wdt)
wdt <- wdt[c]
dim(wdt)

(m0 <- coxph(Surv(t.cr, event=="dead") ~ 1, data=wdt))

# Create design matrix and drop the intercept
# - [ ] NOTE(2016-01-19): these are hand entered into the model here
# do not assume that changes above are important
cov1 <- model.matrix(
    ~ icu_accept +
    age_k + male + sepsis_dx + osupp2 + icnarc_score + periarrest +
    out_of_hours + weekend + winter + room_cmp2,
data=wdt)[,-1]
assert_that(sum(complete.cases(cov1))==nrow(wdt))

# For reference, although you are not planning on using this
# Subdistribution hazard for death
# m1.cr.dead <- crr(ftime=wdt$t, fstatus=wdt$event, cov1=cov1, failcode="dead", cencode="survive" )

# Subdistribution hazard for ICU admission
m1.cr.icu <- crr(ftime=wdt$t.cr, fstatus=wdt$event,
        cov1=cov1, failcode="icu", cencode="survive",
        )
m1.cr.icu
# Extract confidence intervals etc
summary(m1.cr.icu)

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
#        _  _                                        
#      _| || |_                                      
#     |_  __  _|  _ __ ___  ___ _   _ _ __ ___   ___ 
#      _| || |_  | '__/ _ \/ __| | | | '_ ` _ \ / _ \
#     |_  __  _| | | |  __/\__ \ |_| | | | | | |  __/
#       |_||_|   |_|  \___||___/\__,_|_| |_| |_|\___|
#                                                    
#                                                    

# Variable definitions for cox model
s <- with(wdt, Surv(time2icu, icucmp))
with(wdt, Surv(time2icu, time2icu > 0))
wdt[,`:=` (
    admit=ifelse(is.na(time2icu),0,1),
    t=ifelse(is.na(time2icu),168,time2icu)
    )]
describe(wdt$admit)
describe(wdt$t)

# Run your model
# --------------
Surv(wdt$t, wdt$admit)

# Null model
m0 <- coxph(Surv(t, admit) ~ 1, data=wdt)
m0$loglik

# Build model for those accepted else will just be reporting 'decision'
m1 <- coxph(Surv(t, admit) ~
    icu_accept +
    age_k + male + sepsis_dx + v_ccmds + delayed_referral + periarrest +
    icnarc_score +
    out_of_hours + weekend + winter + room_cmp2,
    data=wdt)
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
m0.xt <- coxme(Surv(t, admit) ~ 1 + (1|site), data=wdt)
m0.xt
m0.xt$loglik

m1.xt <- coxme(Surv(t, admit) ~
    icu_accept +
    age_k + male + sepsis_dx + v_ccmds + delayed_referral + periarrest +
    icnarc_score +
    out_of_hours + weekend + winter + room_cmp2 +
    (1|site),
    data=wdt)
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
wb <- loadWorkbook(table.xlsx, create = TRUE)
setStyleAction(wb, XLC$"STYLE_ACTION.NONE") # no formatting applied

sheet1 <-'model_details'
removeSheet(wb, sheet1)
createSheet(wb, name = sheet1)
sheet1.df <- rbind(
    c('table name', table.name),
    c('observations', nrow(wdt)),
    c('observations analysed', nrow(wdt)),
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


