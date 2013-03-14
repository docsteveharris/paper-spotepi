*  ======================================================
*  = Running do file for all numbers quoted in the text =
*  ======================================================

clear
cd ~/data/spot_early/vcode
use ../data/working.dta
qui include cr_preflight.do
count

* Results: sites
use ../data/working, clear
contract icode
tempfile 2merge
rename _freq patients
save `2merge', replace
use ../data/sites.dta, clear
merge 1:m icode using `2merge'
drop if _m == 1
duplicates drop icode, force
count
tab site_teaching
su studymonth_allreferrals, detail
su patients, detail

*  ==========================
*  = Tabulate CCOT activity =
*  ==========================

use ../data/working_postflight.dta, clear
keep if pickone_site
tab ccot_shift_pattern
* copy-past to /an_writing_chapter_ward.do
// not working nicely ... try listtex
destring ccot_senior, replace
collapse ///
	(count) n = id ///
	(median) v_est = patients_perhesadmx ///
	(p25) v_p25 = patients_perhesadmx ///
	(p75) v_p75 = patients_perhesadmx ///
	(mean) ccot_consultant ///
	(median) ccot_senior ///
	, ///
	by(ccot_shift_pattern)
egen sites = total(n)
gen percent = n / sites * 100

gen tablerowlabel = ""
replace tablerowlabel = "No CCOT" if ccot_shift_pattern == 0
replace tablerowlabel = "< 7 days" if ccot_shift_pattern == 1
replace tablerowlabel = "< 24 hrs \texttimes 7 days" if ccot_shift_pattern == 2
replace tablerowlabel = "24 hrs \texttimes 7 days" if ccot_shift_pattern == 3


local sparkhbar_width 3pt
local sparkwidth 8
gen p = percent/100
sdecode p, format(%9.2fc) replace
gen sparkbar = `"\setlength{\sparklinethickness}{`sparkhbar_width'}\begin{sparkline}{`sparkwidth'}\spark 0.0 0.5 "' ///
	 + p + `" 0.5 / \end{sparkline}\setlength{\sparklinethickness}{0.2pt}"'

sdecode n, format(%9.0gc) replace
sdecode percent, format(%9.1fc) replace
sdecode v_est, format(%9.0fc) replace
sdecode v_p25, format(%9.0fc) replace
sdecode v_p75, format(%9.0fc) replace
gen v_iqr = v_p25 + "--" + v_p75
replace ccot_consultant = 100 * ccot_consultant
sdecode ccot_consultant, format(%9.0fc) replace
order tablerowlabel n percent sparkbar ccot_consultant v_iqr

replace v_iqr = "" if ccot_shift_pattern == 0
replace v_est = "" if ccot_shift_pattern == 0
replace ccot_consultant = "" if ccot_shift_pattern == 0

local sparkspike_colour "\definecolor{sparkspikecolor}{gray}{0.7}"
local sparkline_colour "\definecolor{sparklinecolor}{gray}{0.7}"
local sparkspike_width "\renewcommand\sparkspikewidth{$sparkspike_width}"
global table_name ccot_shift_pattern
local justify spread \textwidth {X[3rb] X[rb] X[rb] X[2rb] X[2rb]}
* local tablefontsize "\footnotesize"
local arraystretch 1.0
local taburowcolors 2{white .. white}
local super_heading1 "Shift pattern & No. & (\%) & Consultant cover (\%) & Visits (per 1000 admissions) \\"
/*
Use san-serif font for tables: so \sffamily {} enclosed the whole table
Add a label to the table at the end for cross-referencing
*/
listtex tablerowlabel n percent v_est ccot_consultant ///
	using ../outputs/tables/$table_name.tex, ///
	replace rstyle(tabular) ///
	headlines( ///
		"`tablefontsize'" ///
		"\renewcommand{\arraystretch}{`arraystretch'}" ///
		"\taburowcolors `taburowcolors'" ///
		"`sparkspike_width'" ///
		"`sparkspike_colour'" ///
		"`sparkline_colour'" ///
		"\begin{tabu} `justify'" ///
		"\toprule" ///
		"`super_heading1'" ///
		"\midrule" ) ///
	footlines( ///
		"\bottomrule" ///
		"\end{tabu}   " ///
		"\label{$table_name} ") ///


*  ==================================
*  = Summarise site characteristics =
*  ==================================
use ../data/sites, clear
merge 1:m icode using ../data/working.dta, keepusing(icode)
duplicates drop icode, force
count
tab units_notincmp
tab units_notincmp_l3
/*
Royal Liverpool - the only one with L3 beds: this is a PACU
The others are Coronary Care or HDU beds
*/

// visits per 1000 hes_admission
su patients_perhesadmx,d

*  =====================================
*  = Summarise patient characteristics =
*  =====================================
use ../data/working_postflight.dta, clear
su age, d


* Results: patients
// CCMDS pre
tab v_ccmds
tab rx_resp if v_ccmds == 2
tab rxcvs if v_ccmds == 2
tab rxrrt if v_ccmds == 2
cap drop organ_support
gen organ_support = (rx_resp > 1 | rxcvs > 1 | rxrrt > 0) & !missing(rx_resp, rxcvs, rxrrt)
tab v_ccmds organ_support, row col

// sepsis
tab sepsis2001

*  ==============================
*  = Missing physiological data =
*  ==============================

use ../data/working_postflight.dta, clear
tab abg, m
misstable patterns hrate bpsys rrate creatinine sodium wcc temperature urea uvol1h pf gcst
misstable summarize hrate bpsys rrate creatinine sodium wcc temperature urea uvol1h pf gcst

*  ==================
*  = Incidence data =
*  ==================
* TODO: 2013-03-12 - estimates save and restore is wrong (see severity below for correct way)
use ../data/working_postflight.dta, clear
su hes_overnight*
su hes_emerg*

// derive specific estimates
est use ../data/estimates/count_combine
local evars ///
	hes_overnight_c ///
	hes_emergx_c ///
	cmp_beds_max_c ///
	ccot_shift_pattern ///
	patients_perhesadmx_c ///
	decjanfeb ///
	beds_none

// IRR per 10 000 extra overnight admissions (NEWS)
est restore news_high
estimates esample: `evars'
count if e(sample)
lincom hes_overnight_c*10, eform
lincom beds_none_week*10, eform

// IRR per 10 000 extra overnight admissions (severe sepsis)
est restore severe_sepsis
estimates esample: `evars'
count if e(sample)
lincom hes_overnight_c*10, eform
lincom beds_none_week*10, eform

// IRR per 10 000 extra overnight admissions (septic shock)
est restore septic_shock
estimates esample: `evars'
count if e(sample)
lincom hes_overnight_c*10, eform
lincom beds_none_week*10, eform

*  =================
*  = Severity data =
*  =================
use ../data/working_postflight.dta, clear
est drop _all
local evars ///
	hes_overnight_c ///
	hes_emergx_c ///
	cmp_beds_max_c ///
	decjanfeb ///
	weekend ///
	out_of_hours ///
	delayed_referral ///
	referrals_permonth_c ///
	ccot_shift_pattern ///
	age_c ///
	male ///
	sepsis_dx
// mean severity icnarc
est use ../data/estimates/model_ward_severity.ster, number(1)
estimates esample: `evars'
count if e(sample)
lincom _cons
lincom hes_overnight_c * 10

est use ../data/estimates/model_ward_severity.ster, number(2)
// mean severity news
estimates esample: `evars'
count if e(sample)
lincom _cons
lincom hes_overnight_c * 10

est use ../data/estimates/model_ward_severity.ster, number(3)
// mean severity sofa
estimates esample: `evars'
count if e(sample)
lincom _cons
lincom hes_overnight_c * 10


*  ========================
*  = Survival and outcome =
*  ========================


// simple survival figures

use ../data/working_survival.dta, clear
stset dt1, id(id) failure(dead_st) exit(time dt0+90) origin(time dt0)
gen class  = 0
replace class = -1 if v_disposal == 5
replace class = 1 if rxlimits == 1
tab class if ppsample
sts list, at(0 1 3 7 28 90) failure  noshow
sts list, at(0 1 3 7 28 90) failure by(class) noshow
sts list, at(0 1 3 7 28 90) failure by(rxlimits) noshow

