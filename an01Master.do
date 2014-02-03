// Prep the data
do cr_working.do
// this saves ../data/working.dta

use ../data/working.dta, clear
include cr_preflight.do
save ../data/working_postflight.dta, replace


use ../data/working_postflight.dta, clear
include cr_survival.do
save ../data/working_survival.dta, replace

do cr_working_sensitivity.do

use ../data/working.dta, clear
qui include cr_admitted_pts.do
save ../data/working_tails.dta, replace

