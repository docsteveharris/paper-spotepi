# Results - set-up for R markdwon document
rm(list=ls(all=TRUE))
setwd("~/aor/academic/paper-spotepi/src/write")

# Load libraries
library(assertthat)
library(Hmisc)
library(foreign)
library(data.table)
library(gmodels)
library(datascibc)
library(dsbc)
library(boot)
library(dplyr)

source("../share/functions4rmd.R")  
source("../share/derive.R")
source("../share/spotepi_variable_prep.R")

load("../data/paper-spotepi.RData")
wdt.original <- wdt
tdt <- prep.wdt(wdt)
names(tdt)

# Delay to admission population
# - [ ] NOTE(2016-01-15): should also exclude death at visit but there aren't any??
table(wdt$v_disposal) 
tdt.timing <- tdt[is.na(elgthtr) | elgthtr == 0]

# empty list to store rmd vars
tt <- list()                     

