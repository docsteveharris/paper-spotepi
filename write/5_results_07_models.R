# Uncomment when coding
rm(list=ls(all=TRUE))
source("write/5_results_01start.R")
require(assertthat)
assert_that("wdt" %in% ls())

# level 3 is elgthtr==1
ff.np(elgthtr, data=tdt)

