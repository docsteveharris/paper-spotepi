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

# Notes
# =====
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
library(boot)
library(survival)

load(paste0(PATH_DATA, '/paper-spotepi.RData'))
wdt.surv1.original <- wdt.surv1
wdt.surv1$sample_N <- 1
names(wdt.surv1)
nrow(wdt.surv1)

# Redefine working data
# ---------------------
wdt.surv1 <- wdt.surv1[rxlimits==0 & icu_recommend==1]

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
s <- with(wdt.surv1, Surv(time2icu, icucmp))
with(wdt.surv1, Surv(time2icu, time2icu > 0))
wdt.surv1[,`:=` (
    admit=ifelse(is.na(time2icu),0,1),
    t=ifelse(is.na(time2icu),168,time2icu)
    )]
describe(wdt.surv1$admit)
describe(wdt.surv1$t)

# Run your model
# --------------
Surv(wdt.surv1$t, wdt.surv1$admit)

# Build model for those accepted else will just be reporting 'decision'
m <- coxph(Surv(t, admit) ~
    age_k + male + sepsis_dx + v_ccmds + delayed_referral + periarrest +
    icnarc_score +
    out_of_hours + weekend + winter + room_cmp2,
    data=wdt.surv1[icu_accept==1])
summary(m)

# model reports exponeniated coefficients
str(m)
m$coeff # coefficients on the original scale
confint(m)

# for the baseine survival function
# plot(survfit(m))

# Prepare the columns
beta <- coef(m)
beta.exp <- exp(coef(m))
se   <- sqrt(diag(m$var))
p    <- 1 - pchisq((beta/se)^2, 1)
CI   <- round(confint(m), 3)
CI.exp   <- exp(round(confint(m), 3))

# (m.eform <- cbind(beta.exp, se = exp(beta), CI.exp, p))
(m.eform <- cbind(beta.exp, CI.exp, p))

# Format results table
# --------------------
m.xt.fmt <- data.frame(cbind(vars = row.names(m.eform), m.eform))
colnames(m.xt.fmt)[2] <- 'HR'
colnames(m.xt.fmt)[3] <- 'L95'
colnames(m.xt.fmt)[4] <- 'U95'
m.xt.fmt

m.xt.fmt$HR     <- sprintf("%.2f", round(as.numeric(as.character(m.xt.fmt$HR)), 2))

m.xt.fmt$L95    <- sprintf("%.2f", round(as.numeric(as.character(m.xt.fmt$L95)), 2))
m.xt.fmt$U95    <- sprintf("%.2f", round(as.numeric(as.character(m.xt.fmt$U95)), 2))
m.xt.fmt$CI     <- paste('(', m.xt.fmt$L95, '--', m.xt.fmt$U95, ')', sep='')

m.xt.fmt$star   <- ifelse(as.numeric(as.character(m.xt.fmt$p)) < 0.05, '*', '')
m.xt.fmt$star   <- ifelse(as.numeric(as.character(m.xt.fmt$p)) < 0.01, '**', m.xt.fmt$star)
m.xt.fmt$star   <- ifelse(as.numeric(as.character(m.xt.fmt$p)) < 0.001, '***', m.xt.fmt$star)
m.xt.fmt$p      <- sprintf("%.3f", round(as.numeric(as.character(m.xt.fmt$p)), 3))
m.xt.fmt$p      <- ifelse(m.xt.fmt$p == '0.000', '<0.001', m.xt.fmt$p)

m.xt.fmt
# Be careful with this order: if you change it then the columns in the excel sheet will be out of order
(m.xt.fmt        <- m.xt.fmt[ ,c(1,2,6,5,7)])


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
    c('observations', nrow(wdt.surv1)),
    c('observations analysed', m$n)
    )
writeWorksheet(wb, sheet1.df, sheet1)

sheet2 <- 'raw'
removeSheet(wb, sheet2)
createSheet(wb, name = sheet2)
writeWorksheet(wb, cbind(vars = row.names(m.eform), m.eform), sheet2)

sheet3 <- 'results'
removeSheet(wb, sheet3)
createSheet(wb, name = sheet3)
writeWorksheet(wb, m.xt.fmt, sheet3)

saveWorkbook(wb)


