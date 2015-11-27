// Prepare tails data so that it can be merged with working.dta

/*
Dependencies
============
- working.dta
- spot_early.tailsfinal

Log
===
140617
- created
140623
- saves to working tails again
150712
- converted to work under Waf
- converted to use the safe version of tails

*/
clear
include project_paths.do
cap log close
log using ${PATH_LOGS}cr_workingtails.txt,  text replace
pwd

* CHANGED: 2015-11-06 - [ ] using old copy of tails data b/c probs with
* stata-odbc-sql connection
use ${PATH_DATA_ORIGINAL}working_tails.dta
count
assert r(N)==58183

* Pull the tailsfinal data
* local ddsn mysqlspot
* local uuser stevetm
* local ppass ""

* local ddsn safe-knox
* local uuser steve
* local ppass "[po-09"

* odbc query "`ddsn'", user("`uuser'") pass("`ppass'") verbose
* odbc load, exec("SELECT * FROM spotlight.tailsfinal")  dsn("`ddsn'") user("`uuser'") pass("`ppass'") lowercase sqlshow clear
* count


duplicates report icnno adno
assert r(unique_value) == r(N)

keep icnno adno imscore

tempfile 2merge
save `2merge', replace

use ${PATH_DATA}working.dta, clear
count
local patient_count = _N
tempfile 2append
keep if missing(icnno, adno)
save `2append', replace

use ${PATH_DATA}working.dta, clear
drop if missing(icnno, adno)
merge 1:1 icnno adno using `2merge'
list icode icnno adno lite_open v_timestamp lite_close if _merge == 1
// NOTE: 2014-06-17 - missing 39 cases: seems random
drop if _merge == 2
drop _merge

append using `2append'
count
assert _N == `patient_count'

clonevar ims1 = icnarc_score
rename imscore ims2
gen ims_delta = ims2 - ims1

saveold ${PATH_DATA}working_tails.dta, replace

