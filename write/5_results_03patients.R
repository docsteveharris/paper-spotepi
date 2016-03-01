# Uncomment when coding
# rm(list=ls(all=TRUE))
# setwd("/Users/steve/aor/academic/paper-spotepi/src/write")
# source("../write/5_results_01start.R")
require(assertthat)
assert_that("wdt" %in% ls())

tdt[, surv7 := !dead7]

# Patients with sepsis
tt$sepsis <- data.table(sepsis = wdt[,ifelse(sepsis %in% c(3,4),1,0)])
sepsis <- ff.np(sepsis, data=tt$sepsis, dp=0)
# Sepsis site == 2 if resp (which is 2nd in list after NA)
ssite <- ff.np(sepsis_site, data=wdt[sepsis %in% c(3,4)], dp=0)
s.resp.n <- ssite$n[2]
s.resp.p <- ssite$p[2]

# Organ failure
wdt[, sofa2.r := gen.sofa.r(pf, fio2_std)]
wdt[, odys := ifelse(
    (sofa_score>1 & sofa_r <= 1) |
    (!is.na(sofa2.r) & sofa2.r > 1),1,0)]
odys <- ff.np(odys, data=wdt, dp=0)

# Respiratory failure
tt$rdys <- data.table(rdys=wdt[, ifelse(!is.na(sofa2.r) & sofa2.r>1, 1,0)])
rdys <- ff.np(rdys, data=tt$rdys, dp=0)
# Renal failure
tt$kdys <- data.table(kdys = wdt[,ifelse(sofa_k>1,1,0)])
kdys <- ff.np(kdys, data=tt$kdys, dp=0)

# Shock
tt$shock <- data.table(shock = wdt[,
    ifelse(   (!is.na(bpsys) & bpsys<90 )
            | (!is.na(bpmap) & bpmap<70 )
            | (!is.na(lactate) & lactate > 2.5 )
            | (!is.na(rxcvs_sofa) & rxcvs_sofa > 1)
            ,1,0)])
shock <- ff.np(shock, data=tt$shock, dp=0)

# Organ support
wdt[, osupp := ifelse( rxrrt==1 | rx_resp==2 | rxcvs == 2,1,0)]
osupp <- ff.np(osupp, data=wdt, dp=0)

# Mortality summary
# day 7 deaths
dead7 <- ff.np(dead7, dp=0)
# day 7 deaths in 1st 2 days
dead7.d2 <- ff.np(dead2, dp=0, data=wdt[dead7==1])

# Severity of illness - NEWS risk
describe(wdt$news_risk)
d7.news1 <- ff.np(dead7, data=wdt[news_risk==1], dp=0)
d7.news2 <- ff.np(dead7, data=wdt[news_risk==2], dp=0)
d7.news3 <- ff.np(dead7, data=wdt[news_risk==3], dp=0)

(d7.news3.by.reco <- ff.prop.test(surv7, icu_recommend, data=tdt[news_risk==3]))


# Final mortality
dead90 <- ff.np(dead90, dp=0)
dead1y <- ff.np(dead1y, dp=0)
dead1y <- ff.np(dead1y, data=wdt[rxlimits==0], dp=0)

# Now add on visiti recommendation

# ICU recommendation
(recommend <- ff.np(icu_recommend, tdt, dp=0))
(sofa.by.reco <- ff.t.test(sofa_score, recommend, data=tdt))
(icnarc.by.reco <- ff.t.test(icnarc_score, recommend, data=tdt))

# Overall risk
(d7.reco <- ff.prop.test(surv7, recommend, data=tdt))
# Strata specific effect risk
(d7.news1.by.reco <- ff.prop.test(surv7, recommend, data=tdt[news_risk==1]))
(d7.news2.by.reco <- ff.prop.test(surv7, recommend, data=tdt[news_risk==2]))
(d7.news3.by.reco <- ff.prop.test(surv7, recommend, data=tdt[news_risk==3]))

