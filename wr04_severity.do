* Steve Harris
* Created 140311

* Results - Section - Severity of illness
* =======================================

* Log
* ===
* 140311	- initial set-up
* 140312	- there seems to be a difference between the thesis severity scores and these
/*

## Severity of illness

{>>Focus on NEWS and SOFA as these are relevant nationally and understandable internationally respectively<<}

The median acute physiology scores on the NEWS, SOFA and ICNARC acute physiology scales were 6 (IQR 4--9), 3 (IQR 2--5), and 15 (IQR 10--20) respectively. Nearly half of the patients (7,117 patients, 44.9%) met the criteria for highest NEWS risk class with 4,411 (27.8%) and 3,944 (24.9%) in the Medium and Low risk categories. There was a clear linear association between the physiology and 28-day mortality ([Figure 2][figure2]).

Patients referred out-of-hours (7pm-7am), and older patients had higher mean physiology scores across all three scoring systems at the time of the assessment ([supplementary Table s1][stable1]). Patients with a reported sepsis diagnosis, regardless of the underlying cause, were also markedly more unwell.

{>>Table 3.11 and discussion: Predictors of severity of illness<<}

*/

use ../data/working_postflight.dta, clear

su news_score sofa_score icnarc_score
ci news_score
ci sofa_score
ci icnarc_score

tabstat news_score sofa_score icnarc_score, s(q) col(s)

tab news_risk


