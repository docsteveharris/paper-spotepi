clear
include project_paths.do
cap log close
log using ${PATH_LOGS}cr_units.txt,  text replace
pwd

* ==================================
* = DEFINE LOCAL AND GLOBAL MACROS =
* ==================================
* local ddsn mysqlspot
* local uuser stevetm
* local ppass ""
local ddsn safe-knox
local uuser steve
local ppass "[po-09"
******************


*  ===================
*  = Site level data =
*  ===================

odbc query "`ddsn'", user("`uuser'") pass("`ppass'") verbose

clear
timer on 1
odbc load, exec("SELECT * FROM spotlight.unitsfinal")  dsn("`ddsn'") user("`uuser'") pass("`ppass'") lowercase sqlshow clear
timer off 1
timer list 1
compress
count
d

file open myvars using ../data/scratch/vars.yml, text write replace
foreach var of varlist * {
    di "- `var'" _newline
    file write myvars "- `var'" _newline
}
file close myvars


shell ../share/ccode/python/label_stata_fr_yaml.py "../data/scratch/vars.yml" "../share/specs/dictionary_fields.yml"

capture confirm file ../data/scratch/_label_data.do
if _rc == 0 {
    include ../data/scratch/_label_data.do
    shell  rm ../data/scratch/_label_data.do
    shell rm ../data/scratch/myvars.yml
}
else {
    di as error "Error: Unable to label data"
    exit
}

su _*
drop _*
saveold ${PATH_DATA}unitsFinal.dta, replace
* save ../data/unitsfinal.dta, replace

