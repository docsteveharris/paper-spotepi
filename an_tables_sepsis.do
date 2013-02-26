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
replace tablerowlabel = "Unlikely +" if sepsis_dx == 0
replace tablerowlabel = "Other/unspecified" if sepsis_dx == 1
replace tablerowlabel = "Genitourinary" if sepsis_dx == 2
replace tablerowlabel = "Gastrointestinal" if sepsis_dx == 3
replace tablerowlabel = "Respiratory" if sepsis_dx == 4
replace tablerowlabel =  "\hspace*{1em}\smaller[1]{" + tablerowlabel + "}" ///
	if sepsis_dx != 0
ingap 1
replace tablerowlabel = "Likely +" if _n == 1

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
