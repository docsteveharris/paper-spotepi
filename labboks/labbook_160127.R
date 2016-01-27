setwd("/Users/steve/aor/academic/paper-spotepi/src")
source("../share/spotepi_variable_prep.R")
load("../data/paper-spotepi.RData")

vars.patient <- c(
    "age_k",
    "male",
    "sepsis_dx",
    "osupp2",
    # "v_ccmds",
    "icnarc_score",
    "periarrest"
    # "cc.reco"
    )

vars.timing <- c(
    "out_of_hours",
    "weekend",
    "winter",
    "room_cmp2"
    )

vars.site <- c(
    "teaching_hosp",
    "hes_overnight_c",
    "cmp_beds_max_c",
    "ccot_shift_pattern"
    )

# For exploring survival models
tdt.surv <- prep.wdt(wdt.surv1)
tdt.surv <- tdt.surv[rxlimits==0]
dim(tdt.surv)

# Check data correct
assert_that(all.equal(dim(tdt.surv), c(13017,84)))

#  =============================
#  = Set up survival structure =
#  =============================
# t = time, f=failure event, t.censor = censor time
t.censor <- 90
tdt.surv[, t:=ifelse(t.trace>t.censor, t.censor, t.trace)]
tdt.surv[, f:=ifelse(dead==1 & t.trace <= t.censor ,1,0)]
head(tdt.surv[,.(site,id,t.trace,dead,t,f)])
describe(tdt.surv$t)
describe(tdt.surv$f)
m <- with(tdt.surv, Surv(t, f))
str(m)
# Fit the baseline survival function using the KM method
m.surv <- survfit(m~1)

# Formula for single level model in coxph
fm.ph <- formula(
        paste("Surv(t, f)",
        paste(c(vars.patient, vars.timing),
        collapse = "+"), sep = "~"))

m1 <- coxph(fm.ph, data=tdt.surv)
m1.confint <- cbind(summary(m1)$conf.int[,c(1,3:4)], p=(summary(m1)$coefficients[,5]))
require(scipaper)
(m1.confint <- model2table(m1.confint, est.name="HR"))

zp <- cox.zph(m1, transform=function(time) log(time))
zp # note that icnarc_score ph test fails
plot(zp[10])
abline(0,0, col=2)

# Fit a time interaction in the model
m <- coxph(Surv(t, f) ~ icnarc_score, data=tdt.surv)
summary(m)
m.z <- cox.zph(m)
print(m.z)
plot(m.z)

# - [ ] NOTE(2016-01-26): doesn't work
# Now time transform
# m <- coxph(Surv(t, f) ~ icnarc_score + tt(icnarc_score),
# 	tt=function(x, t) x * t,
# 	, data=tdt.surv)

require(data.table)
# Use the survSplit function to create a long 'counting' form of the data
dim(tdt.surv)
tdt.survSplit <- survSplit(tdt.surv, cut=c(0,2,7),
	start="t0", end="t", event="f", episode="period")
tdt.survSplit <- data.table(tdt.survSplit)
setorder(tdt.survSplit, id, period)
head(tdt.survSplit[,.(id,period,t0,t,f,icnarc_score)], 30)

# Now apply this to the full model
# Complete cases data to permit model comparison
tdt.cc <- tdt.survSplit[,
	c("t0", "t", "f", "period", vars.patient, vars.timing, "news_risk"),
	with=FALSE]
tdt.cc <- na.omit(tdt.cc)
dim(tdt.cc)
tdt.cc[, news_risk:=factor(news_risk, levels=c(3,2,1,0))]
attributes(tdt.cc$room_cmp2)
attr(tdt.cc$room_cmp2, "levels") <- c("beds_ok", "beds_none", "beds_some")
attributes(tdt.cc$room_cmp2)
table(tdt.cc$room_cmp2)

tdt.cc[, room_cmp2]
str(tdt.cc$news_risk)
table(tdt.cc$news_risk)
dim(tdt.cc)

m0 <- coxph(Surv(t0,t,f) ~ 1, data=tdt.cc)

fm1 <- formula(
        paste("Surv(t0, t, f)",
        paste(c(vars.patient, vars.timing),
        collapse = "+"), sep = "~"))
m1 <- coxph(fm1, data=tdt.cc)
summary(m1)

fm2 <- formula(
        paste("Surv(t0, t, f)",
        paste(c(vars.patient, vars.timing, "icnarc_score:factor(period)"),
        collapse = "+"), sep = "~"))
m2 <- coxph(fm2, data=tdt.cc)
summary(m2)
anova(m2,m1)


# Quick inspect of occupancy severity interaction
# Do this using news_risk as an easy way of picking categorising
fm3 <- formula(
        paste("Surv(t0, t, f)",
        paste(c(vars.patient, vars.timing,
            "icnarc_score:factor(period)",
            "news_risk"
            ),
        collapse = "+"), sep = "~"))
m3 <- coxph(fm3, data=tdt.cc)
m3
anova(m3,m2)

# Now with the interaction
fm4 <- formula(
        paste("Surv(t0, t, f)",
        paste(c(vars.patient, vars.timing,
            "icnarc_score:factor(period)",
            "news_risk",
            "room_cmp2:news_risk"
            ),
        collapse = "+"), sep = "~"))
m4 <- coxph(fm4, data=tdt.cc)
m4
anova(m3,m2)

require(multcomp)
summary(glht(m4, linfct=c("room_cmp2beds_none = 0 ")))