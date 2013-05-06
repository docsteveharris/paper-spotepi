*  ==============================
*  = Incidence of Severe sepsis =
*  ==============================

GenericSetupSteveHarris spot_ward an_model_count_severe_sepsis, logon
global table_name incidence_severe_sepsis
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

*  =================
*  = Severe sepsis =
*  =================

// local i is a relic from the NEWS version of the code
local i = 1
local model_name = "Severe Sepsis"
use ../data/scratch/scratch.dta, clear
tab sepsis_severity
keep if inlist(sepsis_severity,3,4)
tab sepsis_severity
cap drop new_patients
gen new_patients = 1
label var new_patients "New patients (per week)"
collapse ///
	(count) vperweek = new_patients ///
	(firstnm) $site_vars patients_perhesadmx_c ///
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
est store severe_sepsis_cubic
est save ../data/estimates/severe_sepsis_cubic, replace
// save the data for use with estimates again, 'all' saves estimates
save ../data/count_severe_sepsis_cubic, replace all

// now the linear model for the table
xtgee vperweek $site_vars $unit_vars $timing_vars ///
 	pts_hes_k1 pts_hes_k3 ///
	, family(poisson) link(log) force corr(ar 1) eform i(site) t(v_week)
est store severe_sepsis_linear
est save ../data/estimates/severe_sepsis_linear, replace
// save the data for use with estimates again, 'all' saves estimates
save ../data/count_severe_sepsis_linear, replace all

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
cap drop if eq != "vperweek"
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
	hes_overnight ///
	hes_emergx ///
	cmp_beds_max ///
	ccot_shift_pattern ///
	patients_perhesadmx ///
	decjanfeb ///
	beds_none_week ///
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
replace tablerowlabel = "ICU fully occupied \smaller[1]{( \% of week)}" if parm == "beds_none_week"

* Append units
cap confirm string var unitlabel
if _rc {
    tostring unitlabel, replace
    replace unitlabel = "" if unitlabel == "."
}
replace tablerowlabel = tablerowlabel + "\smaller[1]{ (" + unitlabel + ")}"  ///
	if !missing(unitlabel) & var_type != "Categorical"
replace tablerowlabel = tablerowlabel + "\smaller[1]{ (per 1,000 hospital admissions)}"  ///
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


*  ======================================================
*  = Now draw the predicted values for the cubic spline =
*  ======================================================
use patients_perhesadmx using ../data/working_postflight, clear
qui su patients_perhesadmx
local patients_perhesadmx_mean = r(mean)
use ../data/count_severe_sepsis_cubic, clear
gen patients_perhesadmx = patients_perhesadmx_c + `patients_perhesadmx_mean'
est use ../data/estimates/severe_sepsis_cubic
est restore severe_sepsis_cubic
est replay, eform
* Graph using adjustrcspline ...
adjustrcspline, link(log)
* prediction assuming RE is 0
predict yhat, mu
running yhat patients_perhesadmx ///
	, ///
	span(1) repeat(3) ///
	lpattern(longdash) lwidth(medthick) ///
	ytitle("Patients with severe sepsis" "(per week)") ///
	ylabel(0 5 10 15) ///
	yscale(noextend) ///
	xtitle("Ward referrals assessed by ICU" "(per week)") ///
	xlabel(0(10)50) ///
	xscale(noextend) ///
	scatter(msymbol(oh) msize(tiny) mcolor(gs4) jitter(1)) ///
	xsize(6) ysize(6) ///
	title("")

if c(os) == "Unix" local gext eps
if c(os) == "MaxOSX" local gext pdf
graph rename count_severe_sepsis_rcs, replace
graph display count_severe_sepsis_rcs
graph export ../outputs/figures/count_severe_sepsis_rcs.`gext' ///
    , name(count_severe_sepsis_rcs) replace
