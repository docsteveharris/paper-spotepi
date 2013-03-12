*  =================================================================
*  = Combine NEWS high risk, severe sepsis and septic shock tables =
*  =================================================================

/*


NOTE: 2013-02-04 - do not include study factors
in the principal model ... use for sensitivity
- Study factors
	- match quality that month
	- match quality overall for the site
	- study month

- timing
	- beds_none
		: enter this uncentered and then scale so 1 unit = 10%
	- out_of_hours
	- weekend

- Site factors
	- patients_perhesadmx_c
	- ccot_shift_pattern
	- hes_overnight_c
	- hes_emergx_c
	- cmp_beds_max_c

- patient factors: cannot include

*/
local clean_run 1
if `clean_run' == 1 {
    clear
    use ../data/working.dta
    include cr_preflight.do
}
use ../data/working_occupancy, clear
keep icode icnno odate beds_none
gen v_week = wofd(odate) 
collapse (mean) beds_none_week = beds_none, by(icode v_week)
// convert mean beds_none (occupancy) to a 10% change from 0 so can be interpreted
replace beds_none_week = 10 * beds_none_week
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
save ../data/scratch/scratch.dta, replace
use ../data/scratch/scratch.dta, clear

*  ===============================================
*  = Model variables assembled into single macro =
*  ===============================================

global site_vars ///
	hes_overnight_c ///
	hes_emergx_c ///
	cmp_beds_max_c ///
	ccot_p_1 ///
	ccot_p_2 ///
	ccot_p_3 ///
	patients_perhesadmx_c ///
	decjanfeb ///
	beds_none_week

global model_vars $site_vars 

*  =================================
*  = Macros etc for building table =
*  =================================
tempfile estimates_file
global table_name count_combine
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
use ../data/scratch/scratch.dta, clear
keep if news_risk == 3
cap drop new_patients
gen new_patients = 1
label var new_patients "New patients (per week)"
collapse ///
	(count) vperweek = new_patients ///
	(firstnm) $site_vars ///
	(min) studymonth visit_month ///
	, by(site v_week)
cap drop cons
gen cons = 1
eq ri: cons
// set up gllamm equations
qui gllamm vperweek $model_vars ///
	, family(poisson) link(log) i(site) eqs(ri) eform dots nolog
noisily gllamm, robust eform
est store news_high
local model_name = "news_high"
parmest, ///
	label list(parm label estimate min* max* p) ///
	erows(chol) ///
	eform ///
	idnum(`i') idstr("`model_name'") ///
	stars(0.05 0.01 0.001) ///
	format(estimate min* max* %9.2f p %9.3f) ///
	saving(`estimates_file', replace)
use `estimates_file', clear
// Sort out the Cholesky decomposition matrix
bys idnum (er_1_1): replace er_1_1 = er_1_1[1] if er_1_1 == .
replace er_1_1 = er_1_1^2
rename er_1_1 var_lvl2
gen medianIRR = exp((2 * var_lvl2)^0.5 * invnormal(3/4))
gen medianIRR_1 = 1 / medianIRR
format var_lvl2 medianIRR medianIRR_1 %9.3f
drop if eq == "sit1_1"
gen table_order = `table_order'
gen model_sequence = `model_sequence'
local ++table_order
save `estimates_file', replace
save ../outputs/tables/$table_name.dta, replace
local ++i

*  =================
*  = Severe sepsis =
*  =================
local ++model_sequence
local model_name = "severe_sepsis"

use ../data/scratch/scratch.dta, clear
keep if sepsis2001 == 3
cap drop new_patients
gen new_patients = 1
label var new_patients "New patients (per week)"
collapse ///
	(count) vperweek = new_patients ///
	(firstnm) $site_vars ///
	(min) studymonth visit_month ///
	, by(site v_week)
cap drop cons
gen cons = 1
eq ri: cons
// set up gllamm equations
qui gllamm vperweek $model_vars ///
	, family(poisson) link(log) i(site) eqs(ri) eform dots nolog
noisily gllamm, robust eform
est store `model_name'
parmest, ///
	label list(parm label estimate min* max* p) ///
	erows(chol) ///
	eform ///
	idnum(`i') idstr("`model_name'") ///
	stars(0.05 0.01 0.001) ///
	format(estimate min* max* %9.2f p %9.3f) ///
	saving(`estimates_file', replace)
use `estimates_file', clear
// Sort out the Cholesky decomposition matrix
bys idnum (er_1_1): replace er_1_1 = er_1_1[1] if er_1_1 == .
replace er_1_1 = er_1_1^2
rename er_1_1 var_lvl2
gen medianIRR = exp((2 * var_lvl2)^0.5 * invnormal(3/4))
gen medianIRR_1 = 1 / medianIRR
format var_lvl2 medianIRR medianIRR_1 %9.3f
drop if eq == "sit1_1"
gen table_order = `table_order'
gen model_sequence = `model_sequence'
local ++table_order
save `estimates_file', replace
use ../outputs/tables/$table_name.dta, clear
append using `estimates_file'
save ../outputs/tables/$table_name.dta, replace
local ++i

*  ================
*  = Septic shock =
*  ================
local ++model_sequence
local model_name = "septic_shock"

use ../data/scratch/scratch.dta, clear
keep if  inlist(sepsis2001,4,5,6)
cap drop new_patients
gen new_patients = 1
label var new_patients "New patients (per week)"
collapse ///
	(count) vperweek = new_patients ///
	(firstnm) $site_vars ///
	(min) studymonth visit_month ///
	, by(site v_week)
cap drop cons
gen cons = 1
eq ri: cons
// set up gllamm equations
qui gllamm vperweek $model_vars ///
	, family(poisson) link(log) i(site) eqs(ri) eform dots nolog
noisily gllamm, robust eform
est store `model_name'
parmest, ///
	label list(parm label estimate min* max* p) ///
	erows(chol) ///
	eform ///
	idnum(`i') idstr("`model_name'") ///
	stars(0.05 0.01 0.001) ///
	format(estimate min* max* %9.2f p %9.3f) ///
	saving(`estimates_file', replace)
use `estimates_file', clear
// Sort out the Cholesky decomposition matrix
bys idnum (er_1_1): replace er_1_1 = er_1_1[1] if er_1_1 == .
replace er_1_1 = er_1_1^2
rename er_1_1 var_lvl2
gen medianIRR = exp((2 * var_lvl2)^0.5 * invnormal(3/4))
gen medianIRR_1 = 1 / medianIRR
format var_lvl2 medianIRR medianIRR_1 %9.3f
drop if eq == "sit1_1"
gen table_order = `table_order'
gen model_sequence = `model_sequence'
local ++table_order
save `estimates_file', replace
use ../outputs/tables/$table_name.dta, clear
append using `estimates_file'
save ../outputs/tables/$table_name.dta, replace
local ++i

est save ../data/estimates/count_combine, replace

*  ===================================
*  = Now produce the tables in latex =
*  ===================================
use ../outputs/tables/$table_name.dta, clear
rename medianIRR_1 medianIRRa
// convert to wide
tempfile working 2merge
cap restore, not
preserve
local wide_vars estimate stderr z p stars min95 max95 var_lvl2 medianIRR medianIRRa
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

// convert back to stata factor notation
replace parm = "0.ccot_shift_pattern" if parm == "ccot_p_1"
replace parm = "1.ccot_shift_pattern" if parm == "ccot_p_2"
replace parm = "2.ccot_shift_pattern" if parm == "ccot_p_3"
mt_extract_varname_from_parm
order model_sequence varname var_level
bys varname: ingap if varname == "ccot_shift_pattern"
replace var_level = 3 if varname == "ccot_shift_pattern" & var_level == .

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
}

// indent categorical variables
mt_indent_categorical_vars

ingap 12

// now replace the estimate with a range for baseline values
forvalues i = 1/3 {
	sdecode min95_`i', format(%9.2fc) replace
	sdecode max95_`i', format(%9.2fc) replace
	replace estimate_`i' = min95_`i' + "--" + max95_`i' if parm == "_cons"
}
replace tablerowlabel = "Baseline Incidence Rate (95\% CI)" if parm == "_cons"
replace tablerowlabel = "No critical care beds" if parm == "beds_none_week"


// now prepare footers with site level variability
forvalues i = 1/3 {
	qui su var_lvl2_`i', meanonly
	local v2_`i': di %9.2fc `=r(mean)'
	qui su medianIRR_`i', meanonly
	local irr_`i': di %9.2fc `=r(mean)'
}
local f1 "Site level variance & `v2_1' & `v2_2' & `v2_3'  \\"
local f2 "Median Incidence rate ratio & `irr_1' & `irr_2' & `irr_3'  \\"
di "`f1'"
di "`f2'"

// now send the table to latex
local cols tablerowlabel estimate_1 estimate_2 estimate_3
order `cols'

local super_heading "& \multicolumn{3}{c}{Incidence rate ratios} \\"
local h1 "& NEWS High Risk & Severe sepsis & Septic shock \\ "
local justify X[3l]X[l]X[l]X[l]
local tablefontsize "\footnotesize"
local taburowcolors 2{white .. white}

listtab `cols' ///
	using ../outputs/tables/$table_name.tex, ///
	replace  ///
	begin("") delimiter("&") end(`"\\"') ///
	headlines( ///
		"`tablefontsize'" ///
		"\renewcommand{\arraystretch}{`arraystretch'}" ///
		"\taburowcolors `taburowcolors'" ///
		"\begin{tabu}  {`justify'}" ///
		"\toprule" ///
		"`super_heading'" ///
		"\cmidrule(r){2-4}" ///
		"`h1'" ///
		"\midrule" ) ///
	footlines( ///
		"\midrule" ///
		"`f1'" ///
		"`f2'" ///	
		"\bottomrule" ///
		"\end{tabu}  " ///
		"\label{tab: $table_name} ") 

