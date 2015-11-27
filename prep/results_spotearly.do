* Steve Harris
* Created 140522
* Based on paper-spotepi/results-spotepi.do
* Analysis code for paper-spotearly
* Assumes all analysis in Stata
* Try a manual version of R's sweave - so that each paragraph in the results has the appropriate code to support it.

* Log
* ===
/*

140522	- initial set-up
140604	- completed strobe diagram; started work on comparison tables
140616	- added mt_Programs.do

150107  - moved as much of this functionality to makefile as possible
150110  - ultimate plan should be to deprecate this file
150712  - stripped and cleaned so only runs the minimal scripts needed
        - compatible with waf set up

*/

clear
include project_paths.do
cap log close
log using ${PATH_LOGS}results_spotearly.txt,  text replace
pwd

* do mt_programs.do

* CHANGED: 2015-01-07 - [ ] everything between >>><<< runs in the makefile
* >>>
* do cr_sites.do
* do cr_units.do

* # Results {>>1st Report descriptive data<<}

* ## Study implementation
* STROBE diagram details come from the following files
* do cr_working.do

// Prepare occupancy data
* do cr_preflight_occupancy.do

// Now merge in ICNARC score on admission
* use ../data/working.dta, clear
* do cr_working_tails.do
* do cr_working_occ.do
* <<<
// now you should be starting off with working_merge.dta

// now run cr_preflight immediately

use ${PATH_DATA}working_merge.dta, clear
do ${PATH_CODE}prep/cr_preflight.do
saveold ${PATH_DATA}working_postflight.dta, replace

* NOTE: 2015-07-12 - [ ] early exit while building up waf
exit
* Should be able to generate numbers for STROBE from here

* Create survival data - do this now b/c you need single record survival
* NOTE: 2015-11-04 - [ ] commented out because this now happens withing cr_survival
* use ${PATH_DATA}working_postflight.dta, clear
* do ${PATH_CODE}prep/cr_survival.do
* save ${PATH_DATA}working_survival.dta, replace

use ../data/working_survival.dta, clear
include cr_postflight_plus.do
saveold ../data/working_postflight_plus.dta, replace

* ## Study implementation
* describe the strobe diagram and the exclusions and the final patient numbers
* do wr01_study_implementation.do

exit
* CHANGED: 2015-01-07 - [ ] stop here; analysis should be in makefile
* ===================================================================

* ## Comparison to full cohort
* compare patient characteristics - using existing tables
do ts_early_comparison.do

* ## Patients
do tb_baseline_pt_chars.do
do tb_baseline_pt_physiology.do

do fg_full_by_week.do
do wr03_occupancy.do
do tb_occupancy_effects.do
do tb_occupancy_model.do // NB: xtgee v slow, commented out

* ## Delay to admission / admission pathway
do fg_time2icu_by_decision.do // BEWARE: Hand edit fig in iDraw
do wr05_delay.do

do  tb_model_icu_recommend.do
do  tb_model_icu_accept.do
do  tb_model_icu_early4.do
do tb_model_time2icu.do

* ## Survival models
do wr05_survival.do
do tb_model_survival.do

* ## Instrumental variable analysis
do wr06_iv.do
do tb_model_iv_linear.do
do tb_model_iv_biprobit.do

* ## Sensitivity analyses
do fg_iv_effect_by_time.do






