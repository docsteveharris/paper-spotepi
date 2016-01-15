# Results - set-up for R markdwon document
rm(list=ls(all=TRUE))

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
# empty list to store rmd vars
tt <- list()                     
