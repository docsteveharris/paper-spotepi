*  ==================================
*  = Check for time-varying effects =
*  ==================================

/*
NOTE: 2013-02-01 - notes on outcome of running this by hand
Time varying effects
- age: no
- severity: yes
- delayed referral: no
- beds_none

*/

use ../data/working_survival.dta, clear
set scheme shred
stsplit tb, at(3 14 28)
label var tb "Time blocks"
list site id _t _t0 _st _d tb in 1/10

stcox age_c male ib0.sepsis_dx delayed_referral icnarc0_c ///
	out_of_hours weekend beds_none ///
	referrals_permonth_c ///
	ib3.ccot_shift_pattern ///
	hes_overnight_c ///
	hes_emergx_c ///
	cmp_beds_max_c ///
	, ///
	nolog
est store full

* Proportional hazards assumption - inspect which variables violate this
estat phtest, detail
* NOTE: 2013-02-03 - clear violation of PH hazards for severity
* nice way to plot this is as per Royston
cap drop sca* ssresidual*
predict sca*, scaledsch
rename sca5 ssresidual
clonevar ssresidual_mirror = ssresidual
replace ssresidual = _b[icnarc0_c] + (_b[icnarc0_c] - ssresidual)
running ssresidual _t if _d == 1, gen(ssresidual_bar) gense(ssresidual_se) nodraw
gen ssresidual_est = exp(ssresidual_bar)
gen ssresidual_min95 = exp(ssresidual_bar - 1.96*ssresidual_se)
gen ssresidual_max95 = exp(ssresidual_bar + 1.96*ssresidual_se)

clonevar ssresidual_max95_orig = ssresidual_max95

local beta = exp(_b[icnarc0_c])
local ymax 5

replace ssresidual_max95 = `ymax' if ssresidual_max95 > `ymax' & !missing(ssresidual_max95)

* stop plot at 21 days because noisy thereafter
drop if _t > 21

tw ///
	(rarea ssresidual_max95 ssresidual_min95 _t, sort pstyle(ci)) ///
	(line ssresidual_est _t, sort clpattern(solid)) ///
	(function y = `beta', lpattern(shortdash) range(_t)) ///
	, ///
	ylabel(0 `beta' 5 `ymax', nogrid format(%9.2f)) ///
	yscale(noextend) ///
	ytitle("Hazard ratio") ///
	xlabel(0(7)21) ///
	xscale(noextend) ///
	xtitle("Days following assessment") ///
	legend(off) ///
	ttext(`beta' 21 "Estimated (time-constant) hazard ratio" ///
		, placement(nw) justification(right) size(small) ///
		margin(small) ///
		)
graph rename survival_icnarc0_ssresidual, replace
graph display survival_icnarc0_ssresidual
graph export ../outputs/figures/survival_icnarc0_ssresidual.pdf, replace
