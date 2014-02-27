*  =====================================
*  = Plot baseline survival and hazard =
*  =====================================
/*
- re-run using piecewise expoential poisson 
*/
local clean_run 0
if `clean_run' == 1 {
	include cr_survival.do
}

*  ===============================
*  = Simple non-parametric plots =
*  ===============================
use ../data/working_survival.dta, clear
stset dt1, id(id) failure(dead_st) exit(time dt0+90) origin(time dt0)
sts list, at(0/28)
* sts graph
* count if ppsample
* stci, p(25)
// rectanglur kernel automatically excludes a single bandwidth at each boundary
// as set here it should be calculating the 'daily' death rate
sts graph, ///
	hazard ci kernel(rectangle) width(0.5) noboundary ///
	ciopts(pstyle(ci)) ///
	tscale(noextend) ///
	tlabel(0(30)90) ///
	ttitle("Days following bedside assessment", margin(medium)) ///
	yscale(noextend) ///
	tscale(noextend) ///
	ylabel( ///
		0.000 "0" ///
		0.010 "10" ///
		0.020 "20" ///
		0.030 "30" ///
		0.040 "40" ///
		0.050 "50" ///
		, nogrid) ///
	ytitle("Deaths" "(per 1000 patients per day)", margin(medium)) ///
	legend(off) ///
	title("Daily mortality rate") ///
	xsize(6) ysize(6)
graph rename hazard_all, replace

sts graph, surv ci ///
	ciopts(color(gs12)) ///
	plotopts(lwidth(thin)) ///
	tscale(noextend) ///
	tlabel(0(30)90) ///
	ttitle("Days following bedside assessment", margin(medium)) ///
	yscale(noextend) ///
	tscale(noextend) ///
	ylabel( ///
		0 	"0" ///
		.25 "25%" ///
		.5 	"50%" ///
		.75 "75%" ///
		1 	"100%" ///
		, nogrid) ///
	ytitle("Survival" "(percentage)", margin(medium)) ///
	legend(off) ///
	title("Survival curve") ///
	xsize(6) ysize(6)

graph rename survival_all, replace
graph combine hazard_all survival_all, cols(1) ysize(6) xsize(4)
graph export ../outputs/figures/hazard_and_survival_all.pdf, replace


exit
*  ==================================
*  = Piecewise exponential poission =
*  ==================================
// problems with this ... leave for now

local run_piecewise 0
if `run_piecewise' == 1 {
	use ../data/working_survival, clear
	stset dt1, id(id) origin(dt0) failure(dead) exit(time dt0+90)
	stsplit tsplit, every(1)
	sts list, at(0 1 3 7 28 90)
	gen risktime = _t - _t0

	// NOTE: 2012-10-04 - comment out code below and run collapsed version instead as quicker
	// glm _d ibn.tsplit, family(poisson) lnoffset(risktime) nocons eform
	// NOTE: 2012-10-04 - copy and paste stata table this into datagraph for quick inspection

	save ../data/scratch/scratch.dta, replace

	use ../data/scratch/scratch, clear
	// SOMEDAY: 2013-03-14 - recheck this model in Royston: the number of deaths
	// is not right and exceeds the number *actually* observed
	collapse (min) _t0 (max) _t (count) n = _d (sum) risktime _d, by(tsplit)
	// NOTE: 2013-03-14 - you don't need to run the this model unless 
	// you have covariates you wish to explore
	// You are in fact just counting the number of deaths per unit time 
	// And this gives you the baseline hazard
	gen baseline_hazard = _d/n
	glm _d ibn.tsplit, family(poisson) lnoffset(risktime) nocons eform
	// in the following predictions you need to divide by n 
	// because the model is generated using grouped data
	cap drop yhat*
	predict yhat, xb
	predict yhat_se, stdp
	cap drop estimate min* max*
	gen estimate = (exp(yhat) / n)
	gen min95 = (exp(yhat - 1.96 * yhat_se) / n)
	gen max95 = (exp(yhat + 1.96 * yhat_se) / n)
	tw ///
		(rarea max95 min95 tsplit, pstyle(ci)) ///
		(line estimate tsplit, lpattern(solid) lcolor(black)) ///
		, ///
		xlabel(0(7)90) ///
		ttitle("Days following bedside assessment", margin(medium)) ///
		yscale(noextend) ///
		ylabel( ///
			0.000 "0" ///
			0.010 "10" ///
			0.020 "20" ///
			0.030 "30" ///
			0.040 "40" ///
			0.050 "50" ///
			, nogrid) ///
		ytitle("Deaths" "(per 1000 patients per day)", margin(medium)) ///
		legend(off) ///
		title("Mortality rate") ///
		xsize(6) ysize(6)
	graph rename piecewise_exponential, replace


}
estimates drop _all
use ../data/working_survival, clear

stcox, estimate
est store cox_base
estimates stats *
predict h_cox, basehc

streg , dist(exponential)
est store exp_base
estimates stats *
predict h_exp, hazard

streg , dist(weibull)
est store wb_base
estimates stats *
predict h_wb, hazard

streg , dist(gompertz)
est store gom_base
estimates stats *
predict h_gom, hazard

sort _t
tw ///
	(line h_cox _t, c(l)) ///
	(line h_exp _t, c(l)) ///
	(line h_wb _t, c(l)) ///
	(line h_gom _t, c(l)) 
