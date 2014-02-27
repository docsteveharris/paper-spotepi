*  =========================================================
*  = Produce tables summarising different severity metrics =
*  =========================================================

/*
- Sepsis severity
- NEWS severity
- Organ failure??
*/

* GenericSetupSteveHarris spot_ward an_tables_severity, logon
local clean_run 0
if `clean_run' == 1 {
	clear
	use ../data/working.dta
	qui include cr_preflight.do
}
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

// sparkbar code
local sparkhbar_width 3pt
local sparkwidth 8
gen p = percent/100
sdecode p, format(%9.2fc) replace
gen sparkbar = `"\setlength{\sparklinethickness}{`sparkhbar_width'}\begin{sparkline}{`sparkwidth'}\spark 0.0 0.5 "' ///
	 + p + `" 0.5 / \end{sparkline}\setlength{\sparklinethickness}{0.2pt}"'

sdecode n, format(%9.0gc) replace
sdecode percent, format(%9.1fc) replace

label list sepsis_dx
gsort -sepsis_dx
gen table_order = _n
sdecode sepsis_dx, gen(tablerowlabel)
replace tablerowlabel = "Unlikely+" if sepsis_dx == 0
replace tablerowlabel = "Other/unspecified" if sepsis_dx == 1
replace tablerowlabel = "Genitourinary" if sepsis_dx == 2
replace tablerowlabel = "Gastrointestinal" if sepsis_dx == 3
replace tablerowlabel = "Respiratory" if sepsis_dx == 4
replace tablerowlabel =  "\hspace*{1em}\smaller[1]{" + tablerowlabel + "}" ///
	if sepsis_dx != 0
ingap 1
replace tablerowlabel = "Likely+" if _n == 1

global table_name sepsis_reports
local justify X[7lb]X[rb]X[rb]X[lb]
* local tablefontsize "\scriptsize"
local arraystretch 1.0
local taburowcolors 2{white .. white}
local super_heading1 "Sepsis & N & (\%) & \\"

listtex tablerowlabel n percent sparkbar ///
	using ../outputs/tables/$table_name.tex, ///
	replace rstyle(tabular) ///
	headlines( ///
		"`tablefontsize'" ///
		"\renewcommand{\arraystretch}{`arraystretch'}" ///
		"\taburowcolors `taburowcolors'" ///
		"\begin{tabu} {`justify'}" ///
		"\toprule" ///
		"`super_heading1'" ///
		"\midrule" ) ///
	footlines( ///
		"\bottomrule" ///
		"\end{tabu} " ///
		"\label{tab:$table_name} ")


*  ===================
*  = Sepsis severity =
*  ===================
use ../data/working_postflight.dta, clear
count
tab sepsis_severity


contract sepsis_severity, freq(n) percent(percent)

// sparkbar code
local sparkhbar_width 3pt
local sparkwidth 8
gen p = percent/100
sdecode p, format(%9.2fc) replace
gen sparkbar = `"\setlength{\sparklinethickness}{`sparkhbar_width'}\begin{sparkline}{`sparkwidth'}\spark 0.0 0.5 "' ///
	 + p + `" 0.5 / \end{sparkline}\setlength{\sparklinethickness}{0.2pt}"'

sdecode n, format(%9.0gc) replace
sdecode percent, format(%9.1fc) replace

gsort -sepsis_severity
gen table_order = _n
sdecode sepsis_severity, gen(tablerowlabel)
label list sepsis_severity
replace tablerowlabel = "None" if sepsis_severity == 0

global table_name sepsis_severity
local justify X[7lb]X[rb]X[rb]X[lb]
* local tablefontsize "\scriptsize"
local arraystretch 1.0
local taburowcolors 2{white .. white}
local super_heading1 "Sepsis severity & N & (\%) & \\"

listtex tablerowlabel n percent sparkbar ///
	using ../outputs/tables/$table_name.tex, ///
	replace rstyle(tabular) ///
	headlines( ///
		"`tablefontsize'" ///
		"\renewcommand{\arraystretch}{`arraystretch'}" ///
		"\taburowcolors `taburowcolors'" ///
		"\begin{tabu} {`justify'}" ///
		"\toprule" ///
		"`super_heading1'" ///
		"\midrule" ) ///
	footlines( ///
		"\bottomrule" ///
		"\end{tabu} " ///
		"\label{tab:$table_name} ")


*  =============
*  = NEWS risk =
*  =============
use news_risk using ../data/working_postflight.dta, clear
contract news_risk, freq(n) percent(percent)
gsort -news_risk
gen table_order = _n

// sparkbar code
local sparkhbar_width 3pt
local sparkwidth 8
gen p = percent/100
sdecode p, format(%9.2fc) replace

gen sparkbar = `"\setlength{\sparklinethickness}{`sparkhbar_width'}\begin{sparkline}{`sparkwidth'}\spark 0.0 0.5 "' ///
	 + p + `" 0.5 / \end{sparkline}\setlength{\sparklinethickness}{0.2pt}"'

sdecode n, format(%9.0gc) replace
sdecode percent, format(%9.1fc) replace
sdecode news_risk, gen(tablerowlabel)

global table_name severity_news_risk
local justify X[7lb]X[rb]X[rb]X[lb]
* local tablefontsize "\scriptsize"
local arraystretch 1.0
local taburowcolors 2{white .. white}
local super_heading1 "NEWS Risk & N & (\%) & \\"

listtex tablerowlabel n percent sparkbar ///
	using ../outputs/tables/$table_name.tex, ///
	replace rstyle(tabular) ///
	headlines( ///
		"`tablefontsize'" ///
		"\renewcommand{\arraystretch}{`arraystretch'}" ///
		"\taburowcolors `taburowcolors'" ///
		"\begin{tabu} {`justify'}" ///
		"\toprule" ///
		"`super_heading1'" ///
		"\midrule" ) ///
	footlines( ///
		"\bottomrule" ///
		"\end{tabu} " ///
		"\label{tab:$table_name} ")


cap log close