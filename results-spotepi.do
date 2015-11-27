* Steve Harris
* Created 140227
* Analysis code for spot-epi (epidemiology paper for (SPOT)light)
* Assumes all analysis in Stata
* Try a manual version of R's sweave - so that each paragraph in the results has the appropriate code to support it.

* Log
* ===
/*

140227	- initial set-up
140311 	- convert to sweave style
140313	- added in line to create and save working_postflight.dta
		- added in site level vars for teaching and CMP unit throughput
140418	- added in wr06_icu_admission and re-numbered wr06_mortality to wr07_mortality

*/




* # Results {>>1st Report descriptive data<<}

* ## Study implementation
* STROBE diagram details come from the following files
do cr_working.do
use ../data/working.dta, clear
qui do cr_preflight.do
save ../data/working_postflight.dta, replace
do wr01_study_implementation.do

* ## Hospitals
do wr02_hospitals.do
do ts_baseline_site_chars.do

* ## Patients
do wr03_patients.do
do tb_baseline_pt_chars.do
do tb_baseline_pt_physiology.do

* ## Severity of illness
do wr04_severity.do
do fg_dead28_aps_severity.do
* Need to hand colour the columns in iDraw
do ts_model_ward_severity.do

* ## Incidence and case finding
do wr05_incidence.do
do tb_model_count_news_high.do
* 24/7 provision vs 7/7 provision comparison comes from lincom command in do file above
* Supplemental table
do ts_model_count_combine_news.do

* ## ICU admission
do wr06_icu_admission.do

* ## Mortality
* Create survival data
use ../data/working_postflight.dta, clear
include cr_survival.do
save ../data/working_survival.dta, replace

do wr07_mortality.do
do tb_model_ward_survival_final.do




