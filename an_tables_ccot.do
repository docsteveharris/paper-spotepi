*  ==========================
*  = Tabulate CCOT activity =
*  ==========================

use ../data/working_postflight.dta, clear
keep if pickone_site
tab ccot_shift_pattern

* copy-past to /an_writing_chapter_ward.do
// not working nicely ... try listtex

destring ccot_senior, replace
collapse ///
	(count) n = id ///
	(median) v_est = patients_perhesadmx ///
	(p25) v_p25 = patients_perhesadmx ///
	(p75) v_p75 = patients_perhesadmx ///
	(mean) ccot_consultant ///
	(median) ccot_senior ///
	, ///
	by(ccot_shift_pattern)
egen sites = total(n)
gen percent = n / sites * 100
su v_*

gen tablerowlabel = ""
replace tablerowlabel = "No CCOT" if ccot_shift_pattern == 0
replace tablerowlabel = "< 7 days" if ccot_shift_pattern == 1
replace tablerowlabel = "< 24 hrs/day \texttimes 7 days" if ccot_shift_pattern == 2
replace tablerowlabel = "24 hrs/day \texttimes 7 days" if ccot_shift_pattern == 3


local sparkhbar_width 3pt
local sparkwidth 8
gen p = percent/100
sdecode p, format(%9.2fc) replace
gen sparkbar = `"\setlength{\sparklinethickness}{`sparkhbar_width'}\begin{sparkline}{`sparkwidth'}\spark 0.0 0.5 "' ///
	 + p + `" 0.5 / \end{sparkline}\setlength{\sparklinethickness}{0.2pt}"'

sdecode n, format(%9.0gc) replace
sdecode percent, format(%9.1fc) replace
sdecode v_est, format(%9.1fc) replace
sdecode v_p25, format(%9.1fc) replace
sdecode v_p75, format(%9.1fc) replace
gen v_iqr = v_p25 + "--" + v_p75
replace ccot_consultant = 100 * ccot_consultant
sdecode ccot_consultant, format(%9.0fc) replace
order tablerowlabel n percent sparkbar ccot_consultant v_iqr

* replace v_iqr = "" if ccot_shift_pattern == 0
* replace v_est = "" if ccot_shift_pattern == 0
replace ccot_consultant = "---" if ccot_shift_pattern == 0

local sparkspike_colour "\definecolor{sparkspikecolor}{gray}{0.7}"
local sparkline_colour "\definecolor{sparklinecolor}{gray}{0.7}"
local sparkspike_width "\renewcommand\sparkspikewidth{$sparkspike_width}"
global table_name ccot_shift_pattern
* local justify spread \textwidth {X[4rb] X[rb] X[rb] X[2rb] X[2rb] X[2lb]}
local justify "{rllllrl}"
local tablefontsize "\scriptsize"
local arraystretch 1.0
local taburowcolors 2{white .. white}
local super_heading1 "&     \multicolumn{2}{p{2cm}}{\centering Sites} & \multicolumn{1}{p{1.5cm}}{\centering Consultant cover}      & \multicolumn{2}{p{2cm}}{\centering Visits (per 1000 admissions)} \\"
local super_heading2 "Shift pattern & No. & (\%) &                  (\%) & Median & (IQR)                                \\"
/*
Use san-serif font for tables: so \sffamily {} enclosed the whole table
Add a label to the table at the end for cross-referencing
*/
listtex tablerowlabel n percent ccot_consultant v_est v_iqr ///
	using ../outputs/tables/$table_name.tex, ///
	replace rstyle(tabular) ///
	headlines( ///
		"`tablefontsize'" ///
		"\renewcommand{\arraystretch}{`arraystretch'}" ///
		"\taburowcolors `taburowcolors'" ///
		"`sparkspike_width'" ///
		"`sparkspike_colour'" ///
		"`sparkline_colour'" ///
		"\begin{tabular}`justify'" ///
		"\toprule" ///
		"`super_heading1'" ///
		"\cmidrule(rl){2-3} \cmidrule(rl){4-4} \cmidrule(rl){5-6}" ///
		"`super_heading2'" ///
		"\midrule" ) ///
	footlines( ///
		"\bottomrule" ///
		"\end{tabular}   " ///
		"\label{$table_name} ")


* Now show the distribution of monthly visits by ccot_shift_pattern
use ../data/working_postflight.dta, clear
keep if pickone_site
regress patients_perhesadmx ccot_shift_pattern
dotplot patients_perhesadmx , ///
	 over(ccot_shift_pattern) center ///
	 xlabel(0 "None" 1 "<7 days" 2 "7 days" 3 "24h x7 days" ) ///
	 xtitle("CCOT shift pattern", margin(medium)) ///
	 ytitle("Patients per 1,000 hosp. adm.") ///
	 xsize(6) ysize(6) ///
	 name(pts_by_ccot, replace)

graph export ../outputs/figures/pts_by_ccot.pdf ///
    , name(pts_by_ccot) replace


