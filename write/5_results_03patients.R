# Uncomment when coding
# rm(list=ls(all=TRUE))
# source("write/5_results_01start.R")

tt$sepsis <- data.table(sepsis = wdt[,ifelse(sepsis %in% c(3,4),1,0)])
sepsis <- ff.np('sepsis', data=tt$sepsis, dp=0)
sepsis$p[2]
ssite <- ff.np('sepsis_site', data=wdt[sepsis %in% c(3,4)], dp=0)

wdt[, sofa2.r := gen.sofa.r(pf, fio2_std)]
wdt[, odys := ifelse(
    (sofa_score>1 & sofa_r <= 1) |
    (!is.na(sofa2.r) & sofa2.r > 1),1,0)]
odys <- ff.np('odys', data=wdt, dp=0)

tt$rdys <- data.table(rdys=wdt[, ifelse(!is.na(sofa2.r) & sofa2.r>1, 1,0)])
rdys <- ff.np('rdys', data=tt$rdys, dp=0)
tt$kdys <- data.table(kdys = wdt[,ifelse(sofa_k>1,1,0)])
kdys <- ff.np('kdys', data=tt$kdys, dp=0)

tt$shock <- data.table(shock = wdt[,
    ifelse(   (!is.na(bpsys) & bpsys<90 )
            | (!is.na(bpmap) & bpmap<70 )
            | (!is.na(lactate) & lactate > 2.5 )
            | (!is.na(rxcvs_sofa) & rxcvs_sofa > 1)
            ,1,0)])
shock <- ff.np('shock', data=tt$shock, dp=0)
describe(wdt$sepsis_severity)
  # fname: sepsis_severity
  # sqltype: tinyint
  # varlab: Sepsis status
  # tablerowlabel:
  #   latex: Sepsis status
  # vallab:
  #   0: Neither SIRS nor sepsis
  #   1: SIRS
  #   2: Sepsis
  #   3: Severe sepsis
  #   4: Septic shock
describe(wdt[sepsis_severity==4]$sepsis2001)
  # vallab:
  #   0: No
  #   1: SIRS
  #   2: Sepsis
  #   3: Severe sepsis
  #   4: Septic shock - hypotension alone
  #   5: Septic shock - hypoperfusion alone
  #   6: Septic shock - hypotension and hypoperfusion


wdt[, osupp := ifelse( rxrrt==1 | rx_resp==2 | rxcvs == 2,1,0)]
osupp <- ff.np('osupp', data=wdt, dp=0)

#  =======================
#  = Severity of illness =
#  =======================

aps.news <- ff.mediqr('news_score')
aps.news
aps.sofa <- ff.mediqr('sofa_score')
aps.sofa
aps.icnarc <- ff.mediqr('icnarc_score')
aps.icnarc

describe(wdt$news_risk)

dead2 <- ff.np('dead2', dp=1)
dead7.d2 <- ff.np('dead2', dp=1, data=wdt[dead7==1])
dead7 <- ff.np('dead7', dp=1)
dead90 <- ff.np('dead90', dp=1)
dead1y <- ff.np('dead1y', dp=1)
dead90.wk1 <- ff.np('dead7', dp=1, data=wdt[dead90==1])

# NEWS risk category and mortality
with(tdt, CrossTable(dead7, news_risk))

# Associations with severity
