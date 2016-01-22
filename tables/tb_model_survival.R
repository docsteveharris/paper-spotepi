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
# - bootstrapping added
# - file made generic to model survival at different times

#  ====================
#  = Code starts here =
#  ====================

rm(list=ls(all=TRUE))

#  =================================================================
#  = Parse command line options or assign defaults if not provided =
#  =================================================================

"usage: 
    tb_model_survival [options]

options:
    --help              help  (print this)
    -d, --describe      describe this model
    --censor=CENSOR     censor survival [default: 90]
    --subgrp=SUBGRP     All patients or subgrp [default: all]
    --nsims=NSIMS       number of simulations for bootstrap [default: 5]
    -s, --siteonly      Exclude patient level predictors" -> doc

require(docopt) # load the docopt library to parse
opts <- docopt(doc)
# print(str(opts))
if (opts$d) {
    write("
***********************************************************************
Multi-level cox survival model with patients nested within sites
***********************************************************************
Survival model with censoring at 90 days etc
Predictors are a consolidated version of the information
available at the bedside but currently exclude all site level
information
Possible subgroups include
- all
- rxlimits
- nolimits
- recommend
", stdout())
    quit()
}

#  ==========================
#  = Set-up and development =
#  ==========================
# Generic packages
require(data.table)
require(Hmisc)
require(ggplot2)
require(XLConnect)

# Survival analysis
require(survival)
require(coxme)
require(cmprsk)

# Code management and user functions
# Format results table
require(assertthat)
require(datascibc)
require(scipaper) # contains model2table

#  =============
#  = Load data =
#  =============
setwd("/Users/steve/aor/academic/paper-spotepi/src")
source("../share/spotepi_variable_prep.R")
load("../data/paper-spotepi.RData")

names(wdt.surv1)
tdt <- prep.wdt(wdt.surv1)
dim(tdt)

# Check data correct
assert_that(all.equal(dim(tdt), c(15158,84)))

nsims    <- opts$nsims              # simulations for bootstrap
subgrp   <- opts$subgrp             # define subgrp
t.censor <- as.integer(opts$censor) # define censor

# Define model name and check subgroups
if (subgrp=="all") {
    assert_that(nrow(tdt)==15158)
    model.name <- "all"
    vars.plus <- c()
} else if (subgrp=="nolimits") {
    tdt <- tdt[get(opts$subgrp)==0]
    assert_that(nrow(tdt)==13017)
    model.name <- "nolimits"
    vars.plus <- c()
} else if (subgrp=="rxlimits") {
    tdt <- tdt[get(opts$subgrp)==1]
    assert_that(nrow(tdt)==2141)
    model.name <- "rxlimits"
    vars.plus  <- c()
} else if (subgrp=="recommend") {
    tdt <- tdt[get(opts$subgrp)==1]
    assert_that(nrow(tdt)==4976)
    model.name <- "recommend"
    vars.plus  <- c()
} else {
    stop(paste("ERROR?:", subgrp, "not recognised"))
}


# Define model name to be used in filename outputs
model.name <- paste0("survival_", model.name, "_")

if (opts$siteonly) {
    table.name <- paste0(model.name, "_sims", opts$nsims, "_siteonly")
} else {
    table.name <- paste0(model.name, "_sims", opts$nsims)
}

table.path <- paste0("../write/tables", "/")
data.path <- "../data/"

table.xlsx  <- paste0(table.path, 'tb_', table.name, '.xlsx')
table.RData <- paste0(data.path, 'tb_', table.name, '.RData')

# print(table.xlsx)
# print(table.RData)


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
    "periarrest"
    # "cc.reco"
    )

# Add in extra predictors based on the outcome being examined
vars.patient <- c(vars.patient, vars.plus)

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

#  =================================================================
#  = Use command line to select patient level predictors in or out =
#  =================================================================
if (opts$siteonly) {
    # Exclude patient level to permit comparison of MOR with/withouta
    vars <- c(vars.timing)
} else {
    vars <- c(vars.timing, vars.patient)
}

#  =============================
#  = Set up survival structure =
#  =============================
# t = time, f=failure event
tdt[, t:=ifelse(t.trace>t.censor, t.censor, t.trace)]
tdt[, f:=ifelse(dead==1 & t.trace <= t.censor ,1,0)]
head(tdt[,.(site,id,t.trace,dead,t,f)])
describe(tdt$t)
describe(tdt$f)

#  ========================================================
#  = Function for resampling clustered data for bootstrap =
#  ========================================================
# use this function to bootstrap coefficients and MHR from model
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


# Cox ME version 
# --------------

# Single level model in coxph (for sanity checks)
m1 <- coxph(fm.ph, data=tdt)
m1.confint <- cbind(summary(m1)$conf.int[,c(1,3:4)], p=(summary(m1)$coefficients[,5]))
(m1.confint <- model2table(m1.confint, est.name="HR"))

message(paste("BE PATIENT: Running", nsims, "simulations"))
r1.system.time <- system.time(r <- (sapply(1:nsims,
     function(i) coxph.rsample(fm=fm.me, data=tdt, coxme=TRUE))))
message(paste("You waited", round(r1.system.time[3]), "seconds"))

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
# Bind single level model estimates for visual checks
(r1.raw <- r1[1:nrow(r1)-1,c(1:4)])
(r1.raw <- cbind(r1.raw, m1.confint))

(r1.mhr <- c(r1[nrow(r1),c(5:7)],p=NA, rep(NA,5)))

(r1.raw <- rbind(r1.raw, r1.mhr))
row.names(r1.raw)[17] <- "MHR"
(r1.fmt <- model2table(r1.raw[,1:4], est.name="HR"))

# Save models since it is these that take ages to run
save(r1,file=table.RData)

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
    c('r1 system.time', r1.system.time[1])
    )
writeWorksheet(wb, sheet1.df, sheet1)

sheet2 <- 'raw.subgrp'
removeSheet(wb, sheet2)
createSheet(wb, name = sheet2)
writeWorksheet(wb, cbind(vars = row.names(r1.raw), r1.raw), sheet2)

sheet3 <- 'fmt.subgrp'
removeSheet(wb, sheet3)
createSheet(wb, name = sheet3)
writeWorksheet(wb, r1.fmt, sheet3)

saveWorkbook(wb)
