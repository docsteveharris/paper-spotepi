# author: Steve Harris
# date: 2015-11-27
# subject: Model ward severity (for NEWS/ICNARC/SOFA)

# Readme
# ======


# Todo
# ====
# - [ ] TODO(2015-11-28): this runs for ICNARC score - will need to find
#   and replace icnarc0 for NEWS/SOFA etc



# Log
# ===
# 2015-11-27
# - file created
# - largely adapted from /Users/steve/aor/academic/paper-spotearly/src/analysis/tb_model_icu_accept.R


# Load libraries

library(Hmisc)
library(ggplot2)
library(data.table)
library(lme4)
library(XLConnect)
library(assertthat)

rm(list=ls(all=TRUE))
source("project_paths.r")

# Load data

load(paste0(PATH_DATA, '/paper-spotepi.RData'))
wdt.original <- wdt
wdt$sample_N <- 1
dim(wdt)

# Define file name
wdt.original <- wdt
wdt$sample_N <- 1
names(wdt)
nrow(wdt)

# Define file name
table.name <- 'model_icnarc_aps'
table.path <- paste0(PATH_TABLES, '/')
table.file <- paste(table.path, 'tb_', table.name, '.xlsx', sep='')
table.file
table.R <- paste(table.path, table.name, '.R', sep='')
table.R

# Inspect the data
# ----------------
gg.age <- qplot(age, icnarc0, data=wdt, geom = c('smooth') )
gg.age  +
    coord_cartesian(ylim=c(0,50)) +
    geom_rug(position='jitter', alpha=1/50)


# Define your variables
# ---------------------
vars.patient    <- c('age_k', 'male', 'sepsis_dx', 'v_ccmds',
					'delayed_referral', 'periarrest')
vars.timing     <- c('out_of_hours', 'weekend', 'winter', 'room_cmp')
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
    room_cmp            = relevel(factor(room_cmp), 3),
    ccot_shift_pattern  = relevel(factor(ccot_shift_pattern), 4),
    icode               = factor(icode)
    )]

# Define simple model
# - for ICNARC aps
# - single level

f.aps <- reformulate(termlabels = vars, response = 'icnarc0')
f.aps

# Run your model
# --------------
m <- glm(f.aps ,
    family = 'gaussian', data = wdt)
summary(m)

# Display your results
m.ci <- cbind(
    cbind(estimate = coef(m), confint(m, method='Wald')),
    z = summary(m)[['coefficients']][,3],
    p = summary(m)[['coefficients']][,4]
    )
m.ci

# Run a formula with site level effects
# -------------------------------------
f.aps.xt <- update(f.aps, . ~ . + (1|icode))
f.aps.xt
m.xt <- lmer(f.aps.xt, data = wdt)
summary(m.xt)
# NOTE: 2015-07-22 - [ ] model fails to converge
# Checks as per CrossValidated post
# http://stats.stackexchange.com/questions/110004/how-scared-should-we-be-about-convergence-warnings-in-lme4
relgrad <- with(m.xt@optinfo$derivs,solve(Hessian,gradient))
max(abs(relgrad))
# So maybe OK if < 0.001

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
summary(m.xt)
confint(m.xt, method='Wald')[-2:0,]
coef(summary(m.xt))
assert_that(
    nrow(confint(m.xt, method='Wald')[-2:0,]) == nrow(coef(summary(m.xt))[,1:2])
)

# lme does not report p-values
# help("pvalues")
# Possible solutions via
# http://mindingthebrain.blogspot.co.uk/2014/02/three-ways-to-get-parameter-specific-p.html
require(lmerTest)
# Now refit the model
m.xt <- lmer(f.aps.xt, data = wdt)
summary(m.xt)
confint(m.xt, method='Wald')[-2:0,]
coef(summary(m.xt))

m.xt.ci <- cbind(coef(summary(m.xt))[,1:2],
    confint(m.xt, method='Wald')[-2:0,], # drop the first 2 rows
    t = summary(m.xt)[['coefficients']][,4],
    p = summary(m.xt)[['coefficients']][,5])
m.xt.ci # this is a matrix not a dataframe


# Quick inspection of predictions
# -------------------------------

# TIP: 2014-10-18 - [ ] include na.action=na.exclude to pad NA rows from the data.frame
wdt[,yhat.xt := predict(m.xt, type='response', na.action=na.exclude)]
describe(wdt[,yhat.xt])

qplot(icnarc_score, yhat.xt, data=wdt, geom = c('smooth') )
qplot(relevel(factor(age_k),'0'), yhat.xt, data=wdt, geom = c('boxplot'), notch=TRUE, ylim=c(0,50))

# Format results table
# --------------------
m.xt.fmt <- data.frame(cbind(vars = row.names(m.xt.ci), m.xt.ci))
m.xt.fmt$z <- NULL
colnames(m.xt.fmt)[2] <- 'estimate'
colnames(m.xt.fmt)[4] <- 'L95'
colnames(m.xt.fmt)[5] <- 'U95'

m.xt.fmt$estimate     <- sprintf("%.2f", round(as.numeric(as.character(m.xt.fmt$estimate)), 2))

m.xt.fmt$L95    <- sprintf("%.2f", round(as.numeric(as.character(m.xt.fmt$L95)), 2))
m.xt.fmt$U95    <- sprintf("%.2f", round(as.numeric(as.character(m.xt.fmt$U95)), 2))
m.xt.fmt$CI     <- paste('(', m.xt.fmt$L95, '--', m.xt.fmt$U95, ')', sep='')

m.xt.fmt$star   <- ifelse(as.numeric(as.character(m.xt.fmt$p)) < 0.05, '*', '')
m.xt.fmt$star   <- ifelse(as.numeric(as.character(m.xt.fmt$p)) < 0.01, '**', m.xt.fmt$star)
m.xt.fmt$star   <- ifelse(as.numeric(as.character(m.xt.fmt$p)) < 0.001, '***', m.xt.fmt$star)
m.xt.fmt$p      <- sprintf("%.3f", round(as.numeric(as.character(m.xt.fmt$p)), 3))
m.xt.fmt$p      <- ifelse(m.xt.fmt$p == '0.000', '<0.001', m.xt.fmt$p)

head(m.xt.fmt)
# Be careful with this order: if you change it then the columns in the excel sheet will be out of order
names(m.xt.fmt)
m.xt.fmt <- m.xt.fmt[ ,c(1,2,8,7,9,3:6)]
m.xt.fmt


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
    c('observations analysed', length(m.xt@resp$mu))
    )
writeWorksheet(wb, sheet1.df, sheet1)

sheet2 <- 'raw'
removeSheet(wb, sheet2)
createSheet(wb, name = sheet2)
writeWorksheet(wb, cbind(vars = row.names(m.xt.ci), m.xt.ci), sheet2)

sheet3 <- 'results'
removeSheet(wb, sheet3)
createSheet(wb, name = sheet3)
writeWorksheet(wb, m.xt.fmt, sheet3)

saveWorkbook(wb)

# Save the formatted table for use in Rmarkdown
# ---------------------------------------------
model_aps.icnarc <- m.xt
model_aps.icnarc.fmt <- m.xt.fmt
save(model_aps.icnarc, model_aps.icnarc.fmt, file=table.R)
