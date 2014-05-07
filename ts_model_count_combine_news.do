*  =======================================================
*  = Comparative table of incidence factors by NEWS risk =
*  =======================================================

* 140319
* - cloned from spot_ward
* - merged using tb_model_count_news_high
* - added in cmp_throughput and teaching_hosp
* - runs on vperday
* - estimates daily instead of weekly incidence


GenericSetupSteveHarris mas_spotepi ts_model_count_combine_news, logon
global table_name model_count_combine_news
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

keep icode icnno odate ohrs free_beds_cmp beds_none beds_blocked
collapse (median) beds_none_l0 = beds_none ///
	beds_blocked_l0 = beds_blocked ///
	(mean) free_beds_cmp_l0 = free_beds_cmp, by(icode odate)
encode icode, gen(site)
tsset site odate

* CHANGED: 2014-03-13 - uses median so now need to convert 0.5 to 1
replace beds_none_l0 = beds_none_l0 != 0
replace beds_blocked_l0 = beds_blocked_l0 != 0

gen beds_none_l1 = L.beds_none_l0
gen beds_blocked_l1 = L.beds_blocked_l0
gen free_beds_cmp_l1 = L.free_beds_cmp_l0


gen decjanfeb = inlist(month(odate),11,12,1)

global timing_vars ///
	decjanfeb ///
	beds_none_l1 // occupancy for the *day* before

* One row per day: now build the analysis data from this
* ------------------------------------------------------
save ../data/scratch/scratch.dta, replace


* Prepare data from working_postflight
* ------------------------------------
use ../data/working_postflight.dta, clear
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
gen odate = dofC(v_timestamp)

*  ===============================================
*  = Model variables assembled into single macro =
*  ===============================================

global site_vars ///
	teaching_hosp ///
	hes_overnight_c ///
	hes_emergx_c ///
	ccot_p_1 ///
	ccot_p_2 ///
	ccot_p_3

	* NOTE: 2014-02-21 - replace ib3 with below
	* if you wish to calculate using <7 as baseline
	* ib1.ccot_shift_pattern

global study_vars ///
	pts_hes_k1 pts_hes_k2 pts_hes_k3

global unit_vars ///
	cmp_beds_max_c ///
	cmp_throughput


global model_vars $site_vars $study_vars $unit_vars $timing_vars

*  ==================
*  = Now build loop =
*  ==================
local i 1
local model_name = "NEWS risk `i'"
tab news_risk
tempfile preloop
save `preloop', replace
forvalues i = 1/3 {
	use `preloop', clear
	keep if news_risk == `i'
	tab news_risk
	* Generate a counter variable
	cap drop new_patients
	gen new_patients = 1
	label var new_patients "New patients (per day)"
	* Collapse over site days
	collapse ///
		(count) vperday = new_patients ///
		(firstnm) $site_vars patients_perhesadmx_c ///
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
	save `working', replace

	* Now collapse over site and merge
	use `2merge', clear
	egen pickone_site = tag(site)
	keep if pickone_site
	drop vperday
	save `2merge', replace

	use `working', clear
	merge m:1 site using `2merge'
	rename _merge merge_icode

	* Data preparation complete
	* -------------------------
	* Check missing model vars

	est drop _all
	xtset site odate, daily

	*  =================================
	*  = Macros etc for building table =
	*  =================================
	tempfile estimates_file
	local model_sequence = 1
	local table_order = 1
	local model_name = "NEWS risk `i'"

	// now the linear model for the table
	xtgee vperday $site_vars $unit_vars $timing_vars ///
	 	pts_hes_k1 pts_hes_k3 ///
		, family(poisson) link(log) force corr(ar 1) eform i(site) t(odate)
	est store news_high_linear_`i'
	est save ../data/estimates/news_high_linear_`i', replace
	// save the data for use with estimates again, 'all' saves estimates
	* save ../data/count_news_high_linear, replace all

	* CHANGED: 2014-03-19 - work out IRR for a week and a month
	lincom _cons, irr
	di "per week: " + 7 * r(estimate)
	di "L95CI: "  + 7 * (r(estimate) - 1.96 * r(se))
	di "U95CI: "  + 7 * (r(estimate) + 1.96 * r(se))
	* Per month
	di "per month: " + 365/12 * r(estimate)
	di "L95CI: "  + 365/12 * (r(estimate) - 1.96 * r(se))
	di "U95CI: "  + 365/12 * (r(estimate) + 1.96 * r(se))

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
	if `i' == 1 {
		save ../outputs/tables/$table_name.dta, replace
	}
	else {
		save `estimates_file', replace
		use ../outputs/tables/$table_name.dta, clear
		append using `estimates_file'
		save ../outputs/tables/$table_name.dta, replace
	}
	local ++model_sequence

}

* Export to excel then import this as a 'raw' table into the master tables spreadsheet
* For each raw table, derive a formatted final table for publication
outsheet using "../outputs/tables/ts_$table_name.csv", ///
     replace comma

