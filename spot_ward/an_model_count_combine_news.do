*  =======================================================
*  = Comparative table of incidence factors by NEWS risk =
*  =======================================================

GenericSetupSteveHarris spot_ward an_model_count_combine_news, logon
global table_name combine_news
set seed 3001

local clean_run 1
if `clean_run' == 1 {
    clear
    use ../data/working.dta
    qui include cr_preflight.do
    save ../data/working_postflight, replace
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

*  ==================
*  = NEWS High Risk =
*  ==================

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
		(firstnm) $site_vars patients_perhesadmx_c ///
		(firstnm) pts_hes_k1 pts_hes_k2 pts_hes_k3 ///
		(median) $unit_vars ///
		(max) $timing_vars ///
		(min) studymonth visit_month ///
		, by(site v_week)
	d 
	xtset site v_week, weekly
	* pause on
	* pause
	* pause of
	// set up gllamm equations
	// CHANGED: 2013-05-05 - allow patients_perhesadmx in as cubic spline
	// first a model with a cubic spline for the patients_perhesadmx
	mkspline pts_hes_rcs = patients_perhesadmx_c, cubic nknots(4) displayknots
	// CHANGED: 2013-05-05 - swap from gllamm to panel models given that the weeks are likely to be correlated
	* cap drop cons
	* gen cons = 1
	* eq ri: cons
	* qui gllamm vperweek $site_vars pts_hes_rcs* $unit_vars $timing_vars ///
	* 	, family(poisson) link(log) i(site) eqs(ri) eform dots nolog
	* noisily gllamm, robust eform
	/*
	NOTE: 2013-05-05 - xtpoisson specification
		- normal option else frailty is gamma distributed
		- vce(bootstrap) to compensate for the overdispersion
	*/
	* xtpoisson vperweek $site_vars pts_hes_rcs* $unit_vars $timing_vars ///
	* 	, normal irr vce(bootstrap)
	* CHANGED: 2013-05-06 - now use xtgee to handle autocorrelation
	xtgee vperweek $site_vars pts_hes_rcs* $unit_vars $timing_vars ///
		, family(poisson) link(log) force corr(ar 1) eform i(site) t(v_week)
	est store news_high_cubic_`i'
	est save ../data/estimates/news_high_cubic, replace
	// save the data for use with estimates again, 'all' saves estimates
	save ../data/count_news_high_cubic, replace all

	// now the linear model for the table
	// NOTE: 2013-05-05 - only include pts_hes_k1 and pts_hes_k3 ... so pts_hes_k2 is reference
	* gllamm vperweek $site_vars $unit_vars $timing_vars ///
	* 	pts_hes_k1 pts_hes_k3 ///
	* 	, family(poisson) link(log) i(site) eqs(ri) eform dots nolog
	* noisily gllamm, robust eform
	* xtpoisson vperweek $site_vars $unit_vars $timing_vars ///
	*  	pts_hes_k1 pts_hes_k3 ///
	* 	, normal irr vce(bootstrap)
	xtgee vperweek $site_vars $unit_vars $timing_vars ///
	 	pts_hes_k1 pts_hes_k3 ///
		, family(poisson) link(log) force corr(ar 1) eform i(site) t(v_week)
	est store news_high_linear_`i'
	est save ../data/estimates/news_high_linear, replace
	// save the data for use with estimates again, 'all' saves estimates
	save ../data/count_news_high_linear, replace all

	parmest, ///
		label list(parm label estimate min* max* p) ///
		eform ///
		idnum(`i') idstr("`model_name'") ///
		stars(0.05 0.01 0.001) ///
		format(estimate min* max* %9.3f p %9.3f) ///
		saving(`estimates_file', replace)

	use `estimates_file', clear
	// Sort out the Cholesky decomposition matrix
	* CHANGED: 2013-05-05 - as needed for gllamm
	* bys idnum (er_1_1): replace er_1_1 = er_1_1[1] if er_1_1 == .
	* replace er_1_1 = er_1_1^2
	* rename er_1_1 var_lvl2

	* gen medianIRR = exp((2 * var_lvl2)^0.5 * invnormal(3/4))
	* gen medianIRR_1 = 1 / medianIRR
	* format var_lvl2 medianIRR medianIRR_1 %9.3f
	* drop if eq == "sit1_1"
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

*  ===================================
*  = Now produce the tables in latex =
*  ===================================
use ../outputs/tables/$table_name.dta, clear
cap drop if eq != "vperweek"
* rename medianIRR_1 medianIRRa
// convert to wide
tempfile working 2merge
cap restore, not
preserve
local wide_vars estimate stderr z p stars min95 max95
forvalues i = 1/3 {
	keep parm model_sequence `wide_vars'
	keep if model_sequence == `i'
	foreach name in `wide_vars' {
		rename `name' `name'_`i'
	}
	save `2merge', replace
	if `i' == 1 {
		save `working', replace
	}
	else {
		use `working', clear
		merge 1:1 parm using `2merge'
		drop _merge
		save `working', replace
	}
	restore
	preserve

}
restore, not

use `working', clear
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


forvalues i = 1/3 {
	gen est_raw_`i' = estimate_`i'
	sdecode estimate_`i', format(%9.3fc) replace
	replace stars_`i' = "\textsuperscript{" + stars_`i' + "}"
	replace estimate_`i' = estimate_`i' + stars_`i'
	// replace reference categories
	replace estimate_`i' = "" if est_raw_`i' == .
	replace estimate_`i' = "--" if varname == "ccot_shift_pattern" & var_level == 3
	replace estimate_`i' = "--" if varname == "patients_perhesadmx" & var_level == 2
	replace var_type = "Categorical" if varname == "ccot_shift_pattern"
	replace var_type = "Categorical" if varname == "patients_perhesadmx"
}

// indent categorical variables
mt_indent_categorical_vars

ingap 13 15

// now replace the estimate with a range for baseline values
forvalues i = 1/3 {
	sdecode min95_`i', format(%9.2fc) replace
	sdecode max95_`i', format(%9.2fc) replace
	replace estimate_`i' = min95_`i' + "--" + max95_`i' if parm == "_cons"
}
replace tablerowlabel = "Baseline Incidence Rate (95\% CI)" if parm == "_cons"
replace tablerowlabel = "No critical care beds" if parm == "beds_none_week"

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


// now prepare footers with site level variability
* forvalues i = 1/3 {
* qui su var_lvl2, meanonly
* local v2: di %9.2fc `=r(mean)'
* qui su medianIRR, meanonly
* local irr: di %9.2fc `=r(mean)'
* }
* local f1 "Site level variance & `v2_1' & `v2_2' & `v2_3'  \\"
* local f2 "Median Incidence rate ratio & `irr_1' & `irr_2' & `irr_3'  \\"
* di "`f1'"
* di "`f2'"

// now send the table to latex
local cols tablerowlabel estimate_1 estimate_2 estimate_3
order `cols'

local super_heading "& \multicolumn{3}{c}{NEWS Risk Class} \\"
local h1 "& Low & Medium & High \\ "
local justify X[5l]X[l]X[l]X[l]
local tablefontsize "\scriptsize"
local taburowcolors 2{white .. white}
local arraystretch 1.2

listtab `cols' ///
	using ../outputs/tables/$table_name.tex, ///
	replace  ///
	begin("") delimiter("&") end(`"\\"') ///
	headlines( ///
		"`tablefontsize'" ///
		"\renewcommand{\arraystretch}{`arraystretch'}" ///
		"\taburowcolors `taburowcolors'" ///
		"\begin{tabu} to " ///
		"\textwidth {`justify'}" ///
		"\toprule" ///
		"`super_heading'" ///
		"\cmidrule(r){2-4}" ///
		"`h1'" ///
		"\midrule" ) ///
	footlines( ///
		"\bottomrule" ///
		"\end{tabu} " ///
		"\label{tab:$table_name} " ///
		"\normalfont" ///
		"\normalsize")

