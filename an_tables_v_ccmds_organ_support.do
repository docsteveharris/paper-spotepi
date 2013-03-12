*  ===========================================
*  = Table of organ support by level of care =
*  ===========================================

use ../data/working_postflight.dta, clear
tab v_ccmds
tab rxcvs, gen(rxcvs_)
tab rx_resp, gen(rxresp_)
tab rxrrt, gen(rxrrt_)
collapse 	(sum) rxrrt_2 rxcvs_2 rxcvs_3 rxresp_2 rxresp_3 ///
			(count) id ///
			,  by(v_ccmds)
xpose, clear varname
drop v5

rename _varname varname
gen tablerowlabel = ""
replace tablerowlabel = "Renal replacement therapy" if varname == "rxrrt_2"
replace tablerowlabel = "Fluid resuscitation" if varname == "rxcvs_2"
replace tablerowlabel = "Vasopressors / Inotropes" if varname == "rxcvs_3"
replace tablerowlabel = "Supplemental oxygen" if varname == "rxresp_2"
replace tablerowlabel = "Non-invasive ventilation" if varname == "rxresp_3"
replace tablerowlabel = "Patients" if varname == "id"

order varname tablerowlabel v1-v4
local finalrow "Patients"
forvalues i = 1/4 {
	sdecode v`i', format(%9.0fc) replace
	local thistotal = v`i'[_N]
	local finalrow = "`finalrow' & `thistotal'"
}
local finalrow = "`finalrow' \\"
di "`finalrow'"

drop if varname == "v_ccmds"
drop if varname == "id"

gen tableorder = 0
replace tableorder = 1 if _n == 4
replace tableorder = 2 if _n == 2
replace tableorder = 3 if _n == 3
replace tableorder = 4 if _n == 5
replace tableorder = 5 if _n == 1
sort tableorder


global table_name v_ccmds_organ_support
local justify lllll
local arraystretch 1.0
local taburowcolors 2{white .. white}
local super_heading1 "& Level 0 & Level 1 & Level 2 & Level 3 \\"
/*
Use san-serif font for tables: so \sffamily {} enclosed the whole table
Add a label to the table at the end for cross-referencing
*/
listtex tablerowlabel v1-v4 ///
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
		"\midrule"  ///
		"`finalrow'"  ///
		"\bottomrule" ///
		"\end{tabu}   " ///
		"\label{tab:$table_name} ") ///


