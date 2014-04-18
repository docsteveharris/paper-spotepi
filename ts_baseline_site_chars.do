* Steve Harris 
* Created 140311

* Log
* ===
* 140311	- adatped from spot_ward/vcode/an_tables_baseline_sites


GenericSetupSteveHarris mas_spotepi ts_tables_baseline_sites, logon

*  ===========================================================
*  = Pull together data from all patients at all study sites =
*  ===========================================================
clear
use ../data/working_raw.dta
keep icode dorisname allreferrals site_quality_q1
gsort icode dorisname -allreferrals
egen pickone = tag(icode)
drop if pickone == 0
count
tempfile working
save `working', replace

preserve
use ../data/working_all,clear
keep icode idvisit include exclude1-exclude3 filled_fields_count _valid_allfields
rename _valid_allfields valid_allfields
gen analysed = include == 1 & exclude1 == 0 & exclude2 == 0 & exclude3 == 0
label var analysed "Patient to analyse"
collapse ///
	(mean) filled_fields_count valid_allfields ///
	(count) n = include ///
	(sum) include exclude1-exclude3 analysed, ///
	by(icode)

replace valid_allfields = round(100 * valid_allfields)

gen crf_completeness = round(filled_fields_count / 48 * 100)
label var crf_completeness "Median percentage of CRF completed"
label var exclude1 "Exclude - by design"
label var exclude2 "Exclude - by choice"
label var exclude3 "Exclude - lost to follow-up"

tempfile 2merge
save `2merge',replace
restore

merge 1:1 icode using `2merge'
drop _m pickone

merge 1:1 icode using ../data/sites.dta
sort dorisname
drop _m

* Now merge in patients and months used
preserve
use icode using ../data/working_postflight.dta, clear
contract icode
rename _freq n
merge 1:1 icode using ../data/sites.dta
keep if _merge == 3
drop _merge

* CHANGED: 2014-03-13 - add in a measure of ICU throughput
gen cmp_throughput = cmp_patients_permonth / cmp_beds_persite
label var cmp_throughput "CMP patients per bed per month"

* Q: Patients per hospital
gen hes_overnight = hes_admissions - hes_daycase
gen n_per_hes_overnight = n / hes_overnight * 1000
su n_per_hes_overnight

tempfile 2merge
save `2merge',replace
restore

merge 1:1 icode using `2merge'
drop _merge

preserve
use icode studymonth using ../data/working_postflight.dta, clear
contract icode studymonth
drop _freq
contract icode
rename _freq studymonths
su studymonths, d

tempfile 2merge
save `2merge',replace
restore

merge 1:1 icode using `2merge'
drop _merge


*  =============================
*  = Now prepare summary table =
*  =============================
/*
- 1 row per site
*/

cap drop hes_overnight
gen hes_overnight = hes_admissions - hes_daycase
label var hes_overnight "HES (overnight) admissions"
cap drop allreferrals_site
gen allreferrals_site = include > 0 & include != .
cap drop hes_emergencies_percent
gen hes_emergencies_percent = round(hes_emergencies / hes_overnight * 100)
cap drop hes_overnight_1000
gen hes_overnight_1000 = round(hes_overnight / 1000)
cap drop simple_site
gen simple_site = all_cc_in_cmp == 1 & tails_othercc == 0
label var simple_site "All critical care provided in CMP units"

local table_vars icode dorisname hes_overnight_1000 ///
	hes_emergencies_percent ///
	ccot_shift_pattern ///
	cmp_beds_persite ///
	simple_site ///
	cmp_patients_permonth ///
	tails_all_percent ///
	exclude1 exclude2 exclude3 ///
	crf_completeness ///
	valid_allfields ///
	n n_per_hes_overnight  studymonths ///
	cmp_throughput site_teaching


order `table_vars'
br `table_vars' if allreferrals_site == 1
keep if allreferrals_site == 1
save ../outputs/tables/$table_name.dta, replace

* CHANGED: 2013-01-25 - now export directly to latex

cap restore, not
preserve
local vars icode ///
	 hes_overnight_1000 ///
	 hes_emergencies_percent ///
	 ccot_shift_pattern cmp_beds_persite ///
	 cmp_patients_permonth ///
	 tails_all_percent
keep `vars'
sort icode
* Convert to string var
foreach var of local vars {
	cap confirm string var `var'
	if !_rc continue
	sdecode `var', replace
}
chardef `vars', ///
	char(varname) ///
	prefix("\textit{") suffix("}") ///
	values( ///
		"Site code" ///
		"Hospital overnight admissions (1000's/yr)" ///
		"Emergency admissions (\%)" ///
		"Critical care outreach" ///
		"Critical care beds" ///
		"Critical care admissions (per month)" ///
		"Emergency ward admissions to critical care (\%)" ///
		)


listtab_vars `vars', ///
	begin("") delimiter("&") end(`"\\"') ///
	substitute(char varname) ///
	local(h1)

global table_name baseline_sites_chars
local justify X[l]X[m]X[m]X[3m]X[m]X[m]X[m]
local tablefontsize "\scriptsize"
local arraystretch 1.0
local taburowcolors 2{white .. gray90}
/*
NOTE: 2013-01-28 - needed in the pre-amble for colors
\usepackage[usenames,dvipsnames,svgnames,table]{xcolor}
\definecolor{gray90}{gray}{0.9}
*/

listtab `vars' ///
	using ../outputs/tables/$table_name.tex, ///
	replace rstyle(tabular) ///
	headlines( ///
		"`tablefontsize'" ///
		"\renewcommand{\arraystretch}{`arraystretch'}" ///
		"\sffamily{" ///
		"\taburowcolors `taburowcolors'" ///
		"\begin{tabu} spread " ///
		"\textwidth {`justify'}" ///
		"\toprule" ///
		"`h1'" ///
		"\midrule" ) ///
	footlines( ///
		"\bottomrule" ///
		"\end{tabu} } " ///
		"\label{$table_name} " ///
		"\normalfont" ///
		"\normalsize")

save ../outputs/tables/baseline_sites_chars.dta, replace

* Export to excel then import this as a 'raw' table into the master tables spreadsheet
* For each raw table, derive a formatted final table for publication
export excel using "../outputs/tables/ts_$table_name.xls", ///
	 firstrow(variables) replace

outsheet using "../outputs/tables/ts_$table_name.csv", ///
	 replace comma
restore



