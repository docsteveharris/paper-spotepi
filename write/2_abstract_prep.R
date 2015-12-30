#  ============
#  = Abstract =
#  ============

with(wdt, CrossTable(rxlimits))
with(wdt, CrossTable(icu_recommend))
with(wdt, CrossTable(icu_recommend, icu_accept))

with(wdt[icu_recommend==1 & icu_accept==0], CrossTable(icucmp,dead7))
(ff.mediqr('time2icu', data=wdt[icu_recommend==1 & icu_accept==0], dp=0))

with(wdt, CrossTable(icu_recommend, rxlimits))
with(wdt[icu_recommend==0 & rxlimits==1], CrossTable(dead7))
with(wdt[icu_recommend==0 & rxlimits==0], CrossTable(icucmp,dead7))
(ff.mediqr('time2icu', data=wdt[icu_recommend==0 & rxlimits==0], dp=0))

# 7 day mortality
with(wdt, CrossTable(dead90, rxlimits))

with(wdt[rxlimits==0], CrossTable(dead2))
with(wdt[rxlimits==0], CrossTable(dead7))
with(wdt[rxlimits==0], CrossTable(dead90))

with(wdt[rxlimits==0 & icu_recommend], CrossTable(dead7))

with(wdt[rxlimits==0 & icu_recommend & icu_accept==1], CrossTable(dead7))
with(wdt[rxlimits==0 & icu_recommend & icu_accept==0], CrossTable(dead7))

# 90 day mortality
with(wdt[rxlimits==0], CrossTable(dead90))
with(wdt[rxlimits==0 & icu_recommend], CrossTable(dead90))
with(wdt[rxlimits==0 & icu_recommend & icu_accept==1], CrossTable(dead90))
with(wdt[rxlimits==0 & icu_recommend & icu_accept==0], CrossTable(dead90))
