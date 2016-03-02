# Uncomment when coding
# rm(list=ls(all=TRUE))
# setwd("~/aor/academic/paper-spotepi/src/write")
source("../write/5_results_01start.R")
require(assertthat)
assert_that("wdt" %in% ls())

# Decision
with(tdt, CrossTable(icu_recommend, bedside.decision))


(recommend <- ff.np(icu_recommend, tdt, dp=0))
(decision <- ff.np(bedside.decision, tdt[!is.na(bedside.decision)], dp=0))
(decision.rec <- ff.np(bedside.decision, tdt[!is.na(bedside.decision) & icu_recommend==1], dp=0))

### Patients without treatment limits initially refused critical care
(tdt[, icu.or.dead7 := ifelse(dead7==1 | icucmp == 1, 1, 0)])

(ward.dead7 <- ff.np(dead7, tdt[bedside.decision=="ward"], dp=0))
(ward.dead7.icu <- ff.np(icucmp, tdt[bedside.decision=="ward" & dead7==1], dp=0))
(ward.icucmp <- ff.np(icucmp, tdt[bedside.decision=="ward"], dp=0))
(ward.icu.or.dead7 <- ff.np(icu.or.dead7, tdt[bedside.decision=="ward"], dp=0))

# lookfor(recommend, tdt)
# Reverse definition of dead7 to get mortality not survival
(ward.reco <- ff.np(recommend, data=tdt[bedside.decision=="ward"], dp=0))
tdt[, surv7 := !dead7]
(ward.surv.by.reco <- ff.prop.test(surv7, recommend, data=tdt[bedside.decision=="ward"], dp=0))
(ward.surv.by.icu <- ff.prop.test(surv7, icucmp, data=tdt[bedside.decision=="ward"], dp=0))
# Patients admitted late
tdt[, icucmp_not := !icucmp]
(ward.icu.by.reco <- ff.prop.test(icucmp_not, recommend, data=tdt[bedside.decision=="ward"], dp=0))

### Patients WITH treatment limits initially refused critical care

(limits.dead7 <- ff.np(dead7, tdt[bedside.decision=="rxlimits"], dp=0))
(limits.icucmp <- ff.np(icucmp, tdt[bedside.decision=="rxlimits"], dp=0))
(limits.icu.dead7 <- ff.np(dead7, tdt[bedside.decision=="rxlimits" & icucmp==1], dp=0))

(age.by.limits <- ff.t.test(tdt[bedside.decision!="icu"], age, bedside.decision, dp=0))
(sofa.by.limits <- ff.t.test(tdt[bedside.decision!="icu"], sofa_score, bedside.decision, dp=1))
(icnarc.by.limits <- ff.t.test(tdt[bedside.decision!="icu"], icnarc_score, bedside.decision, dp=1))

(limits.dead90 <- ff.np(dead90, tdt[bedside.decision=="rxlimits"], dp=0))
(limits.dead1y <- ff.np(dead1y, wdt[rxlimits==1], dp=0))

### Patients immediately accepted to critical care

(icu.dead7 <- ff.np(dead7, tdt[bedside.decision=="icu"], dp=0))
(icu.dead7.pre <- ff.np(icucmp, tdt[bedside.decision=="icu" & dead7==1], dp=0))
(icu.icucmp <- ff.np(icucmp, tdt[bedside.decision=="icu" & dead7==0], dp=0))

(age.by.icu <- ff.t.test(tdt[bedside.decision!="rxlimits"], age, bedside.decision, dp=1))
(sofa.by.icu <- ff.t.test(tdt[bedside.decision!="rxlimits"], sofa_score, bedside.decision, dp=1))
(icnarc.by.icu <- ff.t.test(tdt[bedside.decision!="rxlimits"], icnarc_score, bedside.decision, dp=1))
describe(tdt$room_cmp2)
tt <- tdt[bedside.decision!="rxlimits" & room_cmp2!="[ 1, 3)",
	.(	ward=ifelse(bedside.decision=="icu",0,1),
		full=ifelse(room_cmp2=="[-5, 1)",1,0)
		)]
tt
(full.by.icu <- ff.prop.test(ward, full, data=tt,  dp=1))

# (time2icu <- ff.mediqr(time2icu, data=tdt.timing, dp=0))
(icu.delay <- ff.mediqr(time2icu, data=tdt.timing[bedside.decision=="icu"], dp=0))
(ward.delay <- ff.mediqr(time2icu, data=tdt.timing[bedside.decision=="ward"], dp=0))
require(pairwiseCI)
# Note need to subset the list at the end to extract the estimates via names
tdt.timing[, refuse := !accept]
(delay.by.accept <- pairwiseCI(time2icu ~ refuse, data=tdt.timing[bedside.decision!="rxlimits"], method="Median.diff")$byout[[1]])
names(delay.by.accept)

# Repeat for just those recommended
(reco.icu <- ff.np(icucmp, tdt[recommend==1]))
(reco.delay <- ff.mediqr(time2icu, data=tdt.timing[icu_recommend==1], dp=0))

(icu.delay.reco <- ff.mediqr(time2icu, data=tdt.timing[icu_recommend==1 & bedside.decision=="icu"], dp=0))
(ward.delay.reco <- ff.mediqr(time2icu, data=tdt.timing[icu_recommend==1 & bedside.decision=="ward"], dp=0))
(delay.by.accept.reco <- pairwiseCI(time2icu ~ refuse, data=tdt.timing[icu_recommend==1 & bedside.decision!="rxlimits"], method="Median.diff")$byout[[1]])
names(delay.by.accept.reco)

(icu.early4 <- ff.np(early4, tdt.timing[bedside.decision == "icu" & icucmp == 1], dp=0))
(ward.early4 <- ff.np(early4, tdt.timing[bedside.decision == "ward" & icucmp == 1], dp=0))
tdt.timing[, late4 := !early4]
(early4.by.accept <- ff.prop.test(late4, icu_accept, data=tdt.timing[bedside.decision != "rxlimits" & icucmp == 1], dp=0))

## Early proportions
(recommend.early4 <- ff.np(early4, tdt.timing[icu_recommend==1], dp=0))

