*  ========================================
*  = Describe the patient admitted to ICU =
*  ========================================

/*
Pull tailsfinal, then merge against months, working
Strip out non-eligible patients
This can be the basis for comparison with spotlight vs other
Focus on characteristics not available for all (SPOT)light patients
i.e.
- diagnosis

CHANGED: 2013-05-21 - uses working_all and included_sites and included_months
*/

GenericSetupSteveHarris mas_spotepi cr_admitted_pts, logon

* Now pull the tailsfinal data
local ddsn mysqlspot
local uuser stevetm
local ppass ""
* odbc query "`ddsn'", user("`uuser'") pass("`ppass'") verbose
clear
odbc load, exec("SELECT * FROM spot_early.tailsfinal")  dsn("`ddsn'") user("`uuser'") pass("`ppass'") lowercase sqlshow clear
count

save ../data/working_tails.dta, replace

clear
odbc load, exec("SELECT * FROM spot_early.lite_summ_monthly")  dsn("`ddsn'") user("`uuser'") pass("`ppass'") lowercase sqlshow clear
count
tempfile 2merge
save `2merge', replace
use ../data/working_tails, clear
merge m:1 icnno studymonth using `2merge'
keep if _m == 3
drop _m

* CHANGED: 2013-05-21 - keep everything
* drop if studymonth_allreferrals == 0
* drop if studymonth_protocol_problem == 1
* drop if withinsh == 1
* drop if elgreport_heads == 0
* drop if elgreport_tails == 0
* drop if site_quality_by_month < 80
* drop if elgage == 0
* drop if elgcpr == 0

save ../data/working_tails.dta, replace

use ../data/working_all.dta, clear
cap drop included_sites
egen included_sites = tag(icode) if include == 1 & exclude1 == 0 & exclude2 == 0 & exclude3 == 0
bys icode (included_sites): egen study_site = max(included_sites)

cap drop included_months
egen included_months = tag(icode studymonth) if include == 1 & exclude1 == 0 & exclude2 == 0 & exclude3 == 0
bys icode studymonth: egen study_month = max(included_months)

gen study_patient = include == 1 & exclude1 == 0 & exclude2 == 0 & exclude3 == 0

* NOTE: 2013-05-21 - beware study_month != studymonth
keep icode icnno adno studymonth study_site study_patient study_month
contract icode icnno adno studymonth study_site study_patient study_month
drop _freq

tempfile working
save `working', replace

// site_in_study
use `working', clear
keep if study_site
contract icode
tempfile 2merge
save `2merge', replace
use ../data/working_tails, clear
count
merge m:1 icode using `2merge', nolabel keepusing()
drop if _merge == 2
gen site_in_study = _merge == 3
drop _merge
count
egen pickone_site = tag(icode)
tab site_in_study if pickone_site

preserve
// month_in_study
use `working', clear
// keep only months in study
keep if study_month 
contract icode studymonth
tempfile 2merge
save `2merge', replace
restore
count
merge m:1 icode studymonth using `2merge', nolabel keepusing()
drop if _merge == 2
gen month_in_study = _merge == 3
drop _merge
count
egen pickone_month = tag(icode studymonth)
tab month_in_study if pickone_month

preserve
// patient_in_study
use `working', clear
// keep only months in study
keep if study_patient
contract icode studymonth icnno adno
tempfile 2merge
save `2merge', replace
restore
count
merge m:1 icode studymonth icnno adno using `2merge', nolabel keepusing()
drop if _merge == 2
gen visit_in_study = _merge == 3
drop _merge
count
tab visit_in_study 

file open myvars using ../data/scratch/vars.yml, text write replace
foreach var of varlist * {
	di "- `var'" _newline
	file write myvars "- `var'" _newline
}
file close myvars
compress
shell ../ccode/label_stata_fr_yaml.py "../data/scratch/vars.yml" "../local/lib_phd/dictionary_fields.yml"
capture confirm file ../data/scratch/_label_data.do
if _rc == 0 {
	include ../data/scratch/_label_data.do
	* shell  rm ../data/scratch/_label_data.do
	* shell rm ../data/scratch/myvars.yml
}
else {
	di as error "Error: Unable to label data"
	exit
}

tab visit_in_study
tab month_in_study if pickone_month
tab site_in_study if pickone_site


// responsibility of the calling code to save this
cap log close
