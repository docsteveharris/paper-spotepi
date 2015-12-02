* author: Steve Harris
* date: 2015-12-02
* subject: 

* Readme
* ======


* Todo
* ====


* Log
* ===
* 2015-12-02
* - file created
* - code copied from /Users/steve/aor/academic/analysis-spot-study/vcode/an_occupancy.do

*  ==============================================
*  = Examine occupancy with respect to time etc =
*  ==============================================

local ddsn mysqlspot
local uuser stevetm
local ppass ""

set scheme shbw
GenericSetupSteveHarris spot an_occupancy, logon

* NOTE: 2013-12-15 - pull data directly from spot_early instead

* odbc query "`ddsn'", user("`uuser'") pass("`ppass'") verbose
* odbc load, exec("SELECT m.icnno, m.icode, s.date_opened AS lite_open, s.date_closed AS lite_close, IF(u.cmp_beds_min < u.cmp_beds_max, u.cmp_beds_max, u.cmp_beds_min) AS cmp_beds_max FROM metasiteunit AS m LEFT JOIN sitesfinal AS s ON m.icode = s.icode LEFT JOIN unitsfinal AS u ON m.icnno = u.icnno")  dsn("`ddsn'") user("`uuser'") pass("`ppass'") lowercase sqlshow clear
* drop if inlist(icnno,"XXX","A01")
* duplicates drop icnno, force
use ../../spot_early/data/working_postflight.dta, clear
drop if missing(icnno)
collapse (firstnm) icode lite_open lite_close cmp_beds_max, by(icnno)
replace icnno=upper(icnno)
list  in 1/10

tempfile 2merge
save `2merge', replace

use ../data/occupancy_all24.dta, clear

tab icnno if occupancy == .
/* NOTE: 2013-01-12 - assume if occupancy is zero then unit is closed */
replace occupancy = . if occupancy == 0
replace occupancy_active = . if occupancy == 0

merge m:1 icnno using `2merge'
keep if odate >= lite_open & odate <= lite_close
drop _m
count

save ../data/working_occupancy.dta, replace
use ../data/working_occupancy.dta, clear
/*
Now you need to collapse the data so that times are represented 'equally'
i.e. you have calculated occupancy every 4 hours so you only need these timepoints
else averages won't make sense
*/


order occupancy occupancy_active, after(otimestamp)
gen unit_month = mofd(dofc(otimestamp))
/*
NOTE: 2013-01-10 - avoid brief 'blips' in occupancy when est max
Monthly max will now only depend on occupancy that is sustained for a full calendar day
*/
bys icnno odate: egen occ_perday_min = min(occupancy)

bys icnno unit_month: egen occupancy_max = max(occ_perday_min)
label var occupancy_max "Monthly maximum occupancy"

bys icnno unit_month: egen occupancy_median = median(occupancy)
label var occupancy_median "Monthly median occupancy"

gen free_beds = (occupancy_max - occupancy)
label var free_beds "Empty beds with respect to monthly max"

gen free_beds_pct = (occupancy_max - occupancy) / occupancy_max * 100
label var free_beds_pct "Percent empty beds"

gen free_beds_cmp = (cmp_beds_max - occupancy)
label var free_beds_cmp "Empty beds with respect to CMP reported number"

gen free_beds_cmp_pct = (cmp_beds_max - occupancy) / cmp_beds_max * 100
label var free_beds_cmp_pct "Percent empty beds with respect to CMP reported number"

/* Now examine unblocked beds */
gen open_beds_cmp = (cmp_beds_max - occupancy_active)
label var open_beds_cmp "Open beds with respect to CMP reported number"

gen open_beds_cmp_pct = (cmp_beds_max - occupancy_active) / cmp_beds_max * 100
label var open_beds_cmp_pct "Percent open beds with respect to CMP reported number"

order icode icnno otimestamp cmp_beds_max occupancy* free_beds* open_beds*
cap drop _*

* NOTE: 2013-01-12 - makes sense to measure this as absolute beds not a percentage
gen full_physically0 = free_beds_cmp <= 0
label var full_physically0 "No physically empty beds"
gen full_physically1 = free_beds_cmp <= 1
label var full_physically1 "No more than 1 physically empty bed"

gen full_active0 = open_beds_cmp <= 0
label var full_active0 "No beds / None dischargable"
gen full_active1 = open_beds_cmp <= 1
label var full_active1 "No more than 1 dischargeable patient"




*  ========================
*  = Time and period vars =
*  ========================
cap drop ccadmx_tod
gen ccadmx_hour = hhC(otimestamp)
label var ccadmx_hour "Crit care admission - hour of day"
tab ccadmx_hour

cap drop ccadmx_dow
gen ccadmx_dow = dow(dofC(otimestamp))
label var ccadmx_dow "Crit Care admission - day of week"
label define dow ///
	0 "Sun" ///
	1 "Mon" ///
	2 "Tue" ///
	3 "Wed" ///
	4 "Thu" ///
	5 "Fri" ///
	6 "Sat"
label values ccadmx_dow dow
tab ccadmx_dow

* NOTE: 2013-01-11 - not sure that can make much of this given incomplete annual data
cap drop ccadmx_month
gen ccadmx_month = month(dofC(otimestamp))
label var ccadmx_month "Crit Care admission - month of year"
label define month ///
	1 	"Jan" ///
	2 	"Feb" ///
	3 	"Mar" ///
	4 	"Apr" ///
	5 	"May" ///
	6 	"Jun" ///
	7 	"Jul" ///
	8 	"Aug" ///
	9 	"Sep" ///
	10 	"Oct" ///
	11 	"Nov" ///
	12 	"Dec"
label values ccadmx_month month
tab ccadmx_month


save ../data/working_occupancy.dta, replace
pwd
cd /users/steve/aor/academic/paper-spotepi/src/figures
use ../data/working_occupancy.dta, clear

*  =====================
*  = Inspect free beds =
*  =====================
cap drop fb
gen fb = free_beds_cmp_pct
replace fb = 0 if fb < 0
hist fb, s(0) w(5) percent ///
	ylabel(,nogrid) ///
	xscale(noextend) ///
	yscale(noextend) ///
	xtitle("Unoccupied beds (%)" "as a percentage of total reported physical capacity")

graph rename free_beds_histogram, replace

*  =================================================
*  = Inspect free beds with respect to time of day =
*  =================================================

/*
- inspect percentage free
- inspect proportion of time full / nearly full
*/
use ../data/working_occupancy.dta, clear

collapse (mean) free_beds_mean = free_beds_cmp_pct ///
	(semean) free_beds_se = free_beds_cmp_pct, by(ccadmx_hour)
drop if ccadmx_hour == .

gen free_beds_l95 = (free_beds_mean - 1.96 * free_beds_se)
gen free_beds_u95 = (free_beds_mean + 1.96 * free_beds_se)
su free_beds*
// for the purposes of the plot don't draw the upper CI if too high

tw 	(rspike free_beds_u95 free_beds_l95 ccadmx_hour, lcolor(gs12)) ///
	(scatter free_beds_mean ccadmx_hour, msize(small) msymbol(o)), ///
	xlabel(0(4)24) xscale(noextend) ///
	xtitle("Hour of day") ///
	ylabel(0(5)30, nogrid) yscale(noextend) ///
	ytitle("Free beds (%)") ///
	legend(off)

graph rename free_beds_by_hour`j', replace
graph export ../logs/free_beds_by_hour`j'.pdf, replace


*  ==================================================================
*  = Plot prob full with/without patients pending discharge by time =
*  ==================================================================
use ../data/working_occupancy.dta, clear

/*
Need to come up with some measure of precision
The only sensible 'n' to choose is the number of units sampled?
- times the number of days observed
Then the confidence intervals would describe the likely occupancy all units
based on this sample
*/
* NOTE: 2013-01-12 - the number of units in the sample is 122
local sample_size = _N


collapse (mean) ///
	 full_physically0_bar = full_physically0 full_physically1_bar = full_physically1 ///
	 full_active0_bar = full_active0 full_active1_bar = full_active1 ///
	 ,by(ccadmx_hour)
drop if ccadmx_hour ==.

local vars full_active1 full_active0 full_physically1 full_physically0

gen n = `sample_size' / _N
* NOTE: 2013-01-12 - divide by 24 since each hour is sampled only once per day
foreach var of local vars  {
	cap drop o p se_logodds error_factor o_l95 o_u95
	gen p = `var'_bar
	// convert the proportion to an odds
	gen o = p / (1 - p)
	// standard error of log odds
	gen se_logodds = (((1 / p) + 1 / (1 - p)) / n) ^ 0.5
	gen error_factor = exp(1.96 * se_logodds)
	gen o_l95 = o / error_factor
	gen o_u95 = o * error_factor
	gen `var'_l95 = (o_l95 / (1 + o_l95)) * 100
	gen `var'_u95 = (o_u95 / (1 + o_u95)) * 100
	// for the purposes of the plot don't draw the upper CI if too high
	replace `var'_u95 = 20 if `var'_u95 > 20
	replace `var'_bar = 100 * `var'_bar
	cap drop o p se_logodds error_factor o_l95 o_u95
	order `var'_bar `var'_l95 `var'_u95, after(ccadmx_hour)
}


su full*
// for the purposes of the plot don't draw the upper CI if too high

tw 	///
	(rspike full_active0_u95 full_active0_l95 ccadmx_hour, lcolor(gs12)) ///
	(scatter full_active0_bar ccadmx_hour, msize(small) msymbol(o)) ///
	(rspike full_physically0_u95 full_physically0_l95 ccadmx_hour, lcolor(gs12)) ///
	(scatter full_physically0_bar ccadmx_hour, msize(small) msymbol(oh)), ///
	xlabel(0(4)24) xscale(noextend) ///
	xtitle("Hour of day") ///
	ylabel(0(5)20, nogrid) yscale(noextend) ///
	ytitle("Probability unit full (%)") ///
	legend(label(2 "Full without patients pending d/c") ///
		label(4 "Full with patients pending d/c") ///
		order(4 2) pos(2) ring(0) )

graph rename full_by_hour`j', replace
graph export ../logs/full_by_hour`j'.pdf, replace

*  ========================================================================
*  = Plot prob full with/without patients pending discharge by time / dow =
*  ========================================================================
use ../data/working_occupancy.dta, clear
/*
Need to come up with some measure of precision
The only sensible 'n' to choose is the number of units sampled?
- times the number of days observed
Then the confidence intervals would describe the likely occupancy all units
based on this sample
*/
* NOTE: 2013-01-12 - the number of units in the sample is 122
local sample_size = _N


collapse (mean) ///
	 full_physically0_bar = full_physically0 full_physically1_bar = full_physically1 ///
	 full_active0_bar = full_active0 full_active1_bar = full_active1 ///
	 ,by(ccadmx_hour ccadmx_dow)
drop if ccadmx_hour ==.

local vars full_active1 full_active0 full_physically1 full_physically0

gen n = `sample_size' / _N
* NOTE: 2013-01-12 - divide by 24 since each hour is sampled only once per day
foreach var of local vars  {
	cap drop o p se_logodds error_factor o_l95 o_u95
	gen p = `var'_bar
	// convert the proportion to an odds
	gen o = p / (1 - p)
	// standard error of log odds
	gen se_logodds = (((1 / p) + 1 / (1 - p)) / n) ^ 0.5
	gen error_factor = exp(1.96 * se_logodds)
	gen o_l95 = o / error_factor
	gen o_u95 = o * error_factor
	gen `var'_l95 = (o_l95 / (1 + o_l95)) * 100
	gen `var'_u95 = (o_u95 / (1 + o_u95)) * 100
	// for the purposes of the plot don't draw the upper CI if too high
	replace `var'_u95 = 20 if `var'_u95 > 20
	replace `var'_bar = 100 * `var'_bar
	cap drop o p se_logodds error_factor o_l95 o_u95
	order `var'_bar `var'_l95 `var'_u95, after(ccadmx_hour)
}


su full*
// for the purposes of the plot don't draw the upper CI if too high

cap drop timing
gen timing = ccadmx_dow + ccadmx_hour / 24
// trick to remove the label from the x axis
label var timing " "
* NOTE: 2013-01-12 - note special case using multiple axes and 1 scale
sort timing
tw 	///
	(rarea full_active0_u95 full_active0_l95 timing, pstyle(ci)) ///
	(line full_active0_bar timing, lpattern(solid) lcolor(black) xaxis(1 2)) ///
	(rarea full_physically0_u95 full_physically0_l95 timing, pstyle(ci)) ///
	(line full_physically0_bar timing, lpattern(dash) lcolor(black) xaxis(1 2) ), ///
	xlabel(0 "Sun" 1 "Mon" 2 "Tue" 3 "Wed" 4 "Thu" 5 "Fri" 6 "Sat" 7 "Sun", axis(1)) ///
	xscale(range(0(1)7) noextend axis(1) alt) ///
	xtitle(" " ) ///
	xlabel(0 "00h" 0.25 "06h" 0.5 "12h" 0.75 "18h" 1 "24h", ///
		axis(2) labsize(vsmall)) ///
	xscale(range(0 1) noextend axis(2)) ///
	ylabel(0(5)15, nogrid) yscale(noextend) ///
	ytitle("Probability unit full (%)") ///
	legend( ///
		order( 3 2 ) ///
		label(2 "Without discharges pending") ///
		label(3 "With discharges pending") ///
		pos(4) ring(0) )

graph rename full_by_week, replace
graph display full_by_week
graph export ../outputs/figures/full_by_week.pdf ///
    , name(full_by_week) replace

* Simpler graph with just beds_blocked
tw 	///
	(rarea full_active0_u95 full_active0_l95 timing, pstyle(ci)) ///
	(line full_active0_bar timing, lpattern(solid) lcolor(black) xaxis(1 2)) ///
	, ///
	xlabel(0 "Sun" 1 "Mon" 2 "Tue" 3 "Wed" 4 "Thu" 5 "Fri" 6 "Sat" 7 "Sun", axis(1)) ///
	xscale(range(0(1)7) noextend axis(1) alt) ///
	xtitle(" " ) ///
	xlabel(0 "00h" 0.25 "06h" 0.5 "12h" 0.75 "18h" 1 "24h", ///
		axis(2) labsize(vsmall)) ///
	xscale(range(0 1) noextend axis(2)) ///
	ylabel(0(5)15, nogrid) yscale(noextend) ///
	ytitle("Probability unit full (%)") ///
	legend(off)

graph rename full_by_week_active, replace
graph display full_by_week_active
graph export ../outputs/figures/full_by_week_active.pdf ///
    , name(full_by_week_active) replace

cap log close
