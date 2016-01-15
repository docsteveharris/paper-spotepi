# Uncomment when coding
# rm(list=ls(all=TRUE))
# source("write/5_results_01start.R")
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

lookfor(recommend, tdt)
# Reverse definition of dead7 to get mortality not survival
tdt[, surv7 := !dead7]
(ward.surv.by.reco <- ff.prop.test("surv7", "recommend", data=tdt[bedside.decision=="ward"]))
(ward.surv.by.icu <- ff.prop.test("surv7", "icucmp", data=tdt[bedside.decision=="ward"]))






