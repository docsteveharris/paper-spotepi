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

* do mt_programs.do


use ../data/working_merge.dta, clear
do prep/cr_preflight.do
saveold ../data/working_postflight.dta, replace

