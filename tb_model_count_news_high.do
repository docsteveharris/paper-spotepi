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




*  ============================
*  = Incidence NEWS RISK HIGH =
*  ============================

* CHANGED: 2014-02-26 - changed project reference
GenericSetupSteveHarris mas_spotepi tb_model_count_news_high, logon
global table_name incidence_news_high
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

* Keep just NEWS High Risk
local i 3
local model_name = "NEWS risk `i'"
tab news_risk
keep if news_risk == 3
tab news_risk

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
* Generate a counter variable
cap drop new_patients
gen new_patients = 1
label var new_patients "New patients (per day)"

* Collapse over site days
* CHANGED: 2014-03-24 - add in ccot_shift_pattern so can re-run model with 
* different baseline
collapse ///
	(count) vperday = new_patients ///
	(firstnm) $site_vars ccot_shift_pattern patients_perhesadmx_c ///
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
local model_name = "NEWS risk `i'"

// CHANGED: 2013-05-05 - allow patients_perhesadmx in as cubic spline
// first a model with a cubic spline for the patients_perhesadmx
mkspline2 pts_hes_rcs = patients_perhesadmx_c, cubic nknots(4) displayknots
* CHANGED: 2013-05-06 - now use xtgee to handle autocorrelation
xtgee vperday $site_vars pts_hes_rcs* $unit_vars $timing_vars ///
	, family(poisson) link(log) force corr(ar 1) eform i(site) t(odate)
est store news_high_cubic
est save ../data/estimates/news_high_cubic, replace
// save the data for use with estimates again, 'all' saves estimates
save ../data/count_news_high_cubic, replace all

// now the linear model for the table
xtgee vperday $site_vars $unit_vars $timing_vars ///
 	pts_hes_k1 pts_hes_k3 ///
	, family(poisson) link(log) force corr(ar 1) eform i(site) t(odate)
est store news_high_linear
est save ../data/estimates/news_high_linear, replace
// save the data for use with estimates again, 'all' saves estimates
save ../data/count_news_high_linear, replace all

* CHANGED: 2014-03-19 - work out IRR for a week and a month
lincom _cons, irr
di "per week: " + 7 * r(estimate)
di "L95CI: "  + 7 * (r(estimate) - 1.96 * r(se))
di "U95CI: "  + 7 * (r(estimate) + 1.96 * r(se))
* Per month
di "per month: " + 365/12 * r(estimate)
di "L95CI: "  + 365/12 * (r(estimate) - 1.96 * r(se))
di "U95CI: "  + 365/12 * (r(estimate) + 1.96 * r(se))

* NOTE: 2014-03-24 - run model with factor variable notation
* Now use this to calculate the effect of 24/7 outreach on IRR cf 7 days
preserve
xtgee vperday ///
	teaching_hosp ///
	hes_overnight_c ///
	hes_emergx_c ///
	ib3.ccot_shift_pattern ///
	$unit_vars $timing_vars ///
 	pts_hes_k1 pts_hes_k3 ///
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
save ../outputs/tables/$table_name.dta, replace
local ++model_sequence

*  ===================================
*  = Now produce the tables in latex =
*  ===================================
use ../outputs/tables/$table_name.dta, clear
cap drop if eq != "vperday"
* rename medianIRR_1 medianIRRa
// convert to wide
tempfile working 2merge
qui include mt_Programs.do

// convert back patients_perhesadmx
replace parm = "1.patients_perhesadmx" if parm == "pts_hes_k1"
replace parm = "3.patients_perhesadmx" if parm == "pts_hes_k3"
// convert back to stata factor notation
replace parm = "0.ccot_shift_pattern" if parm == "ccot_p_1"
replace parm = "1.ccot_shift_pattern" if parm == "ccot_p_2"
replace parm = "2.ccot_shift_pattern" if parm == "ccot_p_3"
mt_extract_varname_from_parm
order model_sequence varname var_level
bys varname: ingap if varname == "ccot_shift_pattern"
replace var_level = 3 if varname == "ccot_shift_pattern" & var_level == .

bys varname: ingap if varname == "patients_perhesadmx"
replace var_level = 2 if varname == "patients_perhesadmx" & var_level == .

// label the vars
spot_label_table_vars

order tablerowlabel var_level_lab
// add in blank line as ref category for ccot_shift_pattern

global table_order ///
	teaching_hosp ///
	hes_overnight ///
	hes_emergx ///
	cmp_beds_max ///
	cmp_throughput ///
	ccot_shift_pattern ///
	patients_perhesadmx ///
	decjanfeb ///
	beds_none_l1 ///
	_cons ///

mt_table_order
sort table_order var_level

gen est_raw = estimate
sdecode estimate, format(%9.3fc) replace
* replace stars = "\textsuperscript{" + stars + "}"
* replace estimate = estimate + stars
// replace reference categories
replace estimate = "" if est_raw == .
replace estimate = "--" if varname == "ccot_shift_pattern" & var_level == 3
replace estimate = "--" if varname == "patients_perhesadmx" & var_level == 2
replace var_type = "Categorical" if varname == "ccot_shift_pattern"
replace var_type = "Categorical" if varname == "patients_perhesadmx"

// indent categorical variables
mt_indent_categorical_vars

ingap 13 15

// now replace the estimate with a range for baseline values
sdecode p, format(%9.3fc) replace
replace p = "<0.001" if p == "0.000"
sdecode min95, format(%9.3fc) replace
sdecode max95, format(%9.3fc) replace
gen est_ci95 = "(" + min95 + "--" + max95 + ")" if !missing(min95, max95)
replace tablerowlabel = "Baseline Incidence Rate" if parm == "_cons"
replace tablerowlabel = "ICU fully occupied prev. day" if parm == "beds_none_l1"

* Append units
cap confirm string var unitlabel
if _rc {
    tostring unitlabel, replace
    replace unitlabel = "" if unitlabel == "."
}
replace tablerowlabel = tablerowlabel + "\smaller[1]{ (" + unitlabel + ")}"  ///
	if !missing(unitlabel) & var_type != "Categorical"
replace tablerowlabel = tablerowlabel + "\smaller[1]{ (per 1,000 hosp. adm.)}"  ///
	if tablerowlabel == "Ward referrals to ICU"

* now write the table to latex
local cols tablerowlabel estimate est_ci95 p
order `cols'

local h1 "Parameter & IRR & (95\% CI) & p \\ "
local justify X[6l] X[1l] X[2l] X[1r]
local tablefontsize "\scriptsize"
local arraystretch 1.2
local taburowcolors 2{white .. white}


listtab `cols' ///
	using ../outputs/tables/$table_name.tex, ///
	replace rstyle(tabular) ///
	headlines( ///
		"`tablefontsize'" ///
		"\renewcommand{\arraystretch}{`arraystretch'}" ///
		"\taburowcolors `taburowcolors'" ///
		"\begin{tabu} to " ///
		"\textwidth {`justify'}" ///
		"\toprule" ///
		"`h1'" ///
		"\midrule" ) ///
	footlines( ///
		"\bottomrule" ///
		"\end{tabu} " ///
		"\label{tab:$table_name} " ///
		"\normalfont" ///
		"\normalsize")

outsheet using "../outputs/tables/tb_$table_name.csv", ///
     replace comma

*  ======================================================
*  = Now draw the predicted values for the cubic spline =
*  ======================================================

* NOTE: 2014-03-13 - change scale to to per day vs per week

use patients_perhesadmx using ../data/working_postflight, clear
set scheme shbw
su patients_perhesadmx
local patients_perhesadmx_mean = r(mean)
use ../data/count_news_high_cubic, clear
gen patients_perhesadmx = patients_perhesadmx_c + `patients_perhesadmx_mean'
est use ../data/estimates/news_high_cubic
est restore news_high_cubic
est replay, eform
* Graph using adjustrcspline ...
adjustrcspline, link(log)

* CHANGED: 2014-03-13 - scale prediction to per month (mean is per day)
* prediction assuming RE is 0
predict yhat, mu
replace yhat = yhat * 365.25 / 12

running yhat patients_perhesadmx ///
	, ///
	span(1) repeat(3) ///
	lpattern(longdash) lwidth(medthick) ///
	ytitle("NEWS High Risk patients" "(per month)") ///
	ylabel(0(10)50) ///
	yscale(noextend) ///
	xtitle("Ward referrals assessed by ICU" "(per month)") ///
	xlabel(0(10)50) ///
	xscale(noextend) ///
	scatter(msymbol(p) msize(vtiny) mcolor(gs4) jitter(2)) ///
	xsize(6) ysize(6) ///
	title("")

if c(os) == "Unix" local gext eps
if c(os) == "MacOSX" local gext pdf
graph rename count_news_high_rcs, replace
graph display count_news_high_rcs
graph export ../outputs/figures/count_news_high_rcs.`gext' ///
    , name(count_news_high_rcs) replace
