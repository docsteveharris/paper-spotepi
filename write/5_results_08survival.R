# Uncomment when coding
# rm(list=ls(all=TRUE))
# setwd("/Users/steve/aor/academic/paper-spotepi/src/write")
# source("../write/5_results_01start.R")
require(assertthat)
assert_that("wdt" %in% ls())


# Report deaths and KM survival function at days 1,7,28,90
#  ===================================
#  = Work with no limits population =
#  ===================================
dim(wdt.surv1)
tdt.surv <- prep.wdt(wdt.surv1)
tdt.surv <- tdt.surv[rxlimits==0]
dim(tdt.surv)

# Check data correct
# - [ ] NOTE(2016-03-01): prefer identical to all.equal or use all.equal == TRUE
# 		if using identical then need to check 'type' is equal hence L suffix for integer
assert_that(identical(dim(tdt.surv), c(13017L,85L)))

#  =============================
#  = Set up survival structure =
#  =============================
# t = time, f=failure event
t.censor <- 90 # censoring time

tdt.surv[, t:=ifelse(t.trace>t.censor, t.censor, t.trace)]
tdt.surv[, f:=ifelse(dead==1 & t.trace <= t.censor ,1,0)]
head(tdt.surv[,.(site,id,t.trace,dead,t,f)])
describe(tdt.surv$t)
describe(tdt.surv$f)
m <- with(tdt.surv, Surv(t, f))
str(m)
# Fit the baseline survival function using the KM method
m.surv <- survfit(m~1)
# Extract survival with 95%CI at times
(m.surv.summ <- summary(m.surv, times=c(0,1,7,30,90)))
str(m.surv.summ)
pp <- function(x, dp=0) {
	x   <- 1-x
	fmt <- paste("%.", dp, "f", sep="")
	x   <- paste0(sprintf(fmt, 100*x), "%")
    return(x)
}
# Convert survival to failure, and format as percentages
(t.surv <- with(m.surv.summ, data.table(time, n.risk, n.event,
	fail=pp(surv), lower=pp(lower), upper=pp(upper))))
t.surv[, n := cumsum(n.event)]
t.surv
t.surv$n.cum[2]

# Extract quantiles
quantile(m.surv, probs=c(1/10,1/5,1/4,1/3,1/2))

# Check length of stay
lookfor(los,data=wdt.surv1)
lookfor(discharge,data=wdt.surv1)
lookfor(ddh,data=wdt.surv1)
names(wdt)
describe(wdt$yulosd)

# Report early mortality
t.censor <- 90 # censoring time for this
tdt.surv[, t:=ifelse(t.trace>t.censor, t.censor, t.trace)]
tdt.surv[, f:=ifelse(dead==1 & t.trace <= t.censor ,1,0)]
head(tdt.surv[,.(site,id,t.trace,dead,t,f)])
m <- with(tdt.surv, Surv(t, f))
str(m)
# Fit the baseline survival function using the KM method
m.surv <- survfit(m~1)
# Extract survival with 95%CI at times
(m.surv.summ <- summary(m.surv, times=c(0:90)))
quantile(rep(m.surv$time, times=m.surv$n.event))
