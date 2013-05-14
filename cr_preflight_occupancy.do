*  =============================================================
*  = Bring in the occupancy data and create standard variables =
*  =============================================================

clear
!cp ~/data/spot_study/data/working_occupancy24.dta ../data/working_occupancy24.dta
use ../data/working_occupancy24
replace icode = lower(icode)
d

gen open_beds_cmp = (cmp_beds_max - occupancy_active)
label var open_beds_cmp "Open beds with respect to CMP reported number"

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

* NOTE: 2013-05-02 - no free beds on the ICU 12% of the time
pwd
save ../data/working_occupancy.dta, replace
