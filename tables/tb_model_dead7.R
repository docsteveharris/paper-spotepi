# author: Steve Harris
# date: 2015-12-15
# subject: Predict early death

# Readme
# ======
# Run this in full population, then repeat in subgrps If you are
# interested in occupancy effect on mortality then exclude site level
# variables (because they are responsbile for occupancy) but condition
# on timing which is a confounder


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

#  =======================================
#  = Set up number of sims for bootstrap =
#  =======================================

nsims <- 1

#  ========================================
#  = Define path and filenames for output =
#  ========================================
table.name <- "model_dead7"
# add nsims to file names since you'll be gutted if you overwrite a major simulation
table.name <- paste0(table.name, "_sim", nsims)
table.path <- paste0(PATH_TABLES, '/')
table.xlsx <- paste0(table.path, 'tb_', table.name, '.xlsx')
table.RData <- paste0(table.path, table.name, '.RData', sep='')
table.RData

#  =============
#  = Load data =
#  =============
source(paste0(PATH_SHARE, "/spotepi_variable_prep.R"))
load(paste0(PATH_DATA, '/paper-spotepi.RData'))
names(wdt.surv1)
tdt <- prep.wdt(wdt.surv1)
dim(tdt)

# Check data correct
assert_that(all.equal(dim(tdt), c(15158,81)))

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


# Function for resampling clustered data
rsample2 <- function(data=tdt, id.unit=id.u, id.cluster=id.c) {
    require(data.table)

    setkeyv(tdt,id.cluster)
    # Generate within cluster ID (needed for the sample command)
    tdt[, "id.within" := .SD[,.I], by=id.cluster, with=FALSE]

    # Random sample of sites
    bdt <- data.table(sample(unique(tdt[[id.cluster]]), replace=TRUE))
    setnames(bdt,"V1",id.cluster)
    setkeyv(bdt,id.cluster)

    # Use random sample of sites to select from original data
    # then
    # within each site sample with replacement using the within site ID
    bdt <- tdt[bdt, .SD[sample(.SD$id.within, replace=TRUE)],by=.EACHI]

    # return data sampled with replacement respecting clusters
    bdt[, id.within := NULL] # drop id.within
    return(bdt)
}


# Now use this function to bootstrap coefficients and MHR from model

#  =============================
#  = Define formulae for model =
#  =============================

# Formula for single level model in coxph
fm.ph <- formula(
        paste("Surv(t, f)",
        paste(c(vars.patient, vars.timing),
        collapse = "+"), sep = "~"))

# Formula for old version of coxph with frailty (coxme now recommended but slow)
fm.xt <- formula(
        paste("Surv(t, f)",
        paste(c(vars.patient, vars.timing, "frailty(site, dist=\"gamma\")"),
        collapse = "+"), sep = "~"))

# Formula for coxme
fm.me <- formula(
        paste("Surv(t, f)",
        paste(c(vars.patient, vars.timing, "(1|site)"),
        collapse = "+"), sep = "~"))

#  =============================================
#  = Extract confidence intervals by bootstrap =
#  =============================================

# Now pack this together into a single function
coxph.rsample <- function(fm=fm.xt, data=tdt, coxme=FALSE) {
    
    # Resample with replacement the data
    d <- rsample2(tdt, id.unit="pid", id.cluster="site")

    # By default usses coxph with frailty

    if (coxme) {
        m1.xt <- coxme(fm, data=d)
        (est <- fixef(m1.xt))
        (MHR <- exp(sqrt(2*VarCorr(m1.xt)$site) * qnorm(0.75)))
    }
    else {
        m1.xt <- coxph(fm, data=d)
        (est = m1.xt$coefficients)
        # Extracting theta means pulling the last value from the model
        theta <- m1.xt$history$frailty$history[,1]
        (theta <- m1.xt$history$frailty$history[,1][length(theta)])
        (MHR <- exp(sqrt(2*theta) * qnorm(0.75)))
        
    }

    return(c(est, mhr=MHR))
}

# coxph.rsample(fm=fm.xt, data=tdt, coxme=FALSE)
# coxph.rsample(fm=fm.me, data=tdt, coxme=TRUE)
# r <- (sapply(1:20,  function(i) coxph.rsample(fm=fm.xt, data=tdt)))


# Cox ME version (for all patients without Rx limits)
# ---------------------------------------------------
d <- tdt

# Single level model in coxph (for sanity checks)
m1 <- coxph(fm.ph, data=d)
m1.confint <- cbind(summary(m1)$conf.int[,c(1,3:4)], p=(summary(m1)$coefficients[,5]))

r1.system.time <- system.time(r <- (sapply(1:nsims,
     function(i) coxph.rsample(fm=fm.me, data=d, coxme=TRUE))))

r1 <- t(apply(r, 1,
    function(x) {
            c(
            mean.exp=exp(mean(x)),
            q.exp=quantile(exp(x), probs=c(0.05,0.95)) ,
            p=1-pnorm(abs(mean(x)/sd(x))),
            mean=mean(x),
            q=quantile(x, probs=c(0.05,0.95))
            # se=sd(x),
            # z=mean(x)/sd(x),
        )}
    ))

r1
(r1.raw <- r1[1:nrow(r1)-1,c(1:4)])
(r1.mhr <- c(r1[nrow(r1),c(5:7)],p=NA))
# Bind single level model estimates for visual checks
(r1.raw <- cbind(r1.raw, m1.confint))
(r1.raw <- rbind(r1.raw, r1.mhr))
(r1.fmt <- model2table(r1.raw[,1:4], est.name="HR"))


# Cox ME version (for patients refused)
# -------------------------------------
d <- tdt[icu_accept==0]

# Single level model in coxph (for sanity checks)
m2 <- coxph(fm.ph, data=d)
m2.confint <- cbind(summary(m2)$conf.int[,c(1,3:4)], p=(summary(m2)$coefficients[,5]))

r2.system.time <- system.time(r.refuse <- (sapply(1:nsims,
     function(i) coxph.rsample(fm=fm.me, data=d, coxme=TRUE))))
r2.system.time

r2 <- t(apply(r.refuse, 1,
    function(x) {
            c(
            mean.exp=exp(mean(x)),
            q.exp=quantile(exp(x), probs=c(0.05,0.95)) ,
            p=1-pnorm(abs(mean(x)/sd(x))),
            mean=mean(x),
            q=quantile(x, probs=c(0.05,0.95))
            # se=sd(x),
            # z=mean(x)/sd(x),
        )}
    ))

r2
(r2.raw <- r2[1:nrow(r2)-1,c(1:4)])
(r2.mhr <- c(r2[nrow(r2),c(5:7)],p=NA))
# Bind single level model estimates for visual checks
(r2.raw <- cbind(r2.raw, m2.confint))
(r2.raw <- rbind(r2.raw, r2.mhr))
(r2.fmt <- model2table(r2.raw[,1:4], est.name="HR"))

# Cox ME version (for patients refused but recommended)
# -----------------------------------------------------
d <- tdt[icu_accept==0 & icu_recommend==1]

# Single level model in coxph (for sanity checks)
m3 <- coxph(fm.ph, data=d)
m3.confint <- cbind(summary(m2)$conf.int[,c(1,3:4)], p=(summary(m3)$coefficients[,5]))
m3.confint

r3.system.time <- system.time(r.refused.recommended <- (sapply(1:nsims,
     function(i) coxph.rsample(fm=fm.me, data=d, coxme=TRUE))))
r3.system.time[1]

r3 <- t(apply(r.refused.recommended, 1,
    function(x) {
            c(
            mean.exp=exp(mean(x)),
            q.exp=quantile(exp(x), probs=c(0.05,0.95)) ,
            p=1-pnorm(abs(mean(x)/sd(x))),
            mean=mean(x),
            q=quantile(x, probs=c(0.05,0.95))
            # se=sd(x),
            # z=mean(x)/sd(x),
        )}
    ))

r3
(r3.raw <- r3[1:nrow(r3)-1,c(1:4)])
(r3.mhr <- c(r3[nrow(r3),c(5:7)],p=NA))
# Bind single level model estimates for visual checks
(r3.raw <- cbind(r3.raw, m3.confint))
(r3.raw <- rbind(r3.raw, r3.mhr))
(r3.fmt <- model2table(r3.raw[,1:4], est.name="HR"))


save(list=ls(all=TRUE),file=table.RData)

# Now export to excel
# -------------------
table.xlsx
wb <- loadWorkbook(table.xlsx, create = TRUE)
setStyleAction(wb, XLC$"STYLE_ACTION.NONE") # no formatting applied

sheet1 <-'model_details'
removeSheet(wb, sheet1)
createSheet(wb, name = sheet1)
sheet1.df <- rbind(
    c('table name', table.name),
    c('observations', nrow(tdt)),
    c('observations analysed', nrow(tdt)),
    c('bootstap sims', nsims),
    c('r1 system.time', r1.system.time[1]),
    c('r2 system.time', r2.system.time[1]),
    c('r3 system.time', r3.system.time[1])
    )
writeWorksheet(wb, sheet1.df, sheet1)

sheet2 <- 'raw.norxlimits'
removeSheet(wb, sheet2)
createSheet(wb, name = sheet2)
writeWorksheet(wb, cbind(vars = row.names(r1.raw), r1.raw), sheet2)

sheet3 <- 'fmt.norxlimits'
removeSheet(wb, sheet3)
createSheet(wb, name = sheet3)
writeWorksheet(wb, r1.fmt, sheet3)


sheet4 <- 'raw.refused'
removeSheet(wb, sheet4)
createSheet(wb, name = sheet4)
writeWorksheet(wb, cbind(vars = row.names(r2.raw), r2.raw), sheet4)

sheet5 <- 'fmt.refused'
removeSheet(wb, sheet5)
createSheet(wb, name = sheet5)
writeWorksheet(wb, r2.fmt, sheet5)

sheet6 <- 'raw.refused.recommended'
removeSheet(wb, sheet6)
createSheet(wb, name = sheet6)
writeWorksheet(wb, cbind(vars = row.names(r3.raw), r3.raw), sheet6)

sheet7 <- 'fmt.refused.recommended'
removeSheet(wb, sheet7)
createSheet(wb, name = sheet7)
writeWorksheet(wb, r3.fmt, sheet7)

saveWorkbook(wb)