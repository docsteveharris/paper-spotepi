# Uncomment when coding
# rm(list=ls(all=TRUE))
# source("write/5_results_01start.R")
require(assertthat)
assert_that("wdt" %in% ls())

str(wdt.sites)
n.sites <- nrow(wdt.sites)
n.teach <- table(wdt.sites$teaching)[2]
n.dgh <- table(wdt.sites$teaching)[1]

(smonths <- ff.mediqr('studymonths_n', data=wdt.sites, dp=0))
(pts_q <- ff.mediqr('patients', data=wdt.sites, dp=0))
(pts_overnight <- ff.mediqr('pts_by_hes_n', data=wdt.sites, dp=0))
(ccot <- ff.np(ccot, wdt.sites, dp=0))
(beds <- ff.mediqr('cmp_beds_persite', data=wdt.sites, dp=0))
(colocate <- ff.np(units_incmp, data=wdt.sites, dp=0))



