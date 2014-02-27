* Steve Harris

* Log
* 131009 
* - copied code from an_fig_unadjusted_surival.do in spot_early/vcode
* - modifications such that it runs with expected to live/die 

*  ==================================================
*  = UNADJUSTED SURVIVAL BY EXPECTED TO LIVE OR DIE =
*  ==================================================

use ../data/working_survival.dta, clear
set scheme shred

stset dt1, id(id) failure(dead_st) exit(time dt0+90) origin(time dt0)
local tlabels "0(30)90"

label list pt_cat

sts graph if pt_cat != 0, ///
	by(pt_cat) ///
	hazard ci kernel(rectangle) width(0.5) noboundary ///
	plot1opts(lcolor(red) lpattern(solid)) ///
	plot2opts(lcolor(purple) lpattern(solid)) ///
	plot3opts(lcolor(blue) lpattern(solid)) ///
	ciopts(pstyle(ci)) ///
	tscale(noextend) ///
	tlabel(`tlabels') ///
	ttitle("Days", size(large) margin(medium)) ///
	yscale(noextend) ///
	tscale(noextend) ///
	ylabel( ///
		0.000 "0" ///
		/// 0.010 "10" ///
		/// 0.020 "20" ///
		0.050 "50" ///
		0.100 "100" ///
		0.150 "150" ///
		, nogrid) ///
	ytitle("Deaths" "(per 1000 patients per day)", size(large) margin(medium)) ///
	legend( ///
		title("Patient category", size(medium) pos(11) justification(left)) ///
		order(9 8 7) ///
		label(7 "Expected to live") ///
		label(8 "At risk") ///
		label(9 "Expected to die") ///
		ring(0) pos(2) ///
		cols(1) ///
		) ///
	title("") ///
	xsize(3) ysize(4)

graph rename hazard_by_pt_cat, replace

sts graph if pt_cat != 0, ///
	by(pt_cat) ///
	survival ci ///
	plot1opts(lcolor(red) lpattern(solid)) ///
	plot2opts(lcolor(purple) lpattern(solid)) ///
	plot3opts(lcolor(blue) lpattern(solid)) ///
	ciopts(pstyle(ci)) ///
	tscale(noextend) ///
	tlabel(`tlabels') ///
	ttitle("Days", size(large) margin(medium)) ///
	yscale(noextend) ///
	tscale(noextend) ///
	ylabel( ///
		0 	"0" ///
		.25 "25%" ///
		.5 	"50%" ///
		.75 "75%" ///
		1 	"100%" ///
		, nogrid) ///
	ytitle("Survival" "(percent)", size(large) margin(medium)) ///
	legend( off ///
		/// title("Patient category", size(medium) pos(11) justification(left)) ///
		/// order(9 8 7) ///
		/// label(7 "Low") ///
		/// label(8 "Medium") ///
		/// label(9 "High") ///
		/// ring(0) pos(7) ///
		/// cols(1) ///
		) ///
	title("") ///
	xsize(3) ysize(4)

graph rename survival_by_pt_cat, replace


graph combine hazard_by_pt_cat survival_by_pt_cat, rows(1) ysize(4) xsize(6)
graph export ../outputs/figures/hazard_and_survival_pt_cat_compare.pdf, replace


