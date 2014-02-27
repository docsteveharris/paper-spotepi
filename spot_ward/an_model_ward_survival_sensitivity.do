GenericSetupSteveHarris spot_ward an_model_ward_survival_sens, logon

*  =================================================================
*  = Produce table comparing survival model across match qualities =
*  =================================================================

/*
Created 130517
Modifed 130515

Change log


*/


*  ===================
*  = Model variables =
*  ===================
local patient_vars ///
	age_c ///
	male ///
	ib0.sepsis_dx ///
	delayed_referral ///
	ib1.v_ccmds

// NOTE: 2013-03-13 - enter icnarc0 separtely
// icnarc0_c ///

local timing_vars ///
	out_of_hours ///
	weekend ///
	decjanfeb

local site_vars ///
		hes_overnight_c ///
		hes_emergx_c ///
		cmp_beds_max_c ///
		patients_perhesadmx_c ///
		ib3.ccot_shift_pattern ///

*  ===============================================
*  = Model variables assembled into single macro =
*  ===============================================
global all_vars ///
	`site_vars' ///
	`timing_vars' ///
	`patient_vars' 
	
global table_name ward_survival_sensitivity

use ../data/working_sensitivity.dta, clear
su site_quality_by_month
// original analysis
gen bysens0 = sens_months == 1
// all sites
gen bysens1 = site_quality_by_month >= 70 
// best sites
gen bysens2 = site_quality_by_month >= 95 & sens_months == 1
tab bysens0
tab bysens1
tab bysens2

foreach i in 1 0 2 {
	count if bysens`i' == 1
	local n: di %9.0fc `=r(N)'
	local n = trim("`n'")
	local patients `patients' & `n' 
	qui duplicates report icode if bysens`i' == 1
	local n: di %9.0fc `=r(unique_value)'
	local n = trim("`n'")
	local sites `sites' & `n' 
	qui duplicates report icode studymonth if bysens`i' == 1
	local n: di %9.0fc `=r(unique_value)'
	local n = trim("`n'")
	local months `months' & `n' 
}
global patients  Patients `patients' \\
di "$patients"
global sites  Sites `sites' \\
di "$sites"
global months  Study Months `months' \\
di "$months"

do cr_preflight.do
do cr_survival.do

// NOTE: 2013-01-29 - cr_survival.do stsets @ 28 days by default
stset dt1, id(id) failure(dead_st) exit(time dt0+90) origin(time dt0)
stsplit tb, at(1 4 28)
label var tb "Analysis time blocks"

save ../data/scratch/scratch.dta, replace




local clean_run 1
if `clean_run' == 1 {
	use ../data/scratch/scratch.dta, clear
	keep if bysens0
	stcox $all_vars icnarc0_c i.tb#c.icnarc0_c  ///
		, shared(site) ///
		nolog
	local i 1
	local model_name all_sites
	est store sens1
	tempfile estimates_file
	parmest, ///
		eform ///
		label list(parm label estimate min* max* p) ///
		escal(theta se_theta theta_chi2) ///
		idnum(`i') idstr("`model_name'") ///
		stars(0.05 0.01 0.001) ///
		format(estimate min* max* %9.2f p %9.3f) ///
		saving(`estimates_file', replace)
	use `estimates_file', clear
	gen table_order = _n
	save ../outputs/tables/$table_name.dta, replace
	local ++i

	forvalues j = 1/2 {
		use ../data/scratch/scratch.dta, clear
		keep if bysens`j'
		stcox $all_vars icnarc0_c i.tb#c.icnarc0_c  ///
			, shared(site) ///
			nolog
		if `j' == 1 local model_name study_sites
		if `j' == 2 local model_name best_sites
		est store sens`j'
		est save ../data/estimates/survival_sens`j', replace
		tempfile estimates_file
		parmest, ///
			eform ///
			label list(parm label estimate min* max* p) ///
			escal(theta se_theta theta_chi2) ///
			idnum(`i') idstr("`model_name'") ///
			stars(0.05 0.01 0.001) ///
			format(estimate min* max* %9.2f p %9.3f) ///
			saving(`estimates_file', replace)
		use `estimates_file', clear
		gen table_order = _n
		save `estimates_file', replace
		use ../outputs/tables/$table_name.dta, clear
		append using `estimates_file'
		save ../outputs/tables/$table_name.dta, replace
		local ++i
	}


}


*  ======================
*  = Now produce tables =
*  ======================

use ../outputs/tables/ward_survival_sensitivity, clear
d, full
ren es_1 theta_est
ren es_2 theta_se
ren es_3 theta_chi2
tab theta_est
cap drop model_sequence
gen model_sequence = .
replace model_sequence = idnum


// convert to wide
tempfile working 2merge
cap restore, not
preserve
local wide_vars estimate stderr z p stars min95 max95 theta_est theta_se theta_chi2
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
mt_extract_varname_from_parm
order model_sequence varname var_level

// hand label the time-varying interaction
replace var_level = "0" if strpos(var_level, "0")
replace var_level = "1" if strpos(var_level, "1")
replace var_level = "4" if strpos(var_level, "4")
replace var_level = "28" if strpos(var_level, "28")
destring var_level, replace
replace varname = "icnarc0_timev" if strpos(varname, "tb#c")
// label the vars
spot_label_table_vars
replace tablerowlabel = "\textit{--- with modifier of Day 0 effect}" if varname == "icnarc0_timev"

// replace var_level_lab = "Days 0 effect"  if varname == "icnarc0_timev" & var_level == 0
replace var_level_lab = "Days 1--2"  if varname == "icnarc0_timev" & var_level == 1
replace var_level_lab = "Days 4--28"  if varname == "icnarc0_timev" & var_level == 4
replace var_level_lab = "Days 28+" if varname == "icnarc0_timev" & var_level == 28

order tablerowlabel var_level_lab
// add in blank line as ref category for ccot_shift_pattern

global table_order ///
	hes_overnight ///
	hes_emergx ///
	cmp_beds_max ///
	patients_perhesadmx ///
	ccot_shift_pattern ///
	gap_here ///
	out_of_hours ///
	weekend ///
	decjanfeb ///
	gap_here ///
	age ///
	male ///
	sepsis_dx ///
	delayed_referral ///
	v_ccmds ///
	icnarc0 ///
	icnarc0_timev ///
	theta_est

mt_table_order
sort table_order var_level

forvalues i = 1/3 {
	gen est_raw_`i' = estimate_`i'
	sdecode estimate_`i', format(%9.2fc) replace
	replace stars_`i' = "\textsuperscript{" + stars_`i' + "}"
	replace estimate_`i' = estimate_`i' + stars_`i'
	// replace reference categories
	replace estimate_`i' = "" if est_raw_`i' == .
	replace estimate_`i' = "--" if varname == "ccot_shift_pattern" & var_level == 3
	replace estimate_`i' = "--" if varname == "sepsis_dx" & var_level == 0
	replace estimate_`i' = "--" if varname == "v_ccmds" & var_level == 1
	replace estimate_`i' = "" if varname == "icnarc0_timev" & var_level == 0
}

// indent categorical variables
mt_indent_categorical_vars

// Other headings
ingap 1 10 13 27
replace tablerowlabel = "\textit{Site parameters}" if _n == 1
replace tablerowlabel = "\textit{Timing parameters}" if _n == 11
replace tablerowlabel = "\textit{Patient parameters}" if _n == 15
ingap 11 15

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

*  =====================
*  = Comparative table =
*  =====================
// now prepare footers with site level variability
forvalues i = 1/3 {
	qui su theta_est_`i', meanonly
	local f = r(mean)
	qui su theta_se_`i', meanonly
	local se = r(mean)
	if `f'/`se' > invnorm(0.95) local theta_stars = "*"
	if `f'/`se' > invnorm(0.975) local theta_stars = "**"
	if `f'/`se' > invnorm(0.9995) local theta_stars = "***"
	local frailty: di %9.3fc `f'
	local frailty "`frailty'\textsuperscript{`theta_stars'}"
	local frailty = subinstr("`frailty'", " ", "",.)
	local frailties `frailties' & `frailty'
	di "`frailties'"
	
}
local f1 "Frailty `frailties'  \\"
di "`f1'"


local cols tablerowlabel estimate_1 estimate_2 estimate_3
order `cols'

global table_name ward_survival_sensitivity
local super_heading "& \multicolumn{3}{c}{Hazard ratio} \\"
local h1 "Data set & All  & Study  & Best  \\ "
local justify llll
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
		"\begin{tabu} spread " ///
		"\textwidth {`justify'}" ///
		"\toprule" ///
		"`super_heading'" ///
		"\cmidrule(r){2-4}" ///
		"`h1'" ///
		"\midrule" ) ///
	footlines( ///
		"\midrule" ///
		"`f1'" ///
		"\midrule" ///
		"$patients" ///
		"$months" ///
		"$sites" ///
		"\bottomrule" ///
		"\end{tabu}  " ///
		"\label{tab:$table_name} ")

cap log off






