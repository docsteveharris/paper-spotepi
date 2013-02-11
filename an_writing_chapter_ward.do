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

use ../data/working_postflight.dta, clear
keep if pickone_site
tab ccot_shift_pattern
* copy-past to /an_writing_chapter_ward.do
// not working nicely ... try listtex
contract ccot_shift_pattern, freq(n) percent(percent)
sdecode n, format(%9.0gc) replace
sdecode percent, format(%9.1fc) replace

global table_name ccot_shift_pattern
local justify lrl
local tablefontsize "\footnotesize"
local arraystretch 1.0
local taburowcolors 2{white .. white}
local super_heading1 "& N & (\%) \\"
/*
Use san-serif font for tables: so \sffamily {} enclosed the whole table
Add a label to the table at the end for cross-referencing
*/
listtex ccot_shift_pattern n percent ///
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


