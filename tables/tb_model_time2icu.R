# author: Steve Harris
# date: 2015-12-15
# subject: Time to ICU within competing risk for death without ICU

# Readme
# ======


# Todo
# ====
# - [ ] TODO(2016-01-19): competing risks model with frailty!
#       can't see an easy way to do this
#       therefore ignore frailty and just build CR model here
#       separately build early4 model to get at intersite variability


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
# 2016-01-21
# - dropping hierarchical portion of model

# Notes
# =====
rm(list=ls(all=TRUE))

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
# Format results table
library(assertthat)
library(datascibc)
library(scipaper) # contains model2table
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
vars.patient <- c(
    "age_k",
    "male",
    "sepsis_dx",
    "osupp2",
    # "v_ccmds",
    "icnarc_score",
    "periarrest"
    # - [ ] NOTE(2016-01-18): drop reco from model b/c will examine as subgrp
    # "cc.reco"
    )

vars.timing <- c(
    "out_of_hours",
    "weekend",
    "winter",
    "room_cmp2"
    )

vars <- c(vars.timing, vars.patient)

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
    c('observations analysed', nrow(wdt))
    )
writeWorksheet(wb, sheet1.df, sheet1)

sheet4 <- 'raw.cr.icu'
removeSheet(wb, sheet4)
createSheet(wb, name = sheet4)
writeWorksheet(wb, cbind(vars = row.names(m1.cr.icu.eform), m1.cr.icu.eform), sheet4)

sheet5 <- 'results.cr.icu'
removeSheet(wb, sheet5)
createSheet(wb, name = sheet5)
writeWorksheet(wb, m1.cr.icu.fmt, sheet5)

saveWorkbook(wb)


