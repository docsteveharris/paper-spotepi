# Uncomment when coding
# rm(list=ls(all=TRUE))
# source("write/5_results_01start.R")
require(assertthat)
assert_that("wdt" %in% ls())

lookfor("room")
describe(wdt$room_cmp2)
(room <- ff.np(room_cmp2, wdt[!is.na(room_cmp2)], dp=0))




