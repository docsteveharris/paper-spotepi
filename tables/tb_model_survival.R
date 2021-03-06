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
# 2016-01-26
# - updated to work with time-varying co-efficient for severity

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
    --subgrp=SUBGRP     All patients or subgrp [default: nolimits]
    --tsplit=TSPLIT     Cut-points for survSplit [default: c(7)]
    --nsims=NSIMS       number of simulations for bootstrap [default: 5]
    -b, --bedside       Include icu_accept and early4 predictors
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
You can also specify options
- to examine site only adjustment
- to include bedside decision adjustment
- to change censoring
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
setwd("/Users/steve/aor/academic/paper-spotepi/src/tables")
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
eval(parse(text=paste("tsplit <-", opts$tsplit))) # define survSplit

# Define model name and check subgroups
if (subgrp=="all") {
    assert_that(nrow(tdt)==15158)
    model.name <- "all"
    vars.plus <- c()
} else if (subgrp=="nolimits") {
    tdt <- tdt[rxlimits==0]
    assert_that(nrow(tdt)==13017)
    model.name <- "nolimits"
    vars.plus <- c()
} else if (subgrp=="rxlimits") {
    tdt <- tdt[rxlimits==1]
    assert_that(nrow(tdt)==2141)
    model.name <- "rxlimits"
    vars.plus  <- c()
} else if (subgrp=="recommend") {
    tdt <- tdt[icu_recommend==1 & rxlimits==0]
    assert_that(nrow(tdt)==4976)
    model.name <- "recommend_nolimits"
    vars.plus  <- c()
} else {
    stop(paste("ERROR?:", subgrp, "not recognised"))
}


# Define model name to be used in filename outputs
model.name <- paste0("survival_", model.name)

if (opts$siteonly) {
    model.name <- paste0(model.name, "_siteonly")
}
if (opts$bedside) {
    model.name <- paste0(model.name, "_bedside")
}
if (t.censor != 90) {
    model.name <- paste0(model.name, "_t", opts$censor)
}

table.name <- paste0(model.name, "_sims", opts$nsims)


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

vars.bedside <- c(
    "icu_accept",
    "early4"
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

#  =================================================================
#  = Use command line to select patient level predictors in or out =
#  =================================================================
if (opts$siteonly) {
    # Exclude patient level to permit comparison of MOR with/withouta
    vars     <- c(1)
    vars.tvc <- c()
} else {
    if (opts$bedside) {
        # drop timing vars if you are trying to understand bedside
        vars     <- c(vars.patient, vars.bedside)
    } else {
        vars     <- c(vars.patient, vars.timing)
    }
    vars.tvc <- c("icnarc_score:factor(period)", "periarrest:factor(period)")
}


            

#  =============================
#  = Define formulae for model =
#  =============================

# Formula for single level model in coxph
fm.ph <- formula(
        paste("Surv(t0, t, f)",
        paste(c(vars),
        collapse = "+"), sep = "~"))

# time-varying
fm.tv <- formula(
        paste("Surv(t0, t, f)",
        paste(c(vars, vars.tvc ),
        collapse = "+"), sep = "~"))

# Formula for old version of coxph with frailty (coxme now recommended but slow)
fm.xt <- formula(
        paste("Surv(t, f)",
        paste(c(vars, vars.tvc, "frailty(site, dist=\"gamma\")"),
        collapse = "+"), sep = "~"))

# Formula for coxme
fm.me <- formula(
        paste("Surv(t, f)",
        paste(c(vars, vars.tvc, "(1|site)"),
        collapse = "+"), sep = "~"))

#  =============================================
#  = Extract confidence intervals by bootstrap =
#  =============================================
# Now pack this together into a single function
coxph.rsample <- function(fm=fm.xt, data=tdt, ssplit=tsplit, coxme=FALSE) {
    
    # Resample with replacement the data
    d <- rsample2(tdt, id.unit="pid", id.cluster="site")

    # Post-resampling split the data to permit non-proportional hazards
    d <- data.table(survSplit(d, cut=ssplit,
        start="t0", end="t", event="f", episode="period"))

    # By default usse coxph with frailty

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

# For testing the above
# coxph.rsample(fm=fm.xt, data=tdt, coxme=FALSE)
# coxph.rsample(fm=fm.me, data=tdt, coxme=TRUE)
# r <- (sapply(1:20,  function(i) coxph.rsample(fm=fm.xt, data=tdt)))


# Split the data to manage time-varying characteristics of severity
# --------------
tdt.survSplit <- survSplit(tdt, cut=tsplit,
    start="t0", end="t", event="f", episode="period")
tdt.survSplit <- data.table(tdt.survSplit)
setorder(tdt.survSplit, id, period)
print(head(tdt.survSplit[,.(id, period, t0, t, f)], 20))

# Single level model in coxph (for sanity checks)
m1 <- coxph(fm.ph, data=tdt.survSplit)
m1.confint <- cbind(summary(m1)$conf.int[,c(1,3:4)], p=(summary(m1)$coefficients[,5]))
(m1.confint <- model2table(m1.confint, est.name="HR"))


# Check schoenfeld residuals / FALSE so only runs interactively
if(FALSE) {
    m1.zph <- cox.zph(m1, transform="log")
    print(m1.zph)
    plot(m1.zph[10]) # icnarc_score
    pplot1 <- ggplot(data=data.frame(x=exp(m1.zph[10]$x), y=m1.zph[10]$y),
        aes(x=x, y=icnarc_score)) +
        geom_smooth() +
        geom_hline(yintercept=0, linetype=2) +
        xlab("Days following assessment") +
        ylab("Smoothed exponentiated\n Schoenfeld residuals\nfor ICNARC physiology score") +
        scale_x_continuous(breaks=c(0,30,60,90)) +
        coord_cartesian(xlim=c(0,90), ylim=c(-0.1,0.1)) +
        theme_minimal()
    pplot1
    ggsave("write/figures/schoenfeld_residuals_icnarc_score.jpg", width=6, height=6)


    plot(m1.zph[11]) # periarrest
    ggplot(data=data.frame(x=exp(m1.zph[11]$x), y=m1.zph[11]$y),
        aes(x=x, y=periarrest)) +
        geom_smooth()
    stop("Just plotted residuals, not meant for command line calls")
}


# Time-varying effect for severity
m1.tvc <- coxph(fm.tv, data=tdt.survSplit)
m1.tvc.confint <- cbind(summary(m1.tvc)$conf.int[,c(1,3:4)], p=(summary(m1.tvc)$coefficients[,5]))
(m1.tvc.confint <- model2table(m1.tvc.confint, est.name="HR"))

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
(r1.raw <- cbind(r1.raw, m1.tvc.confint))

(r1.mhr <- c(r1[nrow(r1),c(5:7)],p=NA, rep(NA,5)))

(r1.raw <- rbind(r1.raw, r1.mhr))
row.names(r1.raw)[nrow(r1.raw)] <- "MHR"
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
sheet1.msg <- "on raw.subgrp cols G:J come from the single level model and are there to provide a sanity check against the full multilevel model"
sheet1.df <- rbind(
    c('table name', table.name),
    c('observations', nrow(tdt)),
    c('observations analysed', nrow(tdt)),
    c('bootstap sims', nsims),
    c('r1 system.time', r1.system.time[1]),
    c('*NOTE*', sheet1.msg)
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
