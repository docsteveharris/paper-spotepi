*  ======================================================
*  = Running do file for all numbers quoted in the text =
*  ======================================================
clear 
* STROBE diagram
/*
via cr_working.log
16209 patients eligible of which 15867 completed follow-up = 97.9%
*/


clear
cd ~/data/spot_early/vcode
use ../data/working.dta
qui include cr_preflight.do
count

* Results: sites
use ../data/working_postflight, clear
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
* standardise patients to an annual number
gen pts_annualised =  patients * 365 / studydays
su pts_annualised, detail
gen p_per1000 = pts_annualised / hes_admissions * 1000
su p_per1000, d
gen hes_overnight = hes_admissions - hes_daycase
gen p_per1000onight = pts_annualised / hes_overnight * 1000
* Number of pts_annualised per 1000 overnight admissions
su p_per1000onight, d

* Number per 1000 emergency admissions
gen p_per1000emx = pts_annualised / hes_emerg * 1000
su p_per1000emx, d


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

