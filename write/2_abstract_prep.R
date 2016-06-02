#  =============================================================
#  = IMPORTANT: Abstract is created after the RESULTS are done =
#  =============================================================
# Uncomment when coding
rm(list=ls(all=TRUE))
setwd("/Users/steve/aor/academic/paper-spotepi/src/write")
source("../write/5_results_01start.R")
source("../write/5_results_06pathways.R") # needed for ICU delay stuff
require(assertthat)
assert_that("wdt" %in% ls())

#  ============
#  = Abstract =
#  ============
assert_that("tt" %in% ls())
tt$patients <- nrow(wdt)
tt$sites <- length(unique(wdt$icode))
str(tt)

tt$news_high <- data.frame(ff.np(news_risk, dp=0))[4,]
(tt$full <- data.frame(ff.np(room_cmp2, wdt[!is.na(room_cmp2)], dp=0))[1,])

# Organ failure
wdt[, sofa2.r := gen.sofa.r(pf, fio2_std)]
wdt[, odys := ifelse(
    (sofa_score>1 & sofa_r <= 1) |
    (!is.na(sofa2.r) & sofa2.r > 1),1,0)]
odys <- ff.np(odys, data=wdt, dp=0)

wdt[, osupp := ifelse( rxrrt==1 | rx_resp==2 | rxcvs == 2,1,0)]
osupp <- ff.np(osupp, data=wdt, dp=0)

tt$rxlimits <- ff.np(rxlimits, data=wdt, dp=0)
tt$rxlimits_dead7 <- ff.np(dead7, data=wdt[rxlimits==1], dp=0)
tt$rxlimits_dead90 <- ff.np(dead90, data=wdt[rxlimits==1], dp=0)
tt$rxlimits_dead1y <- ff.np(dead1y, data=wdt[rxlimits==1], dp=0)

tt$sepsis <- data.table(sepsis = wdt[,ifelse(sepsis %in% c(3,4),1,0)])
sepsis <- ff.np(sepsis, data=tt$sepsis, dp=0)

# Recommendation and decision amongst those without limits
(tt$reco<- ff.np(icu_recommend, data=wdt[rxlimits==0], dp=0))
(tt$reco_accept <- ff.np(icu_accept, data=wdt[rxlimits==0 & icu_recommend==1], dp=0))
tt$reco_accept$p[2]

# Recommended but indirect admit
tt$reco_late <- data.table(reco_late =
	wdt[rxlimits==0 & icu_recommend==1 & icu_accept==0,
		ifelse(icucmp==1,0,1)])
tt$reco_late <- ff.np(reco_late, data=tt$reco_late, dp=0)

# Recommended and died without critical care
tt$reco_d7ward <- data.table(reco_d7ward = 
	wdt[rxlimits==0 & icu_recommend==1 & icu_accept==0,
		ifelse(dead7==1 & icucmp==0, 1, 0)])
tt$reco_d7ward <- ff.np(reco_d7ward, data=tt$reco_d7ward, dp=0)

# Mortality without limits
tt$dead7 <- ff.np(dead7, data=wdt[rxlimits==0], dp=0)
tt$dead90 <- ff.np(dead90, data=wdt[rxlimits==0], dp=0)
tt$dead1y <- ff.np(dead1y, data=wdt[rxlimits==0], dp=0)
# day 7 deaths in 1st 2 days
tt$dead7.d2 <- ff.np(dead2, dp=0, data=wdt[rxlimits==0 & dead7==1])


# Died or were admitted late to critical care


# with(wdt, CrossTable(rxlimits))
# with(wdt, CrossTable(icu_recommend))
# with(wdt, CrossTable(icu_recommend, icu_accept))

# with(wdt[icu_recommend==1 & icu_accept==0], CrossTable(icucmp,dead7))
# (ff.mediqr('time2icu', data=wdt[icu_recommend==1 & icu_accept==0], dp=0))

# with(wdt, CrossTable(icu_recommend, rxlimits))
# with(wdt[icu_recommend==0 & rxlimits==1], CrossTable(dead7))
# with(wdt[icu_recommend==0 & rxlimits==0], CrossTable(icucmp,dead7))
# (ff.mediqr('time2icu', data=wdt[icu_recommend==0 & rxlimits==0], dp=0))

# # 7 day mortality
# with(wdt, CrossTable(dead90, rxlimits))

# with(wdt[rxlimits==0], CrossTable(dead2))
# with(wdt[rxlimits==0], CrossTable(dead7))
# with(wdt[rxlimits==0], CrossTable(dead90))

# with(wdt[rxlimits==0 & icu_recommend], CrossTable(dead7))

# with(wdt[rxlimits==0 & icu_recommend & icu_accept==1], CrossTable(dead7))
# with(wdt[rxlimits==0 & icu_recommend & icu_accept==0], CrossTable(dead7))

# # 90 day mortality
# with(wdt[rxlimits==0], CrossTable(dead90))
# with(wdt[rxlimits==0 & icu_recommend], CrossTable(dead90))
# with(wdt[rxlimits==0 & icu_recommend & icu_accept==1], CrossTable(dead90))
# with(wdt[rxlimits==0 & icu_recommend & icu_accept==0], CrossTable(dead90))

