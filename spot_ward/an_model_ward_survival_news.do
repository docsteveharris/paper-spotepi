GenericSetupSteveHarris mas_spotepi an_model_ward_survival_final, logon

*  =======================================================================
*  = Produce a table showing coefficients from final ward survival model =
*  =======================================================================

/*
Created 
Modifed 130515

Change log
CHANGED: 2013-05-15 - work with 90 day survival, and add time-varying effect for severity at 28d
CHANGED: 2013-07-17 - file duplicated and adjustment with NEWS instead of ICNARC
	- see an_model_ward_survival_news.do


Consider the following models
- individual univariate hazard ratio estimates
- full model - ignoring frailty
- full model accounting for frailty
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

// NOTE: 2013-03-13 - enter news_score separtely
// news_score_c ///

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
	`patient_vars' ///


local clean_run 1
if `clean_run' == 1 {
    clear
    use ../data/working.dta
    qui include cr_preflight.do
    save ../data/working_postflight, replace
    qui include cr_survival.do
    save ../data/working_survival, replace
}

global table_name ward_survival_news

use ../data/working_survival.dta, clear
// NOTE: 2013-01-29 - cr_survival.do stsets @ 28 days by default
stset dt1, id(id) failure(dead_st) exit(time dt0+90) origin(time dt0)

local i 1
// =====================================
// = Run full model - ignoring frailty =
// =====================================
stcox $all_vars news_score_c, nolog
local model_name full no_frailty
est store full1
est save ../data/estimates/survival_full1, replace
tempfile estimates_file
parmest, ///
	eform ///
	label list(parm label estimate min* max* p) ///
	idnum(`i') idstr("`model_name'") ///
	stars(0.05 0.01 0.001) ///
	format(estimate min* max* %9.2f p %9.3f) ///
	saving(`estimates_file', replace)
use `estimates_file', clear
gen table_order = _n
save ../outputs/tables/$table_name.dta, replace
local ++i

// ===============================================
// = Run model with time-dependence for severity =
// ===============================================
use ../data/working_survival.dta, clear
stset dt1, id(id) failure(dead_st) exit(time dt0+90) origin(time dt0)
stsplit tb, at(1 4 28)
label var tb "Analysis time blocks"
stcox $all_vars news_score_c i.tb#c.news_score_c, nolog
local model_name full time_dependent
est store full2
est save ../data/estimates/survival_full2, replace
tempfile estimates_file
parmest, ///
	eform ///
	label list(parm label estimate min* max* p) ///
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

// ===============================
// = Run full model with frailty =
// ===============================
use ../data/working_survival.dta, clear
stset dt1, id(id) failure(dead_st) exit(time dt0+90) origin(time dt0)
stsplit tb, at(1 4 28)
label var tb "Analysis time blocks"
stcox $all_vars news_score_c i.tb#c.news_score_c ///
	, shared(site) ///
	nolog
local model_name full_frailty
est store full3
est save ../data/estimates/survival_full3, replace
estimates save ../data/survival_final, replace
tempfile estimates_file
parmest, ///
	eform ///
	label list(parm label estimate min* max* p) ///
	idnum(`i') idstr("`model_name'") ///
	stars(0.05 0.01 0.001) ///
	escal(theta se_theta theta_chi2) ///
	format(estimate min* max* %9.2f p %9.3f) ///
	saving(`estimates_file', replace)
use `estimates_file', clear
gen table_order = _n
save `estimates_file', replace
use ../outputs/tables/$table_name.dta, clear
append using `estimates_file'
save ../outputs/tables/$table_name.dta, replace
local ++i

// Univariate estimates
local uni_vars $all_vars news_score_c
local table_order = 1
foreach var of local uni_vars {
	use ../data/working_survival.dta, clear
	qui stcox `var'
	est store u_`i'
	local model_name: word 4 of `=e(datasignaturevars)'
	local model_name = "univariate `model_name'"
	parmest, ///
		eform ///
		label list(parm label estimate min* max* p) ///
		idnum(`i') idstr("`model_name'") ///
		stars(0.05 0.01 0.001) ///
		format(estimate min* max* %9.2f p %9.3f) ///
		saving(`estimates_file', replace)
	use `estimates_file', clear
	gen table_order = `table_order'
	local ++table_order
	save `estimates_file', replace
	use ../outputs/tables/$table_name.dta, clear
	append using `estimates_file'
	save ../outputs/tables/$table_name.dta, replace
	local ++i
}

* Save a version of the data with a clean name
* so you don't need to re-run the models when debugging
est restore full3
gen theta_chi2 = e(chi2_c) if strpos(idstr, "full_frailty")
save ../data/scratch/scratch_survival_final.dta, replace

*  ======================
*  = Now produce tables =
*  ======================

use ../data/scratch/scratch_survival_final.dta, clear
cap drop model_sequence
gen model_sequence = .
replace model_sequence = 1 if strpos(idstr, "univariate")
replace model_sequence = 2 if strpos(idstr, "no_frailty")
replace model_sequence = 3 if strpos(idstr, "time_dependent")
replace model_sequence = 4 if strpos(idstr, "full_frailty")

ren es_1 theta_est
ren es_2 theta_se

// convert to wide
tempfile working 2merge
cap restore, not
preserve
local wide_vars estimate stderr z p stars min95 max95 theta_est theta_se theta_chi2
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

// hand label the time-varying interaction
replace var_level = "0" if strpos(var_level, "0")
replace var_level = "1" if strpos(var_level, "1")
replace var_level = "4" if strpos(var_level, "4")
replace var_level = "28" if strpos(var_level, "28")
destring var_level, replace
replace varname = "news_score_timev" if strpos(varname, "tb#c")
// label the vars
spot_label_table_vars
replace tablerowlabel = "\textit{--- with modifier of Day 0 effect}" if varname == "news_score_timev"

// replace var_level_lab = "Days 0 effect"  if varname == "news_score_timev" & var_level == 0
replace var_level_lab = "Days 1--2"  if varname == "news_score_timev" & var_level == 1
replace var_level_lab = "Days 4--28"  if varname == "news_score_timev" & var_level == 4
replace var_level_lab = "Days 28+" if varname == "news_score_timev" & var_level == 28

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
	news_score ///
	news_score_timev

mt_table_order
sort table_order var_level

forvalues i = 1/4 {
	gen est_raw_`i' = estimate_`i'
	sdecode estimate_`i', format(%9.2fc) replace
	replace stars_`i' = "\textsuperscript{" + stars_`i' + "}"
	replace estimate_`i' = estimate_`i' + stars_`i'
	// replace reference categories
	replace estimate_`i' = "" if est_raw_`i' == .
	replace estimate_`i' = "--" if varname == "ccot_shift_pattern" & var_level == 3
	replace estimate_`i' = "--" if varname == "sepsis_dx" & var_level == 0
	replace estimate_`i' = "--" if varname == "v_ccmds" & var_level == 1
	replace estimate_`i' = "" if varname == "news_score_timev" & var_level == 0
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
qui su theta_est_4, meanonly
local f = r(mean)
qui su theta_chi2_4, meanonly
local theta_p = chi2tail(1,`=r(mean)')/2
if `theta_p' < 0.001 local theta_stars = "***"
local frailty: di %9.3fc `f'
local frailty "`frailty'\textsuperscript{`theta_stars'}"
local frailty = subinstr("`frailty'", " ", "",.)
local f1 "Frailty &  &  & & `frailty'  \\"
di "`f1'"


local cols tablerowlabel estimate_1 estimate_2 estimate_3 estimate_4
order `cols'

global table_name ward_survival_news_all
local super_heading "& \multicolumn{4}{c}{Hazard ratio} \\"
local h1 "& Uni-variate & Multi-variate & Time-varying & Frailty \\ "
local justify X[6l]XXXX
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
		"\cmidrule(r){2-5}" ///
		"`h1'" ///
		"\midrule" ) ///
	footlines( ///
		"\midrule" ///
		"`f1'" ///
		"\bottomrule" ///
		"\end{tabu}  " ///
		"\label{tab: $table_name} ")

est stats full*

*  ==========================
*  = Final best model table =
*  ==========================
gen estimate = est_raw_4
gen min95 = min95_4
gen max95 = max95_4
gen p = p_4

sdecode estimate, format(%9.2fc) gen(est)
sdecode min95, format(%9.2fc) replace
sdecode max95, format(%9.2fc) replace
sdecode p, format(%9.3fc) replace
replace p = "<0.001" if p == "0.000"
gen est_ci95 = "(" + min95 + "--" + max95 + ")" if !missing(min95, max95)
replace est = "--" if reference_cat == 1
replace est_ci95 = "" if reference_cat == 1
replace est = "" if varname == "news_score_timev" & var_level == 0

// now prepare footers with site level variability
qui su theta_est_4, meanonly
local f = r(mean)
qui su theta_chi2_4, meanonly
local theta_p = chi2tail(1,`=r(mean)')/2
local theta_p: di %9.3fc `theta_p'
local theta_p = subinstr("`theta_p'", " ", "",.)
if `theta_p' < 0.001 local theta_p = "<0.001"
local frailty: di %9.3fc `f'
local frailty "`frailty'"
local frailty = subinstr("`frailty'", " ", "",.)
local f1 "\multicolumn{4}{r}{Frailty `frailty' $(p`theta_p')$}  \\"
di "`f1'"


* now write the table to latex
order tablerowlabel var_level_lab est est_ci95 p
local cols tablerowlabel est est_ci95 p
order `cols'
cap br

global table_name ward_survival_news
local h1 "Parameter & Hazard ratio & (95\% CI) & p \\ "
local justify lrlr
* local justify X[5l] X[1l] X[2l] X[1r]
local tablefontsize "\scriptsize"
local arraystretch 1.0
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
		"`h1'" ///
		"\midrule" ) ///
	footlines( ///
		"\midrule" ///
		"`f1'" ///
		"\bottomrule" ///
		"\end{tabu}  " ///
		"\label{tab: $table_name} ")


*  =====================================
*  = Now inspect importance of frailty =
*  =====================================
use ../data/working_survival.dta, clear
stset dt1, id(id) failure(dead_st) exit(time dt0+90) origin(time dt0)
stsplit tb, at(1 4 28)
label var tb "Analysis time blocks"
est use ../data/estimates/survival_full3
est replay
estimates esample: `=e(datasignaturevars)'

* predict the random effects
cap drop site_re
predict site_re, effects
gsort +site_re
list icode dorisname site_re in 1/10
* NOTE: 2013-02-03 - musgrove park: best effect
gsort -site_re
list icode dorisname site_re in 1/10
* NOTE: 2013-02-03 - tameside worst effect

*  ======================================
*  = Plot the baseline survival frailty =
*  ======================================


stcurve, survival ///
 	outfile(../data/scratch/base_survival, replace)

* NOTE: 2013-05-21 - plot this using standard kernel as suggested in methods
* here is the rectangular version for reference
* hazard kernel(rectangle) width(0.5) noboundary

stcurve, ///
	hazard  ///
 	outfile(../data/scratch/base_hazard, replace)


contract site_re if ppsample
levelsof site_re, local(site_re) clean
global site_re `site_re'
use ../data/scratch/base_survival, clear
duplicates drop surv1 _t, force
rename surv1 base_surv_est


local i = 1
foreach re of global site_re {
	gen re`i' = base_surv_est^(exp(`re'))
	local plot (line re`i' _t, lcolor(black) lwidth(vthin) lpattern(solid))
	local plots `plots' `plot'
	local ++i
}
global plots `plots'
di "$plots"
* Manually create the graph: beware 60k data points so draws very slowly
sort _t
tw $plots ///
	, ///
	ylabel( ///
		0 	"0" ///
		.25 "25%" ///
		.5 	"50%" ///
		.75 "75%" ///
		1 	"100%" ///
		, nogrid) ///
	yscale(noextend) ///
	ytitle("Survival (proportion)") ///
	xlab(0(30)90) ///
	xscale(noextend) ///
	xtitle("Days following assessment") ///
	legend( off )
graph rename survival_reffects, replace
graph display survival_reffects
if c(os) == "MacOSX" local gext pdf
if c(os) != "MacOSX" local gext eps
graph export ../outputs/figures/survival_reffects_news.`gext', ///
	name(survival_reffects) ///
	replace



*  ================================
*  = Now draw the baseline hazard =
*  ================================

use ../data/scratch/base_hazard, clear
rename haz1 base_haz_est
label var base_haz_est "Mean frailty hazard"
local i = 1
foreach re of global site_re {
	gen re`i' = base_haz_est^(exp(`re')) * 1000
	local plot (line re`i' _t, lcolor(black) lwidth(vthin) lpattern(solid))
	local plots `plots' `plot'
	local ++i
}
global plots `plots'
di "$plots"
* Manually create the graph: beware 60k data points so draws very slowly
sort _t

tw $plots ///
	, ///
	ylab(, format(%9.0f) nogrid) ///
	yscale(noextend) ///
	ytitle("Hazard rate" "(Deaths per site per 1,000 patients per day)") ///
	xlab(0(30)90) ///
	xscale(noextend) ///
	xtitle("Days following assessment") ///
	legend(off)

graph rename survival_reffects_bhaz, replace
graph display survival_reffects_bhaz
if c(os) == "MacOSX" local gext pdf
if c(os) != "MacOSX" local gext eps
graph export ../outputs/figures/survival_reffects_bhaz_news.`gext', ///
	name(survival_reffects_bhaz) ///
	replace

graph combine survival_reffects_bhaz survival_reffects, rows(1) ysize(6) xsize(8)
graph rename survival_reffects_both, replace
graph display survival_reffects_both
if c(os) == "MacOSX" local gext pdf
if c(os) != "MacOSX" local gext eps
graph export ../outputs/figures/survival_reffects_both_news.`gext', ///
	name(survival_reffects_both) ///
	replace



cap log off






