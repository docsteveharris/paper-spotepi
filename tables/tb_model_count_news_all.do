* Steve Harris
* LOG
* ===

* 140226
* - Cloned from spot_ward
* 140226
* - modify this to use lagged occupancy from week prior
* 140313
* - estimates daily instead of weekly incidence
* - so the structure of this model is wrong! Detailed note below:
	/*

	You wish to estimate daily incidence but you are collapsing over days
	from the patient data set. The only days that appear are therefore those
	where an admission is reported.
	This worked OK when you examined weekly incidence because it was rare
	for there to be a week without an admission. However it is more common
	for there to be a zero day. These days are not represented in your data.
	Need to start out using the occupancy data and then merge in the admissions
	and other site details.
	*/
* 140418
* - added outsheet command
* NOTE: 2014-05-06 - lincom command in around line 241 estimates effect of 24/7 vs 7/7 incidence
* 2015-12-01 
* - moved under waf control
* - population examined adjusted to drop 49th site
* - problems with spot_label_table_vars (python and MySQL issues)
* 2015-12-29
* - simplified
* - report model as supplementary table?
* - remove elective emergency indicator
* - swap beds_none for room_cmp2
* - remove referral pattern adjustment
* - add back in weekend
* - remove mp_throughput
* - check incidence per 1000 is for NEWS high risk ? @done(2015-12-29)
* 2015-12-29
* - removed news high restriction
* - dropped occupancy vars -  not sure how to interpret
* 2016-03-02
* - added in code to est per 1000 overnight admission


*  ============================
*  = Incidence NEWS RISK HIGH =
*  ============================


* - [ ] NOTE(2015-12-01): under waf control
clear

* CHANGED: 2014-02-26 - changed project reference
* GenericSetupSteveHarris mas_spotepi tb_model_count_news_all, logon
global table_name incidence_news_all
set seed 3001

* Occupancy by day (lagged and direct)
* ------------------------------------
* CHANGED: 2014-02-26 - now merge in the specific occupancy details and the lag
use ../data/working_occupancy, clear
merge m:1 icode using ../data/sites.dta, keepusing(lite_open lite_close)
drop _merge
preserve
use ../data/working_postflight.dta, clear
contract icode
drop _freq
tempfile 2merge
save `2merge', replace
restore
merge m:1 icode using `2merge'
drop if _merge != 3
drop _merge
drop if odate < lite_open
drop if odate > lite_close

keep icode icnno odate ohrs free_beds_cmp beds_none beds_blocked room_cmp2
collapse (median) beds_none_l0 = beds_none beds_blocked_l0 = beds_blocked (mean) free_beds_cmp_l0 = free_beds_cmp room_cmp2_l0 = room_cmp2, by(icode odate)
encode icode, gen(site)
tsset site odate

* CHANGED: 2014-03-13 - uses median so now need to convert 0.5 to 1
replace beds_none_l0 = beds_none_l0 != 0
replace beds_blocked_l0 = beds_blocked_l0 != 0

gen beds_none_l1 = L.beds_none_l0
gen beds_blocked_l1 = L.beds_blocked_l0
gen free_beds_cmp_l1 = L.free_beds_cmp_l0
cap drop room_cmp2_l1
gen room_cmp2_l1 = L.room_cmp2_l0
replace room_cmp2_l1 = round(room_cmp2_l1)
tab room_cmp2_l1
replace room_cmp2_l1 = room_cmp2_l1 -1
cap drop room_cmp2_l1_i*
gen room_cmp2_l1_i0 = room_cmp2_l1 == 0
gen room_cmp2_l1_i1 = room_cmp2_l1 == 1
gen room_cmp2_l1_i2 = room_cmp2_l1 == 2
su room_cmp2_l1_i*

* gen decjanfeb = inlist(month(odate),11,12,1)
gen winter = inlist(month(odate),12,1,2,3)
label var winter "Winter"
tab winter

cap drop weekend
gen weekend = inlist(dow(odate), 0, 6)
label var weekend "Day of week"
label define weekend 0 "Monday--Friday"
label define weekend 1 "Saturday--Sunday", add
label values weekend weekend
tab weekend

* global timing_vars 	winter weekend room_cmp2_l1_i0 room_cmp2_l1_i1 // occupancy for the *day* before
global timing_vars 	winter weekend // occupancy for the *day* before

* One row per day: now build the analysis data from this
* ------------------------------------------------------
save ../data/scratch/scratch.dta, replace

* Prepare data from working_postflight
* ------------------------------------
use ../data/working_postflight.dta, clear
su hes_overnight if pickone_site
global hes_overnight_bar = r(mean) 
di $hes_overnight_bar
cap drop ccot_p_*
tabulate ccot_shift_pattern, generate(ccot_p_)
su ccot_p_*

su patients_perhesadmx if pickone_site, d
cap drop pts_hes_k*
* Define referral rate thresholds
* NOTE: 2013-05-05 - thresholds chosen after visual inspection of cubic spline in univariate
gen pts_hes_k1 = patients_perhesadmx < 5
gen pts_hes_k2 = patients_perhesadmx < 15 & patients_perhesadmx >= 5
gen pts_hes_k3 = patients_perhesadmx >= 15 & patients_perhesadmx != .
su pts_hes_k* if pickone_site

* This will be your merge variable
cap drop odate
gen odate = dofC(v_timestamp)

* Keep all
local model_name = "NEWS risk - all"
tab news_risk

*  ===============================================
*  = Model variables assembled into single macro =
*  ===============================================

* global site_vars teaching_hosp hes_overnight_c hes_emergx_c ccot_p_1 ccot_p_2 ccot_p_3
global site_vars teaching_hosp hes_overnight_c
global ccot_vars ccot_p_1 ccot_p_2 ccot_p_3

	* NOTE: 2014-02-21 - replace ib3 with below
	* if you wish to calculate using <7 as baseline
	* ib1.ccot_shift_pattern

* global study_vars pts_hes_k1 pts_hes_k2 pts_hes_k3
global study_vars 

* global unit_vars cmp_beds_max_c cmp_throughput
global unit_vars cmp_beds_max_c 


global model_vars $site_vars $study_vars $unit_vars $timing_vars
di "$model_vars"
* Generate a counter variable
cap drop new_patients
gen new_patients = 1
label var new_patients "New patients (per day)"

* Collapse over site days
* CHANGED: 2014-03-24 - add in ccot_shift_pattern so can re-run model with 
* different baseline
collapse ///
	(count) vperday = new_patients ///
	(firstnm) $site_vars $ccot_vars ccot_shift_pattern patients_perhesadmx_c ///
	(firstnm) pts_hes_k1 pts_hes_k2 pts_hes_k3 ///
	(median) $unit_vars ///
	(min) studymonth visit_month ///
	, by(site odate)
d

tempfile 2merge
save `2merge', replace

use ../data/scratch/scratch.dta, clear
gen vperday = 0
label var vperday "Visits per day"
* Merge just vperday this time
* Merge with update replace so vperday is overwritten
merge 1:1 site odate using `2merge', update replace keepusing(vperday)
drop if _merge == 2 // patient day records not found in occupancy
rename _merge merge_icode_odate

tempfile working
save `working'

* Now collapse over site and merge
use `2merge', clear
egen pickone_site = tag(site)
keep if pickone_site
drop vperday
save `2merge', replace

use `working', clear
merge m:1 site using `2merge'
rename _merge merge_icode

d
su winter
su weekend
tab room_cmp2_l1
* reset centering for hes_overnight
lookfor hes
* cap drop pickone_site
* egen pickone_site = tag(icode)
* su hes_overnight if pickone_site
* replace hes_overnight_c = hes_overnight - 50

* Data preparation complete
* -------------------------
save ../data/scratch/scratch.dta, replace

use ../data/scratch/scratch.dta, clear
* Check missing model vars

est drop _all
xtset site odate, daily

*  =================================
*  = Macros etc for building table =
*  =================================
tempfile estimates_file
local model_sequence = 1
local table_order = 1
local i 3
local model_name = "NEWS risk all"

* model without patients_perhesadmx to examine 'effect' of ccot
xtgee vperday $site_vars $ccot_vars $unit_vars $timing_vars ///
	, family(poisson) link(log) force corr(ar 1) eform i(site) t(odate)
* model without rcs for referral patterns
xtgee vperday $site_vars patients_perhesadmx_c $unit_vars $timing_vars ///
	, family(poisson) link(log) force corr(ar 1) eform i(site) t(odate)
// CHANGED: 2013-05-05 - allow patients_perhesadmx in as cubic spline
// first a model with a cubic spline for the patients_perhesadmx
mkspline2 pts_hes_rcs = patients_perhesadmx_c, cubic nknots(4) displayknots
* CHANGED: 2013-05-06 - now use xtgee to handle autocorrelation
xtgee vperday $site_vars pts_hes_rcs* $unit_vars $timing_vars ///
	, family(poisson) link(log) force corr(ar 1) eform i(site) t(odate)
est store news_all_cubic
est save ../data/estimates/news_all_cubic, replace
// save the data for use with estimates again, 'all' saves estimates
save ../data/count_news_all_cubic, replace all

// now the linear model for the table
* now the model without patients_perhesadmx for the final table
* model without patients_perhesadmx to examine 'effect' of ccot
xtgee vperday $site_vars $ccot_vars $unit_vars $timing_vars ///
	, family(poisson) link(log) force corr(ar 1) eform i(site) t(odate)
est store news_all_linear
est save ../data/estimates/news_all_linear, replace
// save the data for use with estimates again, 'all' saves estimates
save ../data/count_news_all_linear, replace all

* CHANGED: 2014-03-19 - work out IRR for a week and a month
lincom _cons, irr
di "per week: " + 7 * r(estimate)
di "L95CI: "  + 7 * (r(estimate) - 1.96 * r(se))
di "U95CI: "  + 7 * (r(estimate) + 1.96 * r(se))
* Per month
di "per month: " + 365/12 * r(estimate)
di "L95CI: "  + 365/12 * (r(estimate) - 1.96 * r(se))
di "U95CI: "  + 365/12 * (r(estimate) + 1.96 * r(se))

* Stata calc from baseline incidence to per 10000 overnight
* Equivalent to 22 per month x 12 months / 53.8k overnight admissions/year
di "per 1000: " + 365 * r(estimate) / $hes_overnight_bar
di "L95CI: "  + 365 * (r(estimate) / $hes_overnight_bar) - 1.96 * r(se)
di "U95CI: "  + 365 * (r(estimate) / $hes_overnight_bar) + 1.96 * r(se)

* NOTE: 2014-03-24 - run model with factor variable notation
* Now use this to calculate the effect of 24/7 outreach on IRR cf 7 days
preserve
xtgee vperday ///
	teaching_hosp ///
	hes_overnight_c ///
	ib3.ccot_shift_pattern ///
	$unit_vars $timing_vars ///
	, family(poisson) link(log) force corr(ar 1) eform i(site) t(odate)

lincom 3.ccot_shift_pattern -  1.ccot_shift_pattern, irr
restore

parmest, ///
	label list(parm label estimate min* max* p) ///
	eform ///
	idnum(`i') idstr("`model_name'") ///
	stars(0.05 0.01 0.001) ///
	format(estimate min* max* %9.3f p %9.3f) ///
	saving(`estimates_file', replace)

use `estimates_file', clear
gen table_order = `table_order'
gen model_sequence = `model_sequence'
local ++table_order
save ../data/tb_$table_name.dta, replace
outsheet using "../write/tables/tb_$table_name.csv", ///
     replace comma

cap log close
