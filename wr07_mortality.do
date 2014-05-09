* Steve Harris
* Created 140324

* Results - Section - Mortality and ICU admission
* ===============================================

* Log
* ===
/*
140324
- initial set-up
140507
- re-write using working_postflight as skeleton
I think prior to this there are deaths at entry to survival data that I am not seeing
when I report the survival numbers.
*/

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
strel2 using ../data/scratch/scratch.dta, ///
	breaks(0(0.08333333)1) mergeby(male) eform rtable trace

*  ===========================
*  = Death in and out of ICU =
*  ===========================

use ../data/working_survival.dta, clear
noi stset dt1, id(id) origin(dt0) failure(dead_st) exit(time dt0+365)
sts list, at(0 1 7 30 365)
sts list, at(0 1 7 30 365) fail


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
sts list if rxlimits == 0, at(0 7) by(icu_ever)
sts list, at(0 7) by(icu_ever rxlimits)

* Q: How many deaths occured in patients accepted to ICU while waiting
sts list, at(0 7) by(icu_ever rxlimits icu_accept)

* Q: How many patients with rx limits survive 1 year without admission to critical care?

sts list, at(0 365) by(icu_ever rxlimits)

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

* Redefine dead7 using survival data set-up 
* NOTE: 2014-05-07 - previously dead7 included deaths on day 7 (i.e. <= not <)
tempvar x
gen `x' = _t < 7 & _d == 1
cap drop dead7lt
bys id: egen dead7lt = max(`x')
label var dead7lt "within 7d mortality"
label values dead7lt truefalse

* Now collapse over patient
collapse (max) location_limits icu_ever dead7lt , by(id)
tab location_limits, missing
tab dead7lt

tempfile 2merge
save `2merge', replace

* Now switch back to main data
use ../data/working_postflight.dta, clear
merge 1:1 id using `2merge'
tempfile working
save ../data/scratch/scratch.dta, replace
use ../data/scratch/scratch.dta, clear


gen ward_death = .
label var ward_death "Ward death"
replace ward_death = 0 if dead7lt & icu_ever == 1 & rxlimits == 0
replace ward_death = 1 if dead7lt & icu_ever == 0 & rxlimits == 0

tab ward_death

* Deaths without admission to critical care?
* NOTE: 2014-05-07 - there remains a discrepancy between the numbers reported
* by the survival function and the numbers in the raw data
tab icu_ever dead7lt, col
tab ward_death dead7lt

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

