*  ===========================================================
*  = Funnel plot of the incidence of NEWS High Risk patients =
*  ===========================================================

/*
created:	130417
modified:	130417


*/

forvalues i = 1/3 {

	use ../data/working_postflight.dta, clear
	cap drop __*
	set scheme shbw
	count

	tab news_risk



	label list news_risk

	keep if news_risk >= `i'
	if `i' == 1 local risk Low-Medium-High
	if `i' == 2 local risk Medium-High
	if `i' == 3 local risk High

	cap drop news_class
	gen news_class = 1

	gen n = 1

	drop if studymonth > 12
	collapse ///
		(firstnm) icode ///
		(count) n ///
		(max) periods = studymonth ///
		(sum) events = news_class ///
		, ///
		by(site)

	list in 1/10


	cap drop admissions
	gen admissions = events / periods
	su admissions
	local min = r(min)
	local max = r(max)

	summ  events
	local E=r(sum)
	summ periods
	local N=r(sum)
	local R=`E'/`N'
	local grand_mean = round(`R')

	global winsor 10

	poisfunnel events periods ///
		, ///
		winsor($winsor) ///
		scatteropts( ///
			mcolor(black red) msymbol(oh O) ///
			) ///
		xscale(noextend) ///
		xlab(0(3)12) ///
		ylab( `grand_mean' , custom add labgap(large) labcolor(black) ) ///
		ylab(0(25)125) ///
		ytitle( "Monthly referrals", size(large)) ///
		xtitle("Study months observed", size(large)) ///
		title("`risk'",  size(large)) ///
		graphregion(margin(small)) ///
		legend(off)


	graph rename plot`i', replace
}

graph combine plot1 plot2 plot3 ///
	, ///
	rows(1) ysize(3) xsize(6)
graph rename funnel_news_all, replace

graph export ../outputs/figures/funnel_news_all.pdf ///
    , name(funnel_news_all) replace

