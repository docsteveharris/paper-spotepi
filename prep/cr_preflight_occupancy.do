* WAF set up
clear
global THIS_FILE = "cr_preflight_occupancy"
include project_paths.do
cap log close
log using ${PATH_LOGS}${THIS_FILE}.txt,  text replace
pwd

*  ===============================================================
*  = Pulls working occupnacy data from data-spotstudy and cleans =
*  ===============================================================
/*
Log
===
140605
- copied from analysis-spotearly
- avoids running the cr_occupancy code
140623
- bring in a second definition of occupancy b/c problems with Northampton
- I think it makes more sense to use median
140623
- set data up as panel data and create moving median

*/

use icode using ${PATH_DATA}working.dta, clear
contract icode
drop _freq
tempfile 2merge
save `2merge', replace

* !cp ~/data/spot_study/data/working_occupancy24.dta ${PATH_DATA}working_occupancy24.dta
clear
use ${PATH_DATA}original/working_occupancy24.dta
// FIXME: 2014-06-23 - temp fix for duplicate observations
sort icode icnno odate ohrs
duplicates drop icode icnno odate ohrs, force

replace icode = lower(icode)
replace icnno = lower(icnno)

// drop non-study sites
merge m:1 icode using `2merge'
drop if _merge != 3
drop _merge
tab icode, nof
ret li
assert r(r) == 48

cap restore, not
cap drop unit
encode icnno, gen(unit)
saveold ${PATH_DATA}working_occupancy.dta, replace

// running median smoother over a week
use ${PATH_DATA}working_occupancy.dta, clear
collapse (max) occ_a_max = occupancy_active occ_d_max = occupancy ///
	, by(unit odate)
xtset unit odate, delta(1 day)
// non-linear smoothers don't work with panel data
qui su unit
local unit_max = r(max)
tempfile ddata
forvalues i = 1/`unit_max' {
	preserve
	keep if unit == `i'
	tssmooth nl occ_d_max7 = occ_d_max, smoother(7)
	tssmooth nl occ_a_max7 = occ_a_max, smoother(7)
	if `i' == 1 {
		save `ddata', replace
	}
	else {
		append using `ddata'
		save `ddata', replace
	}
	restore
}

use ${PATH_DATA}working_occupancy.dta, clear
merge m:1 unit odate using `ddata'
drop _merge
ren occ_d_max7 occupancy_pweek
label var occupancy_pweek "Median weekly physical occupancy"
ren occ_a_max7 occupancy_aweek
label var occupancy_aweek "Median weekly active occupancy"
drop occ_d_max occ_a_max

// xtset data
xtset unit otimestamp, delta(1 hour)

// NOTE: 2014-06-23 - existing definitions using reported CMP beds
gen open_beds_cmp = (cmp_beds_max - occupancy_active)
label var open_beds_cmp "Open beds with respect to CMP reported number"

gen physical_beds_cmp = (cmp_beds_max - occupancy)
label var physical_beds_cmp "Physical beds with respect to CMP reported number"

gen beds_none = open_beds_cmp <= 0
label var beds_none "Critical care unit full"
label values beds_none truefalse

gen beds_blocked = cmp_beds_max - occupancy <= 0
label var beds_blocked "Critical care unit unable to discharge"
label values beds_blocked truefalse

cap drop bed_pressure
gen bed_pressure = 0
label var bed_pressure "Bed pressure"
replace bed_pressure = 1 if beds_blocked == 1
replace bed_pressure = 2 if beds_none == 1
label define bed_pressure 0 "Beds available"
label define bed_pressure 1 "No beds but discharges pending", add
label define bed_pressure 2 "No beds and no discharges pending", add
label values bed_pressure bed_pressure

su beds_blocked beds_none

// NOTE: 2014-06-23 - new definition using max beds per month
gen open_beds_max = occupancy_max - occupancy_active
gen xbeds_none = (occupancy_max - occupancy_active) <= 0
gen xbeds_blocked = (occupancy_max - occupancy) <= 0
gen xbed_pressure = 0
label var xbed_pressure "Bed pressure (fr monthly max)"
replace xbed_pressure = 1 if xbeds_blocked == 1
replace xbed_pressure = 2 if xbeds_none == 1
label values xbed_pressure bed_pressure

// NOTE: 2014-06-23 - new definition using running weekly median
gen open_beds_med = occupancy_pweek - occupancy_active
gen mbeds_none = (occupancy_pweek - occupancy_active) <= 0
gen mbeds_blocked = (occupancy_pweek - occupancy) <= 0
gen mbed_pressure = 0
label var mbed_pressure "Bed pressure (fr wkly median)"
replace mbed_pressure = 1 if mbeds_blocked == 1
replace mbed_pressure = 2 if mbeds_none == 1
label values mbed_pressure bed_pressure

cap label drop room
label define room ///
	0 "None" ///
	1 "Some" ///
	2 "Lots"

// vs reported beds
cap drop room_cmp
gen room_cmp = .
label var room_cmp "Room_cmp in ICU"
replace room_cmp = 0 if open_beds_cmp <= 0
replace room_cmp = 1 if open_beds_cmp == 1
replace room_cmp = 2 if open_beds_cmp >= 2 & !missing(open_beds_cmp)
label values room_cmp room
tab room_cmp

// vs reported beds v2 
cap drop room_cmp2
gen room_cmp2 = .
label var room_cmp2 "Room_cmp2 in ICU"
replace room_cmp2 = 0 if open_beds_cmp <= 0
replace room_cmp2 = 1 if inlist(open_beds_cmp, 1, 2)
replace room_cmp2 = 2 if open_beds_cmp >= 3 & !missing(open_beds_cmp)
label values room_cmp2 room
tab room_cmp2

// vs reported beds: as above but using physical not active occupancy
cap drop room_physical
gen room_physical = .
label var room_physical "Room physical in ICU"
replace room_physical = 0 if physical_beds_cmp <= 0
replace room_physical = 1 if physical_beds_cmp == 1
replace room_physical = 2 if physical_beds_cmp >= 2 & !missing(physical_beds_cmp)
label values room_physical room
tab room_physical

// vs max monthly
cap drop room_max
gen room_max = .
label var room_max "Room_max in ICU"
replace room_max = 0 if open_beds_max <= 0
replace room_max = 1 if open_beds_max == 1
replace room_max = 2 if open_beds_max >= 2 & !missing(open_beds_max)
label values room_max room
tab room_max
// vs weekly median
cap drop room_med
gen room_med = .
label var room_med "Room_med in ICU"
replace room_med = 0 if open_beds_med <= 0
replace room_med = 1 if open_beds_med == 1
replace room_med = 2 if open_beds_med >= 2 & !missing(open_beds_med)
label values room_med room
tab room_med

*  ===========================================
*  = for the purposes of reporting occupancy =
*  ===========================================
gen full_physically0 = free_beds_cmp <= 0
label var full_physically0 "No physically empty beds"
gen full_physically1 = free_beds_cmp <= 1
label var full_physically1 "No more than 1 physically empty bed"

gen full_active0 = open_beds_cmp <= 0
label var full_active0 "No beds / None dischargable"
gen full_active1 = open_beds_cmp <= 1
label var full_active1 "No more than 1 dischargeable patient"


*  ========================
*  = Time and period vars =
*  ========================
cap drop ccadmx_tod
gen ccadmx_hour = hhC(otimestamp)
label var ccadmx_hour "Crit care admission - hour of day"
tab ccadmx_hour

cap drop ccadmx_dow
gen ccadmx_dow = dow(dofC(otimestamp))
label var ccadmx_dow "Crit Care admission - day of week"
label define dow ///
	0 "Sun" ///
	1 "Mon" ///
	2 "Tue" ///
	3 "Wed" ///
	4 "Thu" ///
	5 "Fri" ///
	6 "Sat"
label values ccadmx_dow dow
tab ccadmx_dow

* NOTE: 2013-01-11 - not sure that can make much of this given incomplete annual data
cap drop ccadmx_month
gen ccadmx_month = month(dofC(otimestamp))
label var ccadmx_month "Crit Care admission - month of year"
label define month ///
	1 	"Jan" ///
	2 	"Feb" ///
	3 	"Mar" ///
	4 	"Apr" ///
	5 	"May" ///
	6 	"Jun" ///
	7 	"Jul" ///
	8 	"Aug" ///
	9 	"Sep" ///
	10 	"Oct" ///
	11 	"Nov" ///
	12 	"Dec"
label values ccadmx_month month
tab ccadmx_month



* NOTE: 2013-05-02 - no free beds on the ICU 12% of the time
pwd
saveold ${PATH_DATA}working_occupancy.dta, replace



