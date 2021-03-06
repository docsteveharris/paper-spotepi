# author: Steve Harris
# date: 2014-10-17
# subject: Multi-level logistic regression model at bedside assessment

# Readme
# ======

# Possible outcomes include
# - icu_accept
# - early4
# - dead90


# Todo
# ====


# Log
# ===

# Stata log
# ---------
# 140607
# - basic structure adapted fr thesis_spot_early/an_model_propensity_logistic.do
# - variable definitions fr thesis_spot_early/cr_preflight.do
# - variables then merged with those in spotepi tb_model_ward_survival_final.do

# 140616
# - focus on time2icu and include site and timing level vars
# 140624
# - switch to using room_cmp fr beds_none
# 140625
# - duplicated from tb_model_time2icu.do
# - uses identical structure but xtlogit and icu_accept

# R log
# -----
# 2014-10-17
# - file created by duplicating from stata file of the same name
# - mixed effects modelling in R done
# - exports model to excel
# 2014-10-20
# - corrected confidence interval estimates: now uses Wald limits
# 2014-11-06
# - considered addin in ccmds_now but so completely dominates that the model becomes meaningless
# 2014-11-07
# - updated to mirror recommend/early4 etc
# 2015-07-21
# - moved under waf control
# 2015-12-08
# - duplicated from paper-spotearly
# 2016-01-18
# - converted to use same vars as mortality models
# - also now takes command line options or defaults up front for outcomes
# 2016-01-19
# - command line option to run without patient level risk factors
# 2016-01-21
# - modified so that dependent var can now also be selected
#   also permits adding in icu_accept as predictor where early4 is the outcome

# Notes
# =====


#  ====================
#  = Code starts here =
#  ====================

rm(list=ls(all=TRUE))

#  =================================================================
#  = Parse command line options or assign defaults if not provided =
#  =================================================================

"usage: 
    tb_model_logistic [options]

options:
    --help              help  (print this)
    -d, --describe      describe this model
    --outcome=OUTCOME   Outcome (dependent) variable [default: icu_accept]
    --subgrp=SUBGRP     All patients or subgrp [default: all]
    --nsims=NSIMS       number of simulations for bootstrap [default: 5]
    -s, --siteonly      Exclude patient level predictors" -> doc

require(docopt) # load the docopt library to parse
# opts <- docopt(doc, "--subgrp=icu_recommend --nsims=5") # for debugging
opts <- docopt(doc)
if (opts$d) {
    write("
***********************************************************************
Multi-level logistic regression model with patients nested within sites
***********************************************************************
Outcome variable intended to be one of
- icu_accept
- early4
- dead90 etc
Predictors are a consolidated version of the information
available at the bedside but currently exclude all site level
information
", stdout())
    quit()
}

library(Hmisc)
library(ggplot2)
library(data.table)
library(lme4)
library(XLConnect)
library(assertthat)
library(boot)

# Define vars in standardised manner
setwd("/Users/steve/aor/academic/paper-spotepi/src")
source("../share/spotepi_variable_prep.R")
load("../data/paper-spotepi.RData")
wdt.original <- wdt
wdt <- prep.wdt(wdt.original)
wdt$sample_N <- 1
wdt$all <- 1

names(wdt)
nrow(wdt)

# Redefine working data - drop rx limits
# ---------------------
wdt <- wdt[rxlimits==0]
nrow(wdt)
assert_that(nrow(wdt)==13017)

nsims  <- opts$nsims          # simulations for bootstrap
subgrp <- opts$subgrp         # define subgrp
outcome <- opts$outcome       # define outcome


if (subgrp=="all") {
    assert_that(nrow(wdt)==13017)
} else if (subgrp=="icu_recommend") {
    wdt <- wdt[get(opts$subgrp)==1]
    assert_that(nrow(wdt)==4976)
} else {
    stop(paste("ERROR?:", subgrp, "not one of 'all' nor 'icu_recommend'"))
}

if (outcome=="icu_accept") {
    model.name <- "accept"
    vars.plus <- c()
    wdt <- wdt
} else if (outcome=="early4") {
    model.name <- "early4"
    vars.plus <- c("icu_accept")
    # Drop theatre admissions from timing analysis
    describe(wdt$elgthtr)
    wdt <- wdt[is.na(elgthtr) | elgthtr==0]
} else {
    stop(paste("ERROR:", outcome, "not one of icu_accept or early4"))
}

# Define model name to be used in filename outputs
model.name <- paste0("model_", model.name, "_")

if (opts$siteonly) {
    table.name <- paste0(model.name, subgrp, "_sims", opts$nsims, "_siteonly")
} else {
    table.name <- paste0(model.name, subgrp, "_sims", opts$nsims)
}

# add nsims to file names since you'll be gutted if you overwrite a major simulation
table.name <- paste0(table.name)

table.path <- paste0("../write/tables", "/")
data.path <- "../data/"

table.xlsx  <- paste0(table.path, 'tb_', table.name, '.xlsx')
table.RData <- paste0(data.path, 'tb_', table.name, '.RData')

# print(table.xlsx)
# print(table.RData)

#  ==========================
#  = Define your predictors =
#  ==========================
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

# Check that relevelled correctly to biggest category
assert_that(table(wdt$room_cmp2)[1]==max(table(wdt$room_cmp2)))

# Now use the outcome variable provided
f.outcome <- reformulate(termlabels = vars, response = outcome)
f.outcome

# Run your model
# --------------
m <- glm(f.outcome ,
    family = 'binomial', data = wdt)
summary(m)

# Display your results
m.eform <- cbind(
    exp(cbind(OR = coef(m), confint(m))),
    z = summary(m)[['coefficients']][,3],
    p = summary(m)[['coefficients']][,4]
    )
m.eform

# Run a formula with site level effects
# -------------------------------------
f.outcome.xt <- update(f.outcome, . ~ . + (1|icode))
f.outcome.xt
m.xt <- glmer(f.outcome.xt , family = 'binomial', data = wdt) # original or default
summary(m.xt)
# NOTE: 2015-07-22 - [ ] model fails to converge
# Checks as per CrossValidated post
# http://stats.stackexchange.com/questions/110004/how-scared-should-we-be-about-convergence-warnings-in-lme4
relgrad <- with(m.xt@optinfo$derivs,solve(Hessian,gradient))
max(abs(relgrad))
# So maybe OK if < 0.001

# TODO: 2014-10-19 - [ ] different results in stata xtlogit therefore explore glmer
# NB: Stata xtlogit uses Gauss-Hermite adaptive quadrature
# NB: glmer uses the Laplace transform - ?less accurate but faster?
# m.xt.nAGQ7 <- glmer(f.outcome.xt , family = 'binomial', data = wdt, nAGQ=7)
# summary(m.xt.nAGQ7)

# Display your results
# NOTE: 2014-10-20 - [ ] this does not converge so switch to using Wald estimator?
# The default method is via the likelihood profile
# m.xt.eform <- cbind(
#   exp(cbind(OR = coef(m.xt), confint.glm(m.xt))),
#   z = summary(m.xt)[['coefficients']][,3],
#   p = summary(m.xt)[['coefficients']][,4]
#   )
# method must be one of 'profile' (default), 'Wald', or 'bootstrap'


# NOTE: 2015-07-22 - [ ] first term below has extra row that should be dropped
assert_that(
    nrow(exp(confint(m.xt, method='Wald'))[-1,]) == nrow(exp(coef(summary(m.xt))[,1:2]))
)
m.xt.eform <- cbind(exp(coef(summary(m.xt))[,1:2]),
    exp(confint(m.xt, method='Wald'))[-1,], # drop the first row
    z = summary(m.xt)[['coefficients']][,3],
    p = summary(m.xt)[['coefficients']][,4])
m.xt.eform # this is a matrix not a dataframe


# Quick inspection of predictions
# -------------------------------

# TIP: 2014-10-18 - [ ] include na.action=na.exclude to pad NA rows from the data.frame
wdt[,yhat.xt := predict(m.xt, type='response', na.action=na.exclude)]
describe(wdt[,yhat.xt])

qplot(icnarc_score, yhat.xt, data=wdt, geom = c('smooth') )
qplot(age_k, yhat.xt, data=wdt, geom = c('boxplot'), notch=TRUE, ylim=c(0,1))

# Format results table
# --------------------
m.xt.fmt <- data.frame(cbind(vars = row.names(m.xt.eform), m.xt.eform))
m.xt.fmt$z <- NULL
colnames(m.xt.fmt)[2] <- 'OR'
colnames(m.xt.fmt)[4] <- 'L95'
colnames(m.xt.fmt)[5] <- 'U95'

m.xt.fmt$OR     <- sprintf("%.2f", round(as.numeric(as.character(m.xt.fmt$OR)), 2))

m.xt.fmt$L95    <- sprintf("%.2f", round(as.numeric(as.character(m.xt.fmt$L95)), 2))
m.xt.fmt$U95    <- sprintf("%.2f", round(as.numeric(as.character(m.xt.fmt$U95)), 2))
m.xt.fmt$CI     <- paste('(', m.xt.fmt$L95, '--', m.xt.fmt$U95, ')', sep='')

m.xt.fmt$star   <- ifelse(as.numeric(as.character(m.xt.fmt$p)) < 0.05, '*', '')
m.xt.fmt$star   <- ifelse(as.numeric(as.character(m.xt.fmt$p)) < 0.01, '**', m.xt.fmt$star)
m.xt.fmt$star   <- ifelse(as.numeric(as.character(m.xt.fmt$p)) < 0.001, '***', m.xt.fmt$star)
m.xt.fmt$p      <- sprintf("%.3f", round(as.numeric(as.character(m.xt.fmt$p)), 3))
m.xt.fmt$p      <- ifelse(m.xt.fmt$p == '0.000', '<0.001', m.xt.fmt$p)

# head(m.xt.fmt)
# Be careful with this order: if you change it then the columns in the excel sheet will be out of order
m.xt.fmt        <- m.xt.fmt[ ,c(1,2,7,6,8,4,5)]
# head(m.xt.fmt)

# - [ ] NOTE(2015-12-10): using nAGQ=0 to spped this process up
#       also only doing 100 replicates at present
# first model with adjustment for patient level factors
tdt <- wdt[, c(vars, "id", "icode", outcome), with=FALSE]
f.outcome.xt <- update(f.outcome, . ~ . + (1|icode))
f.outcome.xt
# m.xt <- glmer(f.outcome.xt , family = 'binomial', data = wdt) # original or default
relgrad <- with(m.xt@optinfo$derivs,solve(Hessian,gradient))
warning(paste("Model failed to converge: beware if gradient>0.001: Gradient=", max(abs(relgrad))) )
m.xt.boot <- glmer(f.outcome.xt , family = 'binomial', data = tdt, nAGQ = 0)
relgrad <- with(m.xt@optinfo$derivs,solve(Hessian,gradient))
warning(paste("Model failed to converge: beware if gradient>0.001: Gradient=", max(abs(relgrad))) )
# - [ ] NOTE(2015-12-11): boot function now returns MOR and predictions
table(m.xt.boot@frame$room_cmp2)
rBoot <- function(m) {

    # Median Odds Ratio
    re.variance <- m@theta^2
    Median.OR <- exp(sqrt(2*re.variance)*qnorm(.75))
    # return(Median.OR)

    # Predicting extra admissions
    # Extract the data
    tdt.beds1 <- m@frame
    tdt.beds2 <- m@frame
    tdt.beds3 <- m@frame

    table(m@frame$room_cmp2)
    # Generate counterfactual data sets
    # replace with baseline (below capacity)
    tdt.beds1$room_cmp2 <- factor(levels(m@frame$room_cmp2)[1], levels=levels(m@frame$room_cmp2))
    # replace with extreme (at or above capacity)
    tdt.beds2$room_cmp2 <- factor(levels(m@frame$room_cmp2)[2], levels=levels(m@frame$room_cmp2))
    # replace with extreme (near capacity)
    tdt.beds3$room_cmp2 <- factor(levels(m@frame$room_cmp2)[3], levels=levels(m@frame$room_cmp2))

    # Make the predictions
    (p.beds1 <- mean(predict(m, type="response", newdata=tdt.beds1), na.rm=TRUE))
    (p.beds2 <- mean(predict(m, type="response", newdata=tdt.beds2), na.rm=TRUE))
    (p.beds3 <- mean(predict(m, type="response", newdata=tdt.beds3), na.rm=TRUE))

    # Calculate the difference (level 2 vs level 1)
    (p.extra2v1 <- p.beds1 - p.beds2)
    # Scale to the number of patients
    n.beds2 <- sum(m@frame$room_cmp2=="[-5, 1)")
    (n2.extra <- round(p.extra2v1*n.beds2))

    # Calculate the difference (level 3 vs level 1)
    (p.extra3v1 <- p.beds1 - p.beds3)
    # Scale to the number of patients
    n.beds3 <- sum(m@frame$room_cmp2=="[ 1, 3)")
    (n3.extra <- round(p.extra3v1*n.beds3))

    n.extra <- n2.extra + n3.extra

    return(c(Median.OR,
        p.beds1, p.beds2, p.beds3,
        p.extra2v1, n2.extra,
        p.extra3v1, n3.extra,
        n.extra
        ))
}
# rBoot(m.xt.boot)
# system.time(bMer <- bootMer(m.xt.boot, rBoot, nsim=2))
system.time(bMer <- bootMer(m.xt.boot, rBoot, nsim=nsims))

names(bMer$t0) <-
        c("Median.OR",
        "p.beds1", "p.beds2", "p.beds3",
        "p.extra2v1", "n2.extra",
        "p.extra3v1", "n3.extra", "n.extra"
        )
# bMer$t0
rBoot95ci <- function(b, this.i=1) {
    b95ci <- boot.ci(b, type=c("norm"), index=this.i)
    return(c(
        parm = names(b$t0[this.i]),
        est = b$t0[this.i],
        l95 = b95ci$normal[,2],
        u95 = b95ci$normal[,3])
    )
}
rBoot95ci(bMer, 2)
(rBoot <- data.frame(t(sapply(c(1:length(bMer$t0)), rBoot95ci, b=bMer))))



# Calculate MOR excluding patient level vars
f.outcome.xt
f.outcome.xt.nopt <- reformulate(termlabels = c(vars.timing),
    response = outcome)
f.outcome.xt.nopt <-  update(f.outcome.xt.nopt, . ~ . + (1|icode))
f.outcome.xt.nopt
m.xt.nopt.boot <- glmer(f.outcome.xt.nopt , family = 'binomial', data = tdt, nAGQ = 0)
MOR4boot <- function(m) {

    # Median Odds Ratio
    re.variance <- m@theta^2
    Median.OR <- exp(sqrt(2*re.variance)*qnorm(.75))
    return(Median.OR)
}
system.time(bMer.nopt <- bootMer(m.xt.nopt.boot, MOR4boot, nsim=nsims))
MOR.nopt.95ci <- boot.ci(bMer, type=c("norm"))
MOR.nopt.95ci <- c(MOR.nopt.95ci$t0, MOR.nopt.95ci$normal[,2:3])
str(MOR.nopt.95ci)
MOR.nopt.95ci


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
    c('observations analysed', length(m.xt@resp$n)),
    c('Median Odds Ratio (95%CI) (patients excluded)', MOR.nopt.95ci)
    )
writeWorksheet(wb, sheet1.df, sheet1)

sheet2 <- 'raw'
removeSheet(wb, sheet2)
createSheet(wb, name = sheet2)
writeWorksheet(wb, cbind(vars = row.names(m.xt.eform), m.xt.eform), sheet2)

sheet3 <- 'results'
removeSheet(wb, sheet3)
createSheet(wb, name = sheet3)
writeWorksheet(wb, m.xt.fmt, sheet3)

sheet4 <- 'boot'
removeSheet(wb, sheet4)
createSheet(wb, name = sheet4)
writeWorksheet(wb, rBoot, sheet4)

saveWorkbook(wb)

# Save the formatted table for use in Rmarkdown
# ---------------------------------------------
model_icu <- m.xt
model_icu.fmt <- m.xt.fmt
save(model_icu, model_icu.fmt, file=table.RData)


