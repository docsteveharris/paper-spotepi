# Uncomment when coding
# rm(list=ls(all=TRUE))
# source("write/5_results_01start.R")
# require(assertthat)
# assert_that("wdt" %in% ls())

# Decision

with(tdt, CrossTable(icu_recommend, bedside.decision))
(decision <- ff.np(bedside.decision, tdt[!is.na(bedside.decision)], dp=0))




