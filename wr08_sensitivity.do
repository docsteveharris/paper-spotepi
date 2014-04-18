* Steve Harris
* Created 140418

/*
	Objective is to ensure that any statements are robust to different specifications
	1. check results against data quality criteria
	2. check with and without including sites with alternative provision of critical care
*/

* Log
* 140418	- initial set-up


* 2. Check proportion of admissions dying before admission to ICU
* This needs to be done after excluding sites with alt provision of ICU

* NOTE: 2014-04-18 - code below comes from wr07_mortality.do

*  ===========================
*  = Death in and out of ICU =
*  ===========================

use ../data/working_survival.dta, clear

* How many sites and patients will be dropped
cap drop pickone_patient
egen pickone_patient = tag(id)
count if pickone_patient
tab icode if all_cc_in_cmp == 0 & pickone_patient
drop if all_cc_in_cmp == 0

noi stset dt1, id(id) origin(dt0) failure(dead_st) exit(time dt0+365)
sts list, at(0 1 7 30 365)

* Plot a cumulative hazard function
sts graph, failure name(dead, replace) 

* Generate alternative failure markers
* ====================================

* Marker for ICU admission or death
sort id event
cap drop icu_or_dead
gen icu_or_dead = 0
order icu_or_dead dead_st, after(icu)
replace icu_or_dead = 1 if _d == 1
replace icu_or_dead = 1 if icu_in < _t
noi stset dt1, id(id) origin(dt0) failure(icu_or_dead) exit(time dt0+365)
sts graph, failure name(icu_or_dead, replace)

* Marker for death without ICU admission
cap drop dead_no_icu
gen dead_no_icu = 0
order dead_no_icu, after(icu)
replace dead_no_icu = 1 if _d == 1 & icu_in == .
noi stset dt1, id(id) origin(dt0) failure(dead_no_icu) exit(time dt0+365)
sts graph, by(rxlimits) failure ci xsize(4) ysize(6) name(dead_no_icu, replace)


noi stset dt1, id(id) origin(dt0) failure(dead_no_icu) exit(time dt0+7)
sts graph ///
	, ///
	by(rxlimits) failure ci ///
	ylab(0(0.1)0.5) ///
	xsize(6) ysize(6) ///
	tlab(0(1)7) ///
	risktable(0 2 7, order(1 "False" 2 "True") title("Treatment limits") ///
		failevents size(small)) ///
	legend(off) ///
	name(dead_no_icu, replace)

* Deaths in and out of ICU by Rx-limit status
use ../data/working_survival.dta, clear
* How many sites and patients will be dropped
cap drop pickone_patient
egen pickone_patient = tag(id)
count if pickone_patient
tab icode if all_cc_in_cmp == 0 & pickone_patient
drop if all_cc_in_cmp == 0

* Q: How many deaths in the first week?
noi stset dt1, id(id) origin(dt0) failure(dead_st) exit(time dt0+365)
sts list, at(0 7 30)

* Q: How many of these deaths were in patients who had been admitted to ICU
cap drop icu_ever
gen icu_ever = icu_in < _t
order icu_ever, after(icu)
sts list, at(0 7) by(icu_ever)

* Q: How many of the deaths out of ICU were in patients w/o treatment limits
sts list, at(0 7) by(icu_ever rxlimits)

* Q: How many deaths occured in patients accepted to ICU while waiting
sts list, at(0 7) by(icu_ever rxlimits icu_accept)

* Q: How many patients with rx limits survive 1 year without admission to critical care?

sts list, at(0 365) by(icu_ever rxlimits)
