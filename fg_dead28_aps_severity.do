*  ======================================================
*  = Inspect functional forms with respect to mortality =
*  ======================================================

* NEWS score
set scheme shbw

use ../data/working_postflight.dta, clear
egen news_k20 = cut(news_score), at(0(1)20)

collapse ///
	(mean) dead28_bar = dead28 ///
	(sebinomial) dead28_se = dead28 ///
	(count) n = dead28 ///
	, by(news_k20)


gen min95 = dead28_bar - 1.96 * dead28_se
gen max95 = dead28_bar + 1.96 * dead28_se
replace min95 = min95 * 100
replace max95 = max95 * 100
replace dead28_bar = dead28_bar * 100

tw ///
	(bar n news_k20, ///
		barwidth(0.5) ///
		color(gs12) yaxis(1)) ///
	(rspike max95 min95 news_k20 if n > 10, yaxis(2)) ///
	(scatter dead28_bar news_k20 if n > 10, ///
		msym(S) yaxis(2)) ///
	, ///
	yscale(alt noextend axis(1)) ///
	ytitle("Patients", axis(1)) ///
	ylabel(, axis(1) nogrid) ///
	yscale(alt noextend axis(2)) ///
	ytitle("28 day mortality (%)", axis(2)) ///
	ylabel(0(25)100, axis(2) nogrid) ///
	xtitle("NHS Early Warning Score", margin(medium)) ///
	xlabel(0(5)20) ///
	xscale(noextend) ///
	text(100 0 "(A)", placement(e) yaxis(2) size(large)) ///
	legend(off)

graph rename dead28_vs_news, replace
graph export ../outputs/figures/dead28_vs_news.pdf, replace


* SOFA score
use ../data/working_postflight.dta, clear
egen sofa_k20 = cut(sofa_score), at(0(1)24)

collapse ///
	(mean) dead28_bar = dead28 ///
	(sebinomial) dead28_se = dead28 ///
	(count) n = dead28 ///
	, by(sofa_k20)


gen min95 = dead28_bar - 1.96 * dead28_se
gen max95 = dead28_bar + 1.96 * dead28_se
replace min95 = min95 * 100
replace max95 = max95 * 100
replace dead28_bar = dead28_bar * 100

tw ///
	(bar n sofa_k20, ///
		barwidth(0.5) ///
		color(gs12) yaxis(1)) ///
	(rspike max95 min95 sofa_k20 if n > 10, yaxis(2)) ///
	(scatter dead28_bar sofa_k20 if n > 10, ///
		msym(S) yaxis(2)) ///
	, ///
	yscale(alt noextend axis(1)) ///
	ytitle("Patients", axis(1)) ///
	ylabel(, axis(1) nogrid) ///
	yscale(alt noextend axis(2)) ///
	ytitle("28 day mortality (%)", axis(2)) ///
	ylabel(0(25)100, axis(2) nogrid) ///
	xtitle("SOFA (Sepsis-related Organ Failure Assessment) score", margin(medium)) ///
	xlabel(0(4)16) ///
	xscale(noextend) ///
	text(100 0 "(B)", placement(e) yaxis(2) size(large)) ///
	legend(off)

graph rename dead28_vs_sofa, replace
graph export ../outputs/figures/dead28_vs_sofa.pdf, replace

* ICNARC score
use ../data/working_postflight.dta, clear

egen icnarc0_k20 = cut(icnarc0), at(0(2)100)

collapse ///
	(mean) dead28_bar = dead28 ///
	(sebinomial) dead28_se = dead28 ///
	(count) n = dead28 ///
	if icnarc0 <= 50 ///
	, by(icnarc0_k20)


gen min95 = dead28_bar - 1.96 * dead28_se
gen max95 = dead28_bar + 1.96 * dead28_se
replace min95 = min95 * 100
replace max95 = max95 * 100
replace dead28_bar = dead28_bar * 100

tw ///
	(bar n icnarc0_k20, ///
		barwidth(1) ///
		color(gs12) yaxis(1)) ///
	(rspike max95 min95 icnarc0_k20 if n > 10, yaxis(2)) ///
	(scatter dead28_bar icnarc0_k20 if n > 10, ///
		msym(S) yaxis(2)) ///
	, ///
	yscale(alt noextend axis(1)) ///
	ytitle("Patients", axis(1)) ///
	ylabel(, axis(1) nogrid) ///
	yscale(alt noextend axis(2)) ///
	ytitle("28 day mortality (%)", axis(2)) ///
	ylabel(0(25)100, axis(2) nogrid) ///
	xtitle("ICNARC Acute Physiology Score", margin(medium)) ///
	xlabel(0(10)50) ///
	xscale(noextend) ///
	text(100 0 "(C)", placement(e) yaxis(2) size(large)) ///
	legend(off)

graph rename dead28_vs_icnarc0, replace
graph export ../outputs/figures/dead28_vs_icnarc0.pdf, replace

* Export this as figure in the thesis
graph combine dead28_vs_news dead28_vs_sofa dead28_vs_icnarc0, ///
	ycommon cols(1) ysize(12) xsize(6)
graph export ../outputs/figures/dead28_vs_severity_all.pdf, replace


* NOTE: 2014-02-18 - NEWS and SOFA only for paper
graph combine dead28_vs_news dead28_vs_sofa , ///
	ycommon cols(1) ysize(8) xsize(6)
graph export ../outputs/figures/dead28_vs_severity_news_sofa.pdf, replace

* NOTE: 2014-03-12 - you then hand colour the columns in iDraw

