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

use ../data/count_news_high_linear, clear
est use ../data/estimates/news_high_linear
est store news_high_linear
est dir
est replay, eform
// Number of extra patients per 10,000 extra admissions per week
lincom 10 * hes_overnight_c
// Express the baseline incidence rate as patients per 1,000 admissions centred at 62.5k admissions per year
lincom _cons, eform
di `=r(estimate)' * 365 / 7 / 62.5


* NOTE: 2013-05-18 - incidence per 1000 admissions across sites
use ../data/working_postflight.dta, clear
lookfor hes day
collapse (count) n = id (firstnm) studydays hes_overnight hes_admissions, by(site)
li in 1/5
gen v_per1000 = n / studydays * 365 / hes_overnight
su v_per1000, d
gsort -v_per1000
li in 1/15
gen all_per1000 = n / studydays * 365 / hes_admissions * 1000
su all_per1000, d


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

tab ccot_shift_pattern abg if ccot_shift_pattern == 0, row
tab ccot_shift_pattern abg if ccot_shift_pattern != 0, row
prtest abg, by(ccot)

tab out_of_hours  abg , row
prtest abg, by(out_of_hours)
prtest abg, by(male)
prtest abg, by(male)
/*
What proportion of the severity score zero weights are due to missing data?
NEWS
ICNARC
SOFA
*/



tab news_risk

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
stset dt1, id(id) failure(dead_st) exit(time dt0+365) origin(time dt0)
gen class  = 0
label list v_disposal
replace class = -1 if v_disposal == 5
replace class = 1 if rxlimits == 1
tab class if ppsample
sts list, at(0 1 7 30 365) failure  noshow
sts list, at(0 1 7 30 365) failure by(class) noshow
sts list, at(0 1 7 30 365) failure by(rxlimits) noshow

// mortality in 12th month following ward assessment among patients without 
// treatment limitation order

sts list, at(330 365) failure  noshow

di 115/8533/35*1000 // daily rate
di 1 / (115/8533/35*365) // annual rate
sts list, at(330 365) failure by(rxlimits) noshow


// Frailties
est use ../data/estimates/survival_full3.ster
est store full3
est replay
di e(theta)
di e(theta) - 1.96*e(se_theta)
di e(theta) + 1.96*e(se_theta)



// Sensitivity analysis
use ../outputs/tables/count_news_highsubl_sens,clear
d
list estimate stderr if parm == "_cons"
di 4.515 + 1.96 * (0.219)
di 4.515 - 1.96 * (0.219)

di 5.036 + 1.96 * (0.169)
di 5.036 - 1.96 * (0.169)


// Length of stay for ward admissions to ICU
use ../data/secure/cmpclean
lookfor los
su yhlos
su yhlos,d
lookfor elg
su yhlos if elgcore
su yhlos if elgCore
su yhlos if elgCore,d


// Does the shape of the baseline hazard depend on the severity of illness?
// Is the peak more delayed in the less severely unwell?
use ../data/working_survival.dta, clear
tab news_risk if ppsample
sts graph, ///
	by(news_risk) ///
	hazard ci kernel(rectangle) width(0.5) noboundary ///
	ciopts(pstyle(ci)) ///
	tscale(noextend) ///


// Severity and survival
use ../data/working_survival.dta, clear
stset dt1, id(id) origin(dt0) failure(dead_st) exit(time dt0+365)
tab news_risk rxlimits if ppsample, row 
sts list if rxlimits == 0 , at(1 7 30 365) by(news_risk) 
sts list, at(1 7 30 365) by(rxlimits)


// Match quality for ward patients
* 130521
use ../data/working_tails.dta, clear
count

tab elgreport_heads
tab elgreport_tails
tab match_is_ok if ///
	elgcore == 1 ///
	& elgreport_tails != 0 ///
	& elgreport_heads != 0 ///
	& withinsh != 1 ///
	& site_quality_q1 > 80 ///
	& site_quality_by_month > 80




