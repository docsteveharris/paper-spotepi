# Uncomment when coding
# rm(list=ls(all=TRUE))
# source("write/5_results_01start.R")
require(assertthat)
assert_that("wdt" %in% ls())

# level 3 is elgthtr==1
elgthtr <- ff.np(elgthtr, data=tdt)
(room.timing <- ff.np(room_cmp2, tdt.timing[!is.na(room_cmp2)], dp=0))
