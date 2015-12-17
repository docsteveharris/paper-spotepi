# author: Steve Harris
# date: 2015-12-15
# subject: Predict early death

# Readme
# ======
# Run this in full population, then repeat in subgrps


# Todo
# ====


# Log
# ===
# 2015-12-15
# - file created by duplicating from tb_model_icu_accept_vRecommended
# - initial version complete
# - dropped site level covariates
# 2015-12-17
# - file duplicated again fr model_time2icu_vRecommend

# Notes
# =====
rm(list=ls(all=TRUE))
ls()
# setwd('/Users/steve/aor/p-academic/paper-spotearly/src/analysis')
source("project_paths.r")

#  ==========================
#  = Set-up and development =
#  ==========================
# Generic packages
library(data.table)
library(Hmisc)
library(ggplot2)
library(XLConnect)

# Survival analysis
library(survival)
library(coxme)
library(cmprsk)

# Code management and user functions
library(assertthat)
library(datascibc)
library(scipaper) # contains model2table

#  ========================================
#  = Define path and filenames for output =
#  ========================================
table.name <- "model_dead7"
table.path <- paste0(PATH_TABLES, '/')
table.file <- paste(table.path, 'tb_', table.name, '.xlsx', sep='')
table.file
table.R <- paste(table.path, table.name, '.R', sep='')
table.R

#  =============
#  = Load data =
#  =============
source(paste0(PATH_SHARE, "/spotepi_variable_prep.R"))
load(paste0(PATH_DATA, '/paper-spotepi.RData'))
names(wdt.surv1)
tdt <- prep.wdt(wdt.surv1)
dim(tdt)

# Check data correct
assert_that(all.equal(dim(tdt), c(15158,80)))

#  ===============
#  = Subset data =
#  ===============
nrow(tdt <- tdt[rxlimits==0])

#  =====================
#  = Define predictors =
#  =====================

vars.patient <- c(
    "age_k",
    "male",
    "sepsis_dx",
    "osupp2",
    # "v_ccmds",
    "icnarc_score",
    "periarrest",
    "cc.reco"
    )

vars.timing <- c(
    "out_of_hours",
    "weekend",
    "winter",
    "room_cmp2"
    )

vars.site <- c(
    "teaching_hosp",
    "hes_overnight_c",
    "cmp_beds_max_c",
    "ccot_shift_pattern"
    )

vars <- c(vars.site, vars.timing, vars.patient)

#  =============================
#  = Set up survival structure =
#  =============================
# t = time, f=failure event
tdt[, t:=ifelse(t.trace>7,168,24*t.trace)]
tdt[, f:=ifelse(dead==1 & t.trace <=7 ,1,0)]
head(tdt[,.(site,id,t.trace,dead,t,f)])
describe(tdt$t)
describe(tdt$f)

#  ======================
#  = Survival modelling =
#  ======================
# Null model
m0 <- coxph(Surv(t, f) ~ 1, data=tdt)
m0$loglik

# Prepare model
fm <- formula(
        paste("Surv(t, f)",
        paste(c(vars.patient, vars.timing, vars.site),
        collapse = "+"), sep = "~"))

m1 <- coxph(fm, data=tdt)
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
m0.xt <- coxme(Surv(t, f) ~ 1 + (1|site), data=tdt)
m0.xt
m0.xt$loglik

# Prepare model
fm.xt <- formula(
        paste("Surv(t, f)",
        paste(c(vars.patient, vars.timing, vars.site, "(1|site)"),
        collapse = "+"), sep = "~"))
fm.xt

m1.xt <- coxme(fm.xt, data=tdt)
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

#  =============================================
#  = Extract confidence intervals by bootstrap =
#  =============================================
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
(m1.xt.eform.fmt <- model2table(m1.xt.eform, est.name="HR"))

stop()

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


