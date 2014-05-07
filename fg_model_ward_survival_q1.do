/*
Dependencies
============
tb_model_ward_survival_final.do
which generates
../data/estimates/survival_full3

Log
===
140507
- created this file by cutting code from end of tb_model_ward_survival_final.do
- improve random effects plot by colour coding the lines
	the blacker the line, the more data that it is based on
	ditto with line width
140507
- file now calculates quintiles of survival for the purposes of a scatter plot

*/

*  =============================
*  = Now work out survival =
*  =============================

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
keep icode site id _t site_re ppsample

duplicates drop icode site_re , force
drop if missing(site_re)
sort icode
list icode site_re  in 1/10
tempfile site_re_list
save `site_re_list', replace

use ../data/scratch/base_survival, clear
duplicates drop surv1 _t, force
rename surv1 base_surv_est
tempfile working
save `working', replace

tempfile base_surv_est_re
use `site_re_list', clear
sort site_re
cap restore, not
local last = _N
forvalues i = 1/`last' {
	local icode = icode[`i']
	local site_re = site_re[`i']
	di "icode: `icode'  site_re:`site_re'"
	preserve
	use `working', clear
	gen icode = "`icode'"
	gen site_re =  `site_re'
	replace base_surv_est = base_surv_est^(exp(`site_re'))
	if `i' == 1 {
		save `base_surv_est_re', replace
	}
	else {
		append using `base_surv_est_re'
		save `base_surv_est_re', replace
	}
	restore
}
use `base_surv_est_re', clear
sort icode _t
save ../data/scratch/base_surv_est_re, replace

use ../data/scratch/base_surv_est_re, clear
* Now extract the first time that base_surv_est drops below xx%
by icode: egen tmax = max(_t) if base_surv_est > 0.8
duplicates drop icode tmax, force
drop if missing(tmax)
keep icode tmax
tempfile working
save `working', replace
use icode dorisname using ../data/working_postflight.dta, clear
contract icode dorisname, freq(n)
tempfile 2merge
save `2merge', replace
use `working', clear
merge 1:1 icode using `2merge'
list if _merge != 3
list  in 1/10

scatter tmax n ///
	, ///
	ytitle("Time for survival proportion" "to fall to 80% (days)") ///
	xtitle("Sample size (patients)") ///
	name(survival_reffects_q1, replace)

graph export ../outputs/figures/survival_reffects_q1.pdf, ///
	name(survival_reffects_q1) ///
	replace
