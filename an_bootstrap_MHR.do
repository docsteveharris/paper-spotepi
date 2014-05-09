* Steve Harris
* Log
* ===
/*
140509
- initial set-up
- code copied and combined fr tb_model_ward_survival_final.do

*/

*  =================================
*  = Bootstrap Median Hazard ratio =
*  =================================
local patient_vars ///
	age_c ///
	male ///
	ib0.sepsis_dx ///
	delayed_referral ///
	ib1.v_ccmds

global patient_vars `patient_vars'

local timing_vars ///
	out_of_hours ///
	weekend ///
	decjanfeb

global timing_vars `timing_vars'

local site_vars ///
		teaching_hosp ///
		hes_overnight_c ///
		hes_emergx_c ///
		cmp_beds_max_c ///
		cmp_throughput ///
		patients_perhesadmx_c ///
		ib3.ccot_shift_pattern

global site_vars `site_vars'

global all_vars ///
	`site_vars' ///
	`timing_vars' ///
	`patient_vars'

use ../data/working_postflight.dta, clear
*  ==============
*  = Debugging? =
*  ==============
* keep if site <= 10
* must do sample 10 before generating survival data else gaps

keep ///
	dead_icu dead date_trace ///
	v_timestamp icu_admit icu_discharge last_trace id site ///
	age_c male sepsis_dx delayed_referral v_ccmds ///
	out_of_hours weekend decjanfeb ///
	teaching_hosp hes_overnight_c hes_emergx_c ///
	cmp_beds_max_c cmp_throughput patients_perhesadmx_c ///
	ccot_shift_pattern ///
	icnarc0_c
save ../data/scratch/scratch.dta, replace

use ../data/scratch/scratch.dta, clear
qui include cr_survival.do
stset dt1, id(id) failure(dead_st) exit(time dt0+90) origin(time dt0)
stsplit tb, at(1 4 28)
label var tb "Analysis time blocks"

cap program drop est_mhr
program define est_mhr, rclass
	stcox $all_vars icnarc0_c i.tb#c.icnarc0_c ///
		, shared(site) ///
		noshow
	local twoinvtheta2 = 2 / (e(theta)^2)
	local mhr = exp(sqrt(2*e(theta))*invF(`twoinvtheta2',`twoinvtheta2',0.75))
	noi di `mhr'
	return scalar mhr = `mhr'
end


cap drop ppsample
egen ppsample = tag(id)

* Check program returns r(mhr)
* est_mhr
* assert r(mhr) != .


* NOTE: 2014-05-09 - bootstrap with complex data structure
/*
You must cluster on id because the data is survival and stsplit.
You would otherwise risk removing observations from within a patient.
More difficult to decide is whether or not you should include site as a cluster.
*/

* CHANGED: 2014-05-09 - added id to cluster - although probably redundant
set seed 3001
bootstrap r(mhr) , reps(5) nowarn noisily cluster(site id): est_mhr

