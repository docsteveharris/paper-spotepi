#  =============================================================
#  = IMPORTANT: Abstract is created after the RESULTS are done =
#  =============================================================
# Uncomment when coding
# rm(list=ls(all=TRUE))
# setwd("/Users/steve/aor/academic/paper-spotepi/src/write")
# source("../write/5_results_01start.R")
require(assertthat)
assert_that("wdt" %in% ls())

#  ============
#  = Abstract =
#  ============
assert_that("tt" %in% ls())
tt$patients <- nrow(wdt)
tt$sites <- length(unique(wdt$icode))

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

tt$sepsis <- data.table(sepsis = wdt[,ifelse(sepsis %in% c(3,4),1,0)])
sepsis <- ff.np(sepsis, data=tt$sepsis, dp=0)

# Recommendation and decision amongst those without limits
(tt$recommend <- ff.np(icu_recommend, dp=0))
(tt$reco_accept <- ff.np(icu_accept, data=wdt[icu_recommend==1], dp=0))

tt$reco_late <- data.table(reco_late =
	wdt[icu_recommend==1 & icu_accept==0, ifelse(icucmp==1,0,1)])
ff.np(reco_late, data=tt$reco_late, dp=0)

tt$ward_dead7 <- data.table(ward_dead7 = 
	wdt[icu_recommend==1 & icu_accept==0, ifelse(dead7==1 & icucmp==0, 1, 0)])
ff.np(ward_dead7, data=tt$ward_dead7)


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
