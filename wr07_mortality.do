* Steve Harris
* Created 140324

* Results - Section - Mortality and ICU admission
* ===============================================

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
*  =====================
*  = Relative survival =
*  =====================

* Paragraph 1
* Acknowledgement needed: http://www.lshtm.ac.uk/eph/ncde/cancersurvival/tools/acknowledgement/index.html
* NOTE: 2014-05-06 - very crude calculation below using mean age only
* - you could improve on this by calculating for each age
* and then weighting by the number of patients in an age band?
* Something to think about?

insheet using "../data/life_tables_1971_2009_england.txt", comma clear
save ../data/life_tables_1971_2009_england, replace
* death rates by sex at age 67 for 2009: 67y is the mean age in the study
li if age == 67 & calendar_year == 2009

use ../data/working_survival.dta, clear
stset dt1, id(id) failure(dead_st) exit(time dt0+365) origin(time dt0)
* Estimate the number of deaths in the last 3 months
sts list, at(0 275 365) enter by(sex)
* For females: divide deaths by number at risk and scale to a year
* then divide by the baseline population mortality above
di 133/4247 * 4 / 0.010348
* ditto for males
di 162/4286 * 4 / 0.0170277

* strel2 uses the dates in stset to define age
use ../data/life_tables_1971_2009_england, clear
rename sex fm
encode fm, gen(sex)
label list sex
gen male = sex == 2
* use the 2009 data
drop if calendar_year != 2009
save ../data/scratch/scratch.dta, replace


use ../data/working_survival_single.dta, clear
gen agediag = (dofc(v_timestamp) - dob)/365.25
gen ageout = (dt4/365.25) + agediag
su age agediag ageout
rename age age_spotlight
gen calendar_year = yofd(date_trace)
list date_trace calendar_year in 1/5

stset ageout, id(id) failure(dead) enter(time agediag)
strel2 using ../data/scratch/scratch.dta, breaks(0(0.08333333)1) mergeby(male) eform rtable trace

*  ===========================
*  = Death in and out of ICU =
*  ===========================

use ../data/working_survival.dta, clear
noi stset dt1, id(id) origin(dt0) failure(dead_st) exit(time dt0+365)
sts list, at(0 1 7 30 365)
sts list, at(0 1 7 30 365) fail

* Plot a cumulative hazard function
sts graph, failure name(dead, replace)

* Generate alternative failure markers
* ====================================

* Marker for ICU admission or death
sort id event
cap drop icu_ever
gen icu_ever = icu_in < _t
order icu_ever, after(icu)
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

* CHANGED: 2014-05-06 - re-draw graph with 3 categories
/*
- died on the ward (no Rx limits)
- died in ICU
- died on the ward (with Rx limits)
*/
cap drop location_limits
gen location_limits = .
replace location_limits = 1 if rxlimits == 0 & icu_ever == 0
replace location_limits = 2 if icu_ever == 1
replace location_limits = 3 if rxlimits == 1 & icu_ever == 0
cap label drop location_limits
label define location_limits ///
	1 "Remained on the ward without treatment limits" ///
	2 "Admitted to ICU" ///
	3 "Treatment limitation order" 
label values location_limits location_limits

* Use missing option else the percentages won't be correct
* NOTE: 2014-05-06 - dropped the following b/c ppsample will not work with time-varying data
* tab location_limits if ppsample, missing
cap restore, not
preserve
collapse (max) location_limits rxlimits icu_ever , by(id)
count
tab location_limits, missing
restore


sts list, at(0 7 365) by(icu_ever rxlimits)
sts list, at(0 7 365) by(location_limits)
sts list, at(0 7 365) by(location_limits) fail

* Plot the risk over the first 7 days
* don't plot day 0 because you don't have accurate times of death for ward pts
sts graph ///
	, ///
	by(location_limits) failure ci ///
	title("") ///
	ytitle("Mortality") ///
	ylab(0 "0%" 0.10 "10%" 0.20 "20%" 0.30 "30%" 0.40 "40%" 0.5 "50%", ///
		nogrid) ///
	ttitle("Days following ward visit") ///
	xsize(4) ysize(6) ///
	tmin(1) ///
	tlab(0(1)7) ///
	tmax(7) ///
	plot1opts(lpattern(solid) lcolor(red)) ///
	plot2opts(lpattern(solid) lcolor(gs8)) ///
	plot3opts(lpattern(solid) lcolor(black)) ///
	ci1opts(lpattern(blank) color(gs12)) ///
	ci2opts(lpattern(blank) color(gs12)) ///
	ci3opts(lpattern(blank) color(gs12)) ///
	legend(off) ///
	name(dead_no_icu, replace)

graph export ../outputs/figures/location_limits.pdf, replace

*  ===============================================================
*  = Characteristics of the patients dying without ICU admission =
*  ===============================================================
collapse (max) location_limits, by(id)
tempfile 2merge
save `2merge', replace
use ../data/working_postflight.dta, clear
merge 1:1 id using `2merge'

*  ================
*  = Frailty term =
*  ================
use ../data/working_survival.dta, clear
stset dt1, id(id) failure(dead_st) exit(time dt0+90) origin(time dt0)
stsplit tb, at(1 4 28)
label var tb "Analysis time blocks"
est use ../data/estimates/survival_full3
est replay
estimates esample: `=e(datasignaturevars)'
local theta_ll = e(theta) - invnormal(0.975) * e(se_theta)
local theta_ul = e(theta) + invnormal(0.975) * e(se_theta)
di "Theta `=e(theta)' (95%CI `theta_ll', `theta_ul')"

*  ======================
*  = Median Hazard Rate =
*  ======================

