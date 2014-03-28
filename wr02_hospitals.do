* Steve Harris
* Created 140311

* Results - Section - Hospitals
* =============================

* Log
* ===
* 140311	- initial set-up

/*

Critical Care Outreach Teams operated 24 hours/day and 7 days/week in 15 (31%) hospitals, less than 24 hours/day in 19 (39%) hospitals, and less than 7 days/week in 13 (27%) hospitals. Two (4%) hospitals had no CCOT. Where CCOT provison was <7 days/week, hospitals reported 3.4 (1.6--2.0) visits per 1,000 overnight admissions increasing to 5.5 (3.9--7.7) per 1,000 overnight hospital admissions for 24/7 CCOT provision.

{>>Add in supplementary table for participating hospital characteristics: baseline_sites_chars<<}

*/

* Q: CCOT provision by hospital
use icode using ../data/working_postflight.dta, clear
contract icode
rename _freq n
merge 1:1 icode using ../data/sites.dta
keep if _merge == 3
drop _merge

tab ccot_shift_pattern

gen hes_overnight = hes_admissions - hes_daycase
gen n_per_hes_overnight = n / hes_overnight * 1000
su n_per_hes_overnight

tabstat n_per_hes_overnight, by(ccot_shift_pattern) s(n mean q)

