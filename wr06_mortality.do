* Steve Harris
* Created 140324

* Results - Section - Incidence and case-finding
* ==============================================

* Log
* ===
* 140324	- initial set-up

/*

## Mortality

Among the 15,602 (98.3%) patients alive at the end of the visit, there were 704 deaths by the end of the first day, 2,787 by the end of the first week, 4,561 by the end of the first month, and 6,989 by the end of the first year.  The risk of death at these time points was 4.5%, 17.9%, 29.2%, and 44.8% respectively (Kaplan-Meier failure function). The period of greatest risk immediately follows the referral, and rapidly falls, but remains elevated even at one year ([Figure 3][figure3]).{>>Need to add in reference to age standardised mortality here<<}

The overall population could be divided into three: those 'expected to live', those expected to die, and the remainder. The 'expected to live' patients (those without a treatment limitation order, without organ dysfunction when assessed, without a recommendation for critical care, or planned follow-up) numbered 1,179 (7.4%), and had an 8.6% and 13.7% mortality at 28- and 90-days respectively. The 'expected to die' (those with a treatment limitation order) numbered 2,183 (13.8%), and had a 55.7% and 65.4% mortality at 28- and 90 days.  respectively. The remaining 12,485 (78.6%) patients had a 25.7% and 32.2% 28- and 90-day mortality.

A series of models were fitted with 90-day survival as the dependent variable.The final best model [Table 3][table3] incorporated both a time-varying effect for the acute physiology (see supplementary [Figure s1][sfigure1]) measured at the bedside, and a hospital-level frailty.

At the hospital level, with the exception of the two hospitals without a CCOT service, there was a stepwise decrease in survival as the provision of CCOT services. Patients admitted during the winter months had an adjusted hazard ratio of 1.12 (95%CI 1.04--1.20), but neither time of day, nor the day of the week of the visit affected survival.

At the patient level the other risk factors were consistent with existing literature on outcomes in similar patients.[@Harrison:2007jt] Older and physiologically sicker patients had worse outcomes.  The effect of acute severity of illness was evident both through the ICNARC physiology score, and in the level of care that the patient was receiving at the time of the visit. Males were at greater risk of death than females. Septic patients, with the exception of genitourinary sepsis, did worse than non-septic patients.

{>>
outcomes.todo
- report proportion admitted to ICU so you can say only 1/3 of these manifestly sick patients are admitted to ICU
    + cancel this since you would then need to start discussing the number of sites that can contribute to this analysis
<<}

*/

use ../data/working_survival.dta, clear
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

* Plot the risk over the first 7 days
sts graph if icu_ever == 0 ///
	, ///
	by(rxlimits) failure ci ///
	title("Patients not admitted to ICU") ///
	ytitle("Mortality") ///
	ylab(0 "0%" 0.10 "10%" 0.20 "20%" 0.30 "30%" 0.40 "40%" 0.5 "50%", ///
		nogrid) ///
	ttitle("Days following ward visit") ///
	xsize(4) ysize(6) ///
	tlab(0(1)7) ///
	tmax(7) ///
	risktable(0 1 3 7, failevent size(vsmall)  ///
		title("Number at risk (Deaths)", size(small) justification(left)) ///
		order(1 "No treatment limits" 2 "Treatment limits")) ///
	legend(off) ///
	name(dead_no_icu, replace)

graph export ../outputs/figures/failure_no_icu.pdf, replace