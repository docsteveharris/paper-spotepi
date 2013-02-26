*  ======================================================
*  = Running do file for all numbers quoted in the text =
*  ======================================================

clear
cd ~/data/spot_early/vcode
use ../data/working.dta
qui include cr_preflight.do
count

* Results: sites
use ../data/working, clear
contract icode
tempfile 2merge
rename _freq patients
save `2merge', replace
use ../data/sites.dta, clear
merge 1:m icode using `2merge'
drop if _m == 1
duplicates drop icode, force
count
tab site_teaching
su studymonth_allreferrals, detail
su patients, detail

*  ==========================
*  = Tabulate CCOT activity =
*  ==========================
use ../data/working_postflight.dta, clear
keep if pickone_site
tab ccot_shift_pattern
* copy-past to /an_writing_chapter_ward.do
// not working nicely ... try listtex
contract ccot_shift_pattern, freq(n) percent(percent)
local sparkspike `x'
local _N = _N

gen tablerowlabel = ""
replace tablerowlabel = "No CCOT" if ccot_shift_pattern == 0
replace tablerowlabel = "< 7 days" if ccot_shift_pattern == 1
replace tablerowlabel = "< 24 hrs \texttimes 7 days" if ccot_shift_pattern == 2
replace tablerowlabel = "24 hrs \texttimes 7 days" if ccot_shift_pattern == 3


local sparkhbar_width 3pt
local sparkwidth 8
gen p = percent/100
sdecode p, format(%9.2fc) replace
gen sparkbar = `"\setlength{\sparklinethickness}{`sparkhbar_width'}\begin{sparkline}{`sparkwidth'}\spark 0.0 0.5 "' ///
	 + p + `" 0.5 / \end{sparkline}\setlength{\sparklinethickness}{0.2pt}"'

sdecode n, format(%9.0gc) replace
sdecode percent, format(%9.1fc) replace

local sparkspike_colour "\definecolor{sparkspikecolor}{gray}{0.7}"
local sparkline_colour "\definecolor{sparklinecolor}{gray}{0.7}"
local sparkspike_width "\renewcommand\sparkspikewidth{$sparkspike_width}"
global table_name ccot_shift_pattern
local justify X[6lb]X[rb]X[rb]X[lb]
* local tablefontsize "\footnotesize"
local arraystretch 1.0
local taburowcolors 2{white .. white}
local super_heading1 "Shift pattern & N & (\%) & \\"
/*
Use san-serif font for tables: so \sffamily {} enclosed the whole table
Add a label to the table at the end for cross-referencing
*/
listtex tablerowlabel n percent sparkbar ///
	using ../outputs/tables/$table_name.tex, ///
	replace rstyle(tabular) ///
	headlines( ///
		"`tablefontsize'" ///
		"\renewcommand{\arraystretch}{`arraystretch'}" ///
		"\taburowcolors `taburowcolors'" ///
		"`sparkspike_width'" ///
		"`sparkspike_colour'" ///
		"`sparkline_colour'" ///
		"\begin{tabu} {`justify'}" ///
		"\toprule" ///
		"`super_heading1'" ///
		"\midrule" ) ///
	footlines( ///
		"\bottomrule" ///
		"\end{tabu}   " ///
		"\label{$table_name} ") ///


*  ==================================
*  = Summarise site characteristics =
*  ==================================
use ../data/sites, clear
merge 1:m icode using ../data/working.dta, keepusing(icode)
duplicates drop icode, force
count
tab units_notincmp
tab units_notincmp_l3

/*
Royal Liverpool - the only one with L3 beds: this is a PACU
The others are Coronary Care or HDU beds
*/

* Results: patients
// CCMDS pre
use ../data/working_postflight.dta, clear
tab v_ccmds
tab rx_resp if v_ccmds == 2
tab rxcvs if v_ccmds == 2
tab rxrrt if v_ccmds == 2
cap drop organ_support
gen organ_support = (rx_resp > 1 | rxcvs > 1 | rxrrt > 0) & !missing(rx_resp, rxcvs, rxrrt)
tab v_ccmds organ_support, row col

*  =================================================
*  = Tabulate reported sepsis and sepsis diagnosis =
*  =================================================

use ../data/working_postflight.dta, clear
count
lookfor sepsis
tab sepsis
tab sepsis_site
tab sepsis_dx


contract sepsis_dx, freq(n) percent(percent)
sdecode n, format(%9.0gc) replace
sdecode percent, format(%9.1fc) replace
label list sepsis_dx
gsort -sepsis_dx
gen table_order = _n
sdecode sepsis_dx, gen(tablerowlabel)
replace tablerowlabel = "Sepsis unlikely/very unlikely" if sepsis_dx == 0
replace tablerowlabel = "Other/unspecified" if sepsis_dx == 1
replace tablerowlabel = "Genitourinary" if sepsis_dx == 2
replace tablerowlabel = "Gastrointestinal" if sepsis_dx == 3
replace tablerowlabel = "Respiratory" if sepsis_dx == 4
replace tablerowlabel =  "\hspace*{1em}\smaller[1]{" + tablerowlabel + "}" ///
	if sepsis_dx != 0
ingap 1
replace tablerowlabel = "Sepsis likely/very likely" if _n == 1

global table_name sepsis_reports
local justify lrl
local tablefontsize "\footnotesize"
local arraystretch 1.0
local taburowcolors 2{white .. white}
local super_heading1 "& N & (\%) \\"
/*
Use san-serif font for tables: so \sffamily {} enclosed the whole table
Add a label to the table at the end for cross-referencing
*/
listtex tablerowlabel n percent ///
	using ../outputs/tables/$table_name.tex, ///
	replace rstyle(tabular) ///
	headlines( ///
		"`tablefontsize'" ///
		"\renewcommand{\arraystretch}{`arraystretch'}" ///
		"\taburowcolors `taburowcolors'" ///
		"\sffamily{" ///
		"\begin{tabu} to " ///
		"\textwidth {`justify'}" ///
		"\toprule" ///
		"`super_heading1'" ///
		"\midrule" ) ///
	footlines( ///
		"\bottomrule" ///
		"\end{tabu} } " ///
		"\label{$table_name} " ///
		"\normalfont")


*  ===================
*  = Sepsis severity =
*  ===================
use ../data/working_postflight.dta, clear
count
tab sepsis_severity


contract sepsis_severity, freq(n) percent(percent)
sdecode n, format(%9.0gc) replace
sdecode percent, format(%9.1fc) replace
label list sepsis_severity
gsort -sepsis_severity
gen table_order = _n
sdecode sepsis_severity, gen(tablerowlabel)

global table_name sepsis_severity
local justify lrl
local tablefontsize "\footnotesize"
local arraystretch 1.0
local taburowcolors 2{white .. white}
local super_heading1 "& N & (\%) \\"
/*
Use san-serif font for tables: so \sffamily {} enclosed the whole table
Add a label to the table at the end for cross-referencing
*/
listtex tablerowlabel n percent ///
	using ../outputs/tables/$table_name.tex, ///
	replace rstyle(tabular) ///
	headlines( ///
		"`tablefontsize'" ///
		"\renewcommand{\arraystretch}{`arraystretch'}" ///
		"\taburowcolors `taburowcolors'" ///
		"\sffamily{" ///
		"\begin{tabu} to " ///
		"\textwidth {`justify'}" ///
		"\toprule" ///
		"`super_heading1'" ///
		"\midrule" ) ///
	footlines( ///
		"\bottomrule" ///
		"\end{tabu} } " ///
		"\label{$table_name} " ///
		"\normalfont")
