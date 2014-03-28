* Steve Harris
* Created 140311

* Results - Section - Study implementation
* ========================================

* Log
* ===
* 140311	- initial set-up

* Q: Teaching status of hospitals
use icode using ../data/working_postflight.dta, clear
contract icode
rename _freq n
merge 1:1 icode using ../data/sites.dta
keep if _merge == 3
drop _merge

tab site_teaching

* Q: Patients per hospital
su n, d
gen n_per_hes_admx = n / hes_admissions * 1000
su n_per_hes_admx,d

gen hes_overnight = hes_admissions - hes_daycase
gen n_per_hes_overnight = n / hes_overnight * 1000
su n_per_hes_overnight

gen n_per_hes_emx = n / hes_emergencies * 1000
su n_per_hes_emx, d 


* Q: How did participation vary by site and by month?
use ../data/working.dta, clear
preserve
gen v_month=mofd(dofc(v_timestamp))
encode icode, gen(sid)
gen v=1
collapse (count) v, by(sid v_month)
xtset sid v_month
xtdes, patterns(54)
restore






