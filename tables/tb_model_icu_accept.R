# author: Steve Harris
# date: 2014-10-17
# subject: ICU accept model in R

# Readme
# ======


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

# Notes
# =====


# // spotepi tb_model_ward_survival_final variables
# local patient_vars ///
#   ib1.age_k ///
#   male ///
#   ib0.sepsis_dx ///
#   delayed_referral ///
#   ib1.v_ccmds ///
#   icnarc_score ///
#   ib2.room_cmp

# global patient_vars `patient_vars'

# local timing_vars ///
#   out_of_hours ///
#   weekend ///
#   winter

# global timing_vars `timing_vars'

# local site_vars ///
#   teaching_hosp ///
#   hes_overnight_c ///
#   hes_emergx_c ///
#   cmp_beds_max_c ///
#   cmp_throughput ///
#   patients_perhesadmx_c ///
#   ib3.ccot_shift_pattern

# global site_vars `site_vars'


# * NOTE: 2014-06-25 - use this data to ensure comparability with time2icu
# use ../data/working_survival_single.dta, clear
# xtset site
# xtlogit icu_accept $all_vars, or

# // now produce table order
# global table_order ///
#   hes_overnight hes_emergx ccot_shift_pattern patients_perhesadmx ///
#   ccot_shift_pattern small_unit cmp_beds_max ///
#   gap_here ///
#   weekend out_of_hours room_cmp ///
#   gap_here ///
#   age male sepsis_dx v_ccmds periarrest icnarc0

rm(list=ls(all=TRUE))
ls()
# setwd('/Users/steve/aor/p-academic/paper-spotearly/src/analysis')
source("project_paths.r")

library(Hmisc)
library(ggplot2)
library(data.table)
library(lme4)
library(XLConnect)
library(assertthat)

load(paste0(PATH_DATA, '/paper-spotepi.RData'))
wdt.original <- wdt
wdt$sample_N <- 1
names(wdt)
nrow(wdt)

# Redefine working data
# ---------------------
wdt <- wdt[rxlimits==0]

# Define file name
table.name <- 'model_icu_accept'
table.path <- paste0(PATH_TABLES, '/')
table.file <- paste(table.path, 'tb_', table.name, '.xlsx', sep='')
table.file
table.R <- paste(table.path, table.name, '.R', sep='')
table.R

# Inspect the data
# ----------------
gg.age <- qplot(age, icu_accept, data=wdt, geom = c('smooth') )
gg.age  +
    geom_rug(data=wdt[icu_accept==1], sides='t', position='jitter', alpha=1/50) +
    geom_rug(data=wdt[icu_accept==0], sides='b', position='jitter', alpha=1/50) +
    coord_cartesian(ylim=c(0,1))

gg.icnarc <- qplot(icnarc0, icu_accept, data=wdt, geom = c('smooth') )
gg.icnarc   +
    geom_rug(data=wdt[icu_accept==1], sides='t', position='jitter', alpha=1/50) +
    geom_rug(data=wdt[icu_accept==0], sides='b', position='jitter', alpha=1/50) +
    coord_cartesian(ylim=c(0,1))


# Redefine new vars
# -----------------
wdt[, room_cmp2 := cut2(open_beds_cmp, c(1,3), minmax=T )]

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
wdt[, `:=`(
    age_k               = relevel(factor(age_k), 2),
    v_ccmds             = relevel(factor(v_ccmds), 2),
    sepsis_dx           = relevel(factor(sepsis_dx), 1),
    room_cmp2            = relevel(factor(room_cmp2), 3),
    ccot_shift_pattern  = relevel(factor(ccot_shift_pattern), 4),
    icode               = factor(icode)
    )]

describe(wdt$age_k)

f.accept <- reformulate(termlabels = vars, response = 'icu_accept')
f.accept

# Run your model
# --------------
m <- glm(f.accept ,
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
f.accept.xt <- update(f.accept, . ~ . + (1|icode))
f.accept.xt
m.xt <- glmer(f.accept.xt , family = 'binomial', data = wdt) # original or default
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
# m.xt.nAGQ7 <- glmer(f.accept.xt , family = 'binomial', data = wdt, nAGQ=7)
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
tdt <- wdt[, c(vars, "id", "icode", "icu_accept"), with=FALSE]
f.accept.xt <- update(f.accept, . ~ . + (1|icode))
f.accept.xt
# m.xt <- glmer(f.accept.xt , family = 'binomial', data = wdt) # original or default
relgrad <- with(m.xt@optinfo$derivs,solve(Hessian,gradient))
warning(paste("Model failed to converge: beware if gradient>0.001: Gradient=", max(abs(relgrad))) )
m.xt.boot <- glmer(f.accept.xt , family = 'binomial', data = tdt, nAGQ = 0)
relgrad <- with(m.xt@optinfo$derivs,solve(Hessian,gradient))
warning(paste("Model failed to converge: beware if gradient>0.001: Gradient=", max(abs(relgrad))) )
MOR4boot <- function(m) {
    re.variance <- m@theta^2
    Median.OR <- exp(sqrt(2*re.variance)*qnorm(.75))
    return(Median.OR)
}
MOR4boot(m.xt.boot)
system.time(bMer <- bootMer(m.xt.boot, MOR4boot, nsim=100))
boot.ci(bMer, type=c("basic", "norm"))
MOR.95ci <- boot.ci(bMer, type=c("norm"))
MOR.95ci <- c(MOR.95ci$t0, MOR.95ci$normal[,2:3])
str(MOR.95ci)
MOR.95ci

# Predictions
tdt <- wdt[, c(vars, "id", "icode", "icu_accept"), with=FALSE]
table(tdt$room_cmp2)
# Create 2 counterfactual data sets
tdt.beds1 <- tdt
tdt.beds1$room_cmp2 <- 1L
head(tdt.beds1)
tdt.beds0 <- tdt
tdt.beds0$room_cmp2 <- 2L
head(tdt.beds0)
assert_that(nrow(tdt.beds1)==nrow(tdt.beds0))
summary(p.beds1 <- predict(m.xt.boot, type="response", newdata=tdt.beds1))
summary(p.beds0 <- predict(m.xt.boot, type="response", newdata=tdt.beds0))

boot.beds0 <- function(m) {
    # Extract the data
    tdt.beds1 <- m@frame
    tdt.beds0 <- m@frame

    # replace with baseline (below capacity)
    # tdt.beds1$room_cmp2 <- 1L
    tdt.beds1$room_cmp2 <- factor(levels(m@frame$room_cmp2)[1], levels=levels(m@frame$room_cmp2))
    # replcae with extreme (at or above capacity)
    # tdt.beds0$room_cmp2 <- 2L
    tdt.beds0$room_cmp2 <- factor(levels(m@frame$room_cmp2)[2], levels=levels(m@frame$room_cmp2))
    # Make the predictions
    (p.beds1 <- mean(predict(m, type="response", newdata=tdt.beds1), na.rm=TRUE))
    (p.beds0 <- mean(predict(m, type="response", newdata=tdt.beds0), na.rm=TRUE))
    # Calculate the difference
    (p.extra <- p.beds1 - p.beds0)
    # Scale to the number of patients
    n.beds0 <- sum(m@frame$room_cmp2=="[-5, 1)")
    (n0.extra <- round(p.extra*n.beds0))
    return(c(p.beds0, p.beds1, p.extra, n0.extra))
}
boot.beds0(m.xt.boot)
system.time(bMer.beds0 <- bootMer(m.xt.boot, boot.beds0, nsim=2))
str(bMer.beds0)
bMer.beds0$t
library(boot)
(bMer.beds0.n0.95ci <- boot.ci(bMer.beds0, type=c("norm"), index=4))
(bMer.beds0.p.extra.95ci <- boot.ci(bMer.beds0, type=c("norm"), index=3))


f.accept.xt
f.accept.xt.nopt <- reformulate(termlabels = c(vars.timing, vars.site),
    response = 'icu_accept')
f.accept.xt.nopt <-  update(f.accept.xt.nopt, . ~ . + (1|icode))
f.accept.xt.nopt
m.xt.nopt.boot <- glmer(f.accept.xt.nopt , family = 'binomial', data = tdt, nAGQ = 0)
system.time(bMer.nopt <- bootMer(m.xt.nopt.boot, MOR4boot, nsim=10))
MOR.nopt.95ci <- boot.ci(bMer, type=c("norm"))
MOR.nopt.95ci <- c(MOR.nopt.95ci$t0, MOR.nopt.95ci$normal[,2:3])
str(MOR.nopt.95ci)
MOR.nopt.95ci


# Now export to excel
# -------------------

wb <- loadWorkbook(table.file, create = TRUE)
setStyleAction(wb, XLC$"STYLE_ACTION.NONE") # no formatting applied

sheet1 <-'model_details'
removeSheet(wb, sheet1)
createSheet(wb, name = sheet1)
sheet1.df <- rbind(
    c('table name', table.name),
    c('observations', nrow(wdt)),
    c('observations analysed', length(m.xt@resp$n)),
    c('Median Odds Ratio (95%CI)', MOR.95ci)
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

saveWorkbook(wb)

# Save the formatted table for use in Rmarkdown
# ---------------------------------------------
model_icu_accept <- m.xt
model_icu_accept.fmt <- m.xt.fmt
save(model_icu_accept, model_icu_accept.fmt, file=table.R)


