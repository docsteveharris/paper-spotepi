*  =====================================
*  = Merge occupancy data into working =
*  =====================================
/*
Dependencies
============
- working.dta
- working_occupancy.dta

Returns
=======
- working_merge.dta

Log
===
140623
- created
140624
- now starts with working_tails
150712
- converted to run with waf

*/

// 1: if ICU and HDU then merge against ICU

use icode using ../data/working.dta, clear
contract icode
keep icode
tempfile 2merge
save `2merge', replace

use ../data/working_occupancy.dta, clear

merge m:1 icode using `2merge'
drop if _merge != 3
drop _merge


merge m:1 icnno using ../data/unitsfinal.dta, keepusing(unit_type)
drop if _merge != 3 // broomfield
drop _merge

// order units from most to least relevant
gen unit_relevance = 9
replace unit_relevance = 1 if unit_type == "icu"
replace unit_relevance = 2 if unit_type == "icu/n"
replace unit_relevance = 3 if unit_type == "hdu"

bysort icode odate ohrs (unit_relevance): drop if _N > 1 & _n != 1
contract icode icnno unit_type
drop _freq
duplicates report icode icnno unit_type
assert r(unique_value) == r(N)
tempfile 2merge
save `2merge'

// now merge this list of unique icnnos back into occupancy
use ../data/working_occupancy, clear
merge m:1 icnno using `2merge'
drop if _merge != 3
drop _merge
duplicates report icode odate ohrs
assert r(unique_value) == r(N)

tempfile 2merge
save `2merge'

// 2: Merge this list of occupancy stats against working.dta
use ../data/working_tails.dta, clear
gen odate = dofc(v_timestamp)
gen ohrs = hh(v_timestamp)

merge m:1 icode odate ohrs using `2merge'
count if _merge == 1
assert r(N) == 0
drop if _merge != 3
drop _merge

// Inspect / check
tab bed_pressure
tab xbed_pressure
tab mbed_pressure

saveold ../data/working_merge.dta, replace
cap log close

