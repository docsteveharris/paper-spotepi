* Steve Harris
* Created 140312

* Results - Section - Incidence and case-finding
* ==============================================

* Log
* ===
* 140312	- initial set-up
/*

## Incidence and case-finding {>>2nd: Report analysis and interpretation: Incidence<<}

{>>Need to show how incidence is related to case finding, and what component is independent thereof; then need a discussion of the determinants of incidence

- emphasise that these are new *patients* not just extra *visits*
<<}

The incidence models defined, as a baseline, a hospital that around 90,000 admissions per year (60% overnight), had a median of 11 critical care beds, provided CCOT 24 hours/day and 7 days/week, and assessed 5--15 patients per 1,000 overnight hospital admissions. Such a hospital would see 21 (95%CI 17--25) NEWS High Risk patients per month ([Table 2][table2]). For every extra 10,000 overnight admissions, a 10% increase in NEWS High Risk referrals (1.11, 95%CI 1.10--1.13) was seen. This is equivalent to approximately 5 NEWS High Risk patients per 1,000 overnight admissions. Medium and Low Risk patients were less frequently referred to, and assessed by critical care (2.5 patients per week) ([supplementary Table s2][stable2]).

CCOT provision, and local differences in referral patterns strongly affected the incidence of NEWS High Risk referrals. Hospitals with 24/7 CCOT provision saw 13.4% (95%CI 4.2--23.4%) more cases per week than those with less than 7 day provision. As the number of patients referred to, and assessed by, the critical care team increased the number of NEWS High Risk patients also increased.  In [Table 2][table2], this is reported after categorising the number of referrals per 1,000 hospital overnight admissions into a low (0--5), medium (5--15), and high (>=15) groups.  The categorisation was necessary because the association between total ward referrals and the number of NEWS High Risk patients identified at those ward referrals was not linear (Figure fig:count_news_high_rcs).  There was a steep increase in the 'yield' for the 37 sites reporting less than 10 referrals per week, and a more shallow increase thereafter ([Figure 3][figure3]).


*/

use ../data/working_postflight.dta, clear

* Define centred values used in incidence models
su hes_overnight, d
local median_overnight = r(p50) * 1000
su hes_daycase, d
local median_daycase = r(p50)
di "`median_daycase' / (`median_daycase' + `median_overnight')"
di `median_daycase' / (`median_daycase' + `median_overnight')

su cmp_beds_max,d

* NEWS High risk incidence per 1000 overnight admissions
di 22 * 12 / 53.8
* Equivalent to 22 per month x 12 months / 53.8k overnight admissions/year

*  ====================================================
*  = Precise estimate of NEWS high risk per admission =
*  ====================================================

/*
You need 
- number of NEWS High risk patients per site
- number of study months
- number of admissions (daycase and/or overnight)

Then study_months/12 x admissions gives you admissions during study
*/

use ../data/working_postflight.dta, clear
tab news_risk, gen(news_cat)
collapse (sum) news_cat* (count) n=id (firstnm) icode, by(site)
merge 1:1 icode using ../data/sites.dta
keep if _merge == 3
drop _merge
gen hes_overnight = hes_admissions - hes_daycase
keep icode site n news_cat* hes_overnight studymonth_allreferrals_analysed
forvalues i=1/4 {
	cap drop news1000_`i'
	gen news1000_`i' = 1000 * news_cat`i' / (studymonth_allreferrals_analysed / 12 * hes_overnight)
	ci news1000_`i'
}

gen news1000_all = 1000 * n / (studymonth_allreferrals_analysed / 12 * hes_overnight)
	ci news1000_all
