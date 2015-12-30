# source("write/5_results_01start.R")
# How many patients and sites
dim(wdt)
nrow(wdt)
length(unique(wdt$icode))
# Data linkage
summary(wdt[,.(min(match_quality_by_site)),by=.(icode,studymonth)][,V1])
str(wdt.sites)

