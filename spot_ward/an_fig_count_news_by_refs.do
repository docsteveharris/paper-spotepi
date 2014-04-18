*  ===================================================================
*  = Plot the relationship between incidence, referrals and severity =
*  ===================================================================

GenericSetupSteveHarris mas_spotepi an_fig_count_news_by_refs, logon
set seed 3001

local clean_run 1
if `clean_run' == 1 {
    clear
    use ../data/working.dta
    qui include cr_preflight.do
}
use ../data/working_occupancy, clear
keep icode icnno odate beds_none
gen v_week = wofd(odate) 
collapse (mean) beds_none_week = beds_none, by(icode v_week)
// convert mean beds_none (occupancy) to a 10% change from 0 so can be interpreted
replace beds_none_week = 100 * beds_none_week
drop if missing(icode, v_week, beds_none)
tempfile 2merge
save `2merge', replace

use ../data/working_postflight.dta, clear
gen v_week = wofd(dofC(v_timestamp))
label var v_week "Visit week"
merge m:1 icode v_week using `2merge'
drop if _merge  == 2
drop _merge
est drop _all
//NOTE: 2013-01-18 - gllamm does not like factor variables
//so expand up your ccot_shift_pattern (leaving 24/7 as the reference)
//which is why ccot_p_4 does not appear in the ivars list
cap drop ccot_p_*
tabulate ccot_shift_pattern, generate(ccot_p_)
su ccot_p_*

su patients_perhesadmx if pickone_site, d
cap drop pts_hes_k*
* NOTE: 2013-05-05 - thresholds chosen after visual inspection of cubic spline in univariate
gen pts_hes_k1 = patients_perhesadmx < 5 
gen pts_hes_k2 = patients_perhesadmx < 15 & patients_perhesadmx >= 5
gen pts_hes_k3 = patients_perhesadmx >= 15 & patients_perhesadmx != .
su pts_hes_k* if pickone_site

save ../data/scratch/scratch.dta, replace
use ../data/scratch/scratch.dta, clear


*  ===============================================
*  = Model variables assembled into single macro =
*  ===============================================

global site_vars ///
	hes_overnight_c ///
	hes_emergx_c ///
	ccot_p_1 ///
	ccot_p_2 ///
	ccot_p_3 

global study_vars ///
	pts_hes_k1 pts_hes_k2 pts_hes_k3

global unit_vars ///
	cmp_beds_max_c 

global timing_vars ///
	decjanfeb ///
	beds_none_week

global model_vars $site_vars $study_vars $unit_vars $timing_vars

*  =================================
*  = Macros etc for building table =
*  =================================
tempfile estimates_file
local i = 1
local model_sequence = 1
local table_order = 1
/*
pp 395 of Rabe-Hesketh: recommend using the robust SE (sandwich estimator)
- this means using gllamm
*/

forvalues i = 1/3 {
	local model_name = "NEWS risk `i'"
	use ../data/scratch/scratch.dta, clear
	tab news_risk
	keep if news_risk == `i'
	tab news_risk
	cap drop new_patients
	gen new_patients = 1
	label var new_patients "New patients (per week)"
	collapse ///
		(count) vperweek = new_patients ///
		(firstnm) $site_vars patients_perhesadmx_c patients_perhesadmx ///
		(firstnm) pts_hes_k1 pts_hes_k2 pts_hes_k3 ///
		(median) $unit_vars ///
		(max) $timing_vars ///
		(min) studymonth visit_month ///
		, by(site v_week)
	d 
	xtset site v_week, weekly
	// CHANGED: 2013-05-05 - allow patients_perhesadmx in as cubic spline
	// first a model with a cubic spline for the patients_perhesadmx
	mkspline2 pts_hes_rcs = patients_perhesadmx_c, cubic nknots(4) displayknots
	* CHANGED: 2013-05-06 - now use xtgee to handle autocorrelation
	xtgee vperweek $site_vars pts_hes_rcs* $unit_vars $timing_vars ///
		, family(poisson) link(log) force corr(ar 1) eform i(site) t(v_week)
	est store news_`i'_cubic
	adjustrcspline, link(log)
	graph rename news_`i', replace
	predict yhat, mu
	running yhat patients_perhesadmx ///
		, ///
		span(1) repeat(3) ///
		lpattern(longdash) lwidth(medthick) ///
		ytitle("NEWS High Risk patients" "(per week)") ///
		ylabel(0 5 10 15) ///
		yscale(noextend) ///
		xtitle("Ward referrals assessed by ICU" "(per week)") ///
		xlabel(0(10)50) ///
		xscale(noextend) ///
		scatter(msymbol(oh) msize(tiny) mcolor(gs4) jitter(1)) ///
		xsize(6) ysize(6) ///
		title("")
	graph rename news_`i'r, replace
	keep yhat patients_perhesadmx
	gen news_risk = `i'
	if `i' == 1 {
		save ../data/count_news_by_refs, replace
	}
	else {
		append using ../data/count_news_by_refs
		save ../data/count_news_by_refs, replace
	}

}

graph combine news_1 news_2 news_3 ///
	, ///
	rows(1) xsize(6) ysize(2)
if c(os) == "Unix" local gext eps
if c(os) == "MacOSX" local gext pdf
graph rename count_news_by_refs, replace
graph display count_news_by_refs
* graph export ../outputs/figures/count_news_by_refs.`gext' ///
*     , name(count_news_by_refs) replace

use ../data/count_news_by_refs, clear
forvalues i = 1/3 {
	running yhat patients_perhesadmx if news_risk == `i', ///
		span(1) repeat(3) nograph generate(run`i')
	if `i' == 1 local ccolor blue
	if `i' == 2 local ccolor orange
	if `i' == 3 local ccolor red
	local plot (line run`i' patients_perhesadmx if news_risk == `i', sort lcolor(`ccolor') lpattern(longdash) lwidth(medthick))
	local plots `plots' `plot'
}
global plots `plots'


tw $plots ///
	, ///
	ytitle("NEWS High Risk patients" "(per week)") ///
	ylabel(0 5 10 15, nogrid) ///
	yscale(noextend) ///
	xtitle("Ward referrals assessed by ICU" "(per week)") ///
	xlabel(0(10)50) ///
	xscale(noextend) ///
	xsize(6) ysize(6) ///
	title("") ///
	legend( ///
		label( 1 "Low") ///
		label( 2 "Medium") ///
		label( 3 "High") ///
		order(3 2 1) ///
		title("NEWS Risk Class", size(small) pos(11)) ///
		cols(1) ///
		pos(2) ring(0))

if c(os) == "Unix" local gext eps
if c(os) == "MacOSX" local gext pdf
graph rename count_news_by_refs, replace
graph display count_news_by_refs
graph export ../outputs/figures/count_news_by_refs.`gext' ///
    , name(count_news_by_refs) replace
