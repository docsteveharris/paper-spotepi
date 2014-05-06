*  ====================================================
*  = Determinants of severity within and across sites =
*  ====================================================

* NOTE: 2014-03-12 - originally called an_model_ward_severity_tables.do in spot_ward

use ../data/working_postflight.dta, clear
est drop _all
xtset site
save ../data/scratch/scratch.dta, replace
use ../data/scratch/scratch.dta, clear


*  ===============================================
*  = Model variables assembled into single macro =
*  ===============================================
local all_vars ///
	hes_overnight_c ///
	hes_emergx_c ///
	cmp_beds_max_c ///
	teaching_hosp ///
	cmp_throughput ///
	decjanfeb ///
	weekend ///
	out_of_hours ///
	delayed_referral ///
	patients_perhesadmx_c ///
	ib3.ccot_shift_pattern ///
	age_c ///
	male ///
	ib0.sepsis_dx

global model_vars `all_vars'


*  =================================
*  = Macros etc for building table =
*  =================================

tempfile estimates_file
global table_name model_ward_severity
local i = 3
local model_sequence = 1
local table_order = 1


*  ================
*  = ICNARC score =
*  ================
use ../data/scratch/scratch.dta, clear
xtreg icnarc0 $model_vars
est store icnarc0
local model_name = "icnarc0"
parmest, ///
	label list(parm label estimate min* max* p) ///
	escal(rho) ///
	idnum(`i') idstr("`model_name'") ///
	stars(0.05 0.01 0.001) ///
	format(estimate min* max* %9.2f p %9.3f) ///
	saving(`estimates_file', replace)
use `estimates_file', clear
gen table_order = `table_order'
gen model_sequence = 3
local ++table_order
save `estimates_file', replace
save ../outputs/tables/$table_name.dta, replace



*  ==============
*  = NEWS score =
*  ==============
local i = 1
use ../data/scratch/scratch.dta, clear
local model_sequence = 1
xtreg news_score $model_vars
est store news
parmest, ///
	label list(parm label estimate min* max* p) ///
	escal(rho) ///
	idnum(`i') idstr("`model_name'") ///
	stars(0.05 0.01 0.001) ///
	format(estimate min* max* %9.2f p %9.3f) ///
	saving(`estimates_file', replace)
use `estimates_file', clear
gen table_order = _n
gen model_sequence = `model_sequence'
save `estimates_file', replace
use ../outputs/tables/$table_name.dta, clear
append using `estimates_file'
save ../outputs/tables/$table_name.dta, replace
local ++i

*  ==============
*  = SOFA score =
*  ==============
local i = 2
use ../data/scratch/scratch.dta, clear
local model_sequence = 2
xtreg sofa_score $model_vars
est store sofa
parmest, ///
	label list(parm label estimate min* max* p) ///
	escal(rho) ///
	idnum(`i') idstr("`model_name'") ///
	stars(0.05 0.01 0.001) ///
	format(estimate min* max* %9.2f p %9.3f) ///
	saving(`estimates_file', replace)
use `estimates_file', clear
gen table_order = _n
gen model_sequence = `model_sequence'
save `estimates_file', replace
use ../outputs/tables/$table_name.dta, clear
append using `estimates_file'
save ../outputs/tables/$table_name.dta, replace
local ++i

estimates save ../data/estimates/$table_name, replace

*  ===================================
*  = Now produce the tables in latex =
*  ===================================
use ../outputs/tables/$table_name.dta, clear
ren es_1 icc
label var icc "Intra-class correlation coefficient"
expand 2 if parm == "_cons", gen(new_flag)
replace parm = "icc" if new_flag == 1
replace estimate = icc if new_flag
replace stars = "" if new_flag
foreach var in stderr z p min95 max95 {
	replace `var' = . if new_flag == 1
}

// convert to wide
tempfile working 2merge
cap restore, not
preserve
local wide_vars estimate stderr z p stars min95 max95 icc
forvalues i = 1/4 {
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

mt_extract_varname_from_parm
order model_sequence varname var_level

// label the vars
spot_label_table_vars

order tablerowlabel var_level_lab
replace tablerowlabel = "\textbf{Mean severity score}" if parm == "_cons"
replace tablerowlabel = "Intra-class correlation" if parm == "icc"

global table_order ///
	teaching_hosp ///
	hes_overnight ///
	hes_emergx ///
	cmp_beds_max ///
	cmp_throughput ///
	patients_perhesadmx ///
	ccot_shift_pattern ///
	gap_here ///
	decjanfeb ///
	weekend ///
	out_of_hours ///
	gap_here ///
	delayed_referral ///
	gap_here ///
	age ///
	male ///
	sepsis_dx ///
	gap_here ///
	_cons ///
	gap_here ///
	icc

mt_table_order
sort table_order var_level

forvalues i = 1/3 {
	gen est_raw_`i' = estimate_`i'
	sdecode estimate_`i', format(%9.2fc) replace
	* CHANGED: 2014-05-05 - drop the latex formatting
	* replace stars_`i' = "\textsuperscript{" + stars_`i' + "}"
	* replace estimate_`i' = estimate_`i' + stars_`i'
	// replace reference categories
	replace estimate_`i' = "{--}" if parm == "3b.ccot_shift_pattern"
	replace estimate_`i' = "{--}" if parm == "0b.sepsis_dx"
	replace estimate_`i' = "" if est_raw_`i' == .
}

// now replace the estimate with a range for baseline values
* forvalues i = 1/3 {
* 	sdecode min95_`i', format(%9.1fc) replace
* 	sdecode max95_`i', format(%9.1fc) replace
* 	replace estimate_`i' = min95_`i' + "--" + max95_`i' if parm == "_cons"
* }


// indent categorical variables
mt_indent_categorical_vars

* Append units
cap confirm string var unitlabel
if _rc {
    tostring unitlabel, replace
    replace unitlabel = "" if unitlabel == "."
}
replace tablerowlabel = tablerowlabel + "\smaller[1]{ (" + unitlabel + ")}"  ///
	if !missing(unitlabel) & var_type != "Categorical"
replace tablerowlabel = "Ward referrals to ICU\smaller[1]{ (per 1,000 hosp. adm.)}"  ///
	if parm == "patients_perhesadmx_c"

ingap 10 13 22 23

// now send the table to latex
local cols tablerowlabel estimate_1 estimate_2 estimate_3
order `cols'

local super_heading "& \multicolumn{3}{c}{(Change in) mean score} \\"
local h1 "& {NEWS} & {SOFA} & ICNARC \\ "
* CHANGED: 2013-05-14 - decimally aligned column
local zcol "\newcolumntype Z{X[-1m]{S[tight-spacing = true,round-mode=places,round-precision=2]}}"
local justify X[lm]*3{Z}
local tablefontsize "\scriptsize"
local taburowcolors 2{white .. white}

listtab `cols' ///
	using ../outputs/tables/$table_name.tex, ///
	replace  ///
	begin("") delimiter("&") end(`"\\"') ///
	headlines( ///
		"`tablefontsize'" ///
		"\renewcommand{\arraystretch}{`arraystretch'}" ///
		"\taburowcolors `taburowcolors'" ///
		"`zcol'" ///
		"\begin{tabu} spread " ///
		"\textwidth {`justify'}" ///
		"\toprule" ///
		"`super_heading'" ///
		"\cmidrule(r){2-4}" ///
		"`h1'" ///
		"\midrule" ) ///
	footlines( ///
		"\bottomrule" ///
		"\end{tabu}  " ///
		"\label{tab:$table_name} ") 



outsheet using "../outputs/tables/ts_$table_name.csv", ///
     replace comma
