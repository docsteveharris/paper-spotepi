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
set scheme shred
stset dt1, id(id) failure(dead_st) exit(time dt0+365) origin(time dt0)
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
	tlabel(0 30 90 180 365) ///
	ttitle("Days following bedside assessment", margin(medium)) ///
	yscale(noextend) ///
	tscale(noextend) ///
	ylabel( ///
		0.000 "0" ///
		0.005 "5" ///
		0.010 "10" ///
		0.015 "15" ///
		0.020 "20" ///
		0.025 "30" ///
		, nogrid) ///
	ytitle("Deaths" "(per 1000 patients per day)", margin(medium)) ///
	subtitle("(A) Daily mortality rate", position(11) justification(left) ) ///
	legend(off) ///
	title("") ///
	xsize(6) ysize(6)

graph rename hazard_all, replace
graph display hazard_all

sts graph, surv ci ///
	ciopts(color(gs12)) ///
	plotopts(lwidth(thin)) ///
	tscale(noextend) ///
	tlabel(0 30 90 180 365) ///
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
	title("") ///
	subtitle("(B) Kaplan-Meier survival estimate", position(11) justification(left) ) ///
	xsize(6) ysize(6)

graph rename survival_all, replace
graph display survival_all
graph combine hazard_all survival_all, cols(2) ysize(6) xsize(8) 
graph export ../outputs/figures/hazard_and_survival_all.pdf, replace

