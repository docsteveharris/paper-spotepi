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

*/

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

* NOTE: 2014-05-07 - uncomment below if you wish to draw baseline hazard
* stcurve, ///
* 	hazard  ///
*  	outfile(../data/scratch/base_hazard, replace)


cap drop ppsample
egen ppsample = tag(id)
collapse (firstnm) site_re (count) n=id if ppsample, by(site)
drop if site == .
* sort order is important: will determine order lines drawn in plot and hence appearance
gsort n
gen i=_n
su n
local n_max = r(max)
qui su i
local i_max = r(max)
tempfile site_re
save `site_re'

use ../data/scratch/base_survival, clear
duplicates drop surv1 _t, force
rename surv1 base_surv_est

cap restore, not
forvalues i = 1(1)`i_max' {
	preserve
	use if i == `i' using `site_re', clear
	local re = site_re[1]
	local n = n[1]
	restore
	gen re`i' = base_surv_est^(exp(`re'))
	// use the gs0 (black) to gs16 (white) scale
	// the darkest will be where n approaches n_max hence 15-14 = 1
	// the lightest will be where n approaches 0 hence 15-0 = 15
	local lcolor = 15 - round((`n'/`n_max')*12)
	local relsize = 0.0 +  (round(`n'/`n_max',0.25)*2)
	local plot (line re`i' _t, lcolor(gs`lcolor') lwidth(*`relsize') lpattern(solid))
	local plots `plots' `plot'
}
global plots `plots'
di "$plots"

* CHANGED: 2014-02-24 - now save this in order to work with random effects
save ../data/scratch/base_survival_re, replace

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
graph export ../outputs/figures/survival_reffects.`gext', ///
	name(survival_reffects) ///
	replace

