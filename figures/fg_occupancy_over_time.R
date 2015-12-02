# author: Steve Harris
# date: 2015-12-02
# subject: Plot occupancy

# Readme
# ======


# Dictionary
# ----------
# - occupancy_active: number of actively treated patients
# - occupancy: number of current patients (including those waiting for d/c)
# label var occupancy_max "Monthly maximum occupancy"
# label var occupancy_median "Monthly median occupancy"
# label var free_beds "Empty beds with respect to monthly max"
# gen free_beds_cmp = (cmp_beds_max - occupancy)
# label var free_beds_cmp "Physically Empty beds with respect to CMP reported number"
# gen full_physically0 = free_beds_cmp <= 0
# gen open_beds_cmp = (cmp_beds_max - occupancy_active)
# label var open_beds_cmp "Open beds with respect to CMP reported number"
# gen full_active0 = open_beds_cmp <= 0

# Todo
# ====


# Log
# ===
# 2015-12-02
# - file created

# Load dependencies
# -----------------
library(data.table)
library(reshape2)
library(ggplot2)
library(Hmisc)
library(assertthat)
library(foreign)
library(lubridate)

rm(list=ls(all=TRUE))

# Waf control
source("project_paths.r")

# Load the necessary data
# -----------------------
rdt <- data.table(read.dta(
	paste0(PATH_DATA, '/working_occupancy.dta'
	)))

# Check this is the correct data
dim(rdt)
assert_that(all.equal(dim(rdt),c(366072,43)))
str(rdt)
wdt <- rdt[,.(icode,icnno,otimestamp,
		occupancy, occupancy_active,
		cmp_beds_max)]
wdt[, `:=` (
	full.physical = ifelse(occupancy>=cmp_beds_max,1,0),
	full.clinical = ifelse(occupancy_active>=cmp_beds_max,1,0)
	)]
str(wdt)


# Quick histogram for distribution of free beds
qplot(x=cmp_beds_max-occupancy, data=wdt,
	facets=~icode) +
	theme_minimal()

# Now plot occupancy over the week
table(hour(wdt$otimestamp))
describe(wday(wdt$otimestamp))
tdt <- wdt[,
	.(occupancy = mean(1-((cmp_beds_max-occupancy)/cmp_beds_max),na.rm=TRUE)),
	by=.((wday(otimestamp)-1)*24 + hour(otimestamp))]
tdt
qplot(x=wday,y=occupancy, data=tdt, geom="step") 

# Now plot when the unit is full
tdt <- wdt[, .(
		full.physical=mean(full.physical,na.rm=TRUE),
		full.clinical=mean(full.clinical,na.rm=TRUE)
		),
	by=.((wday(otimestamp)-1)*24 + hour(otimestamp))]
tdt
qplot(x=wday,y=full.clinical, data=tdt, geom="step") 

# Final plot
gg <- ggplot(data=tdt, aes(x=wday,y=full.clinical*100))
gg + geom_step() +
	theme_minimal() +
	scale_x_continuous(breaks=c(0,24,48,72,96,120,144,168)) +
	xlab("Hours (starting at 00:00h Monday)") +
	ylab("Clinical occupancy at capacity (%)") +
	coord_cartesian(y=c(0,20))




