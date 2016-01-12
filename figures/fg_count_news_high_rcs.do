* author: Steve Harris
* date: 2015-12-01
* subject: Plot RCS of referral patterns

* Readme
* ======


* Todo
* ====


* Log
* ===
* 2015-12-01
* - file created by copying code at end of tb_model_count_news_high.do
* - put under waf control
* 2016-01-12
* - switched to doit control


*  ======================================================
*  = Now draw the predicted values for the cubic spline =
*  ======================================================

clear
cap log close
log using ../logs/fg_count_news_high_rcs.txt,  text replace
pwd

* NOTE: 2014-03-13 - change scale to to per day vs per week

use patients_perhesadmx using ../data/working_postflight, clear
set scheme shbw
su patients_perhesadmx
local patients_perhesadmx_mean = r(mean)
use ../data/count_news_high_cubic, clear
gen patients_perhesadmx = patients_perhesadmx_c + `patients_perhesadmx_mean'
est use ../data/estimates/news_high_cubic
eret li
* est restore news_high_cubic
est replay, eform
* Graph using adjustrcspline ...
adjustrcspline, link(log)

* CHANGED: 2014-03-13 - scale prediction to per month (mean is per day)
* prediction assuming RE is 0
predict yhat, mu
replace yhat = yhat * 365.25 / 12

running yhat patients_perhesadmx ///
	, ///
	span(1) repeat(3) ///
	lpattern(longdash) lwidth(medthick) ///
	ytitle("NEWS High Risk patients" "(per month)") ///
	ylabel(0(10)50) ///
	yscale(noextend) ///
	xtitle("Ward referrals assessed by ICU" "(per month)") ///
	xlabel(0(10)50) ///
	xscale(noextend) ///
	scatter(msymbol(p) msize(vtiny) mcolor(gs4) jitter(2)) ///
	xsize(6) ysize(6) ///
	title("")

if c(os) == "Unix" local gext eps
if c(os) == "MacOSX" local gext pdf
graph rename count_news_high_rcs, replace
graph display count_news_high_rcs
graph export ../write/figures/count_news_high_rcs.`gext' ///
    , name(count_news_high_rcs) replace
