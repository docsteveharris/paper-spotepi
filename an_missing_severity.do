*  =========================
*  = Missing severity data =
*  =========================

use ../data/working_postflight.dta, clear

// Prepare variables so appropriately labelled for severity scores
cap drop hr1
ren hrate hr1
label var hr1 "Heart rate - SPOT"

cap drop bps1
rename bpsys bps1
label var bps1 "SBP - SPOT"

cap drop temp1 
rename temperature temp1
label var temp1 "Temp - SPOT"

cap drop rr1
rename rrate rr1
label var rr1 "Resp rate - SPOT"

cap drop pf1 
replace pao2 = pao2 / 7.6 if abgunit == 2
gen pf1 = pao2 / abgfio2 * 100
label var pf1 "P:F ratio - SPOT"

cap drop ph1 
ren ph ph1
label var ph1 "pH - SPOT"

cap drop urea1 
ren urea urea1
label var urea1 "Urea - SPOT"

cap drop cr1
rename creatinine cr1
label var cr1 "Creatinine - SPOT"

ren sodium na1
label var na1 "Sodium - SPOT"
replace na1 = .a if na1 < 80

cap drop urin1 
rename uvol1h urin1

cap drop yulos
gen yulos = round(hours(cofd(ddicu) + tdicu - cofd(daicu) - taicu)) if dead_icu == 0
replace yulos = round(hours(cofd(dod) + tod - cofd(daicu) - taicu)) if dead_icu == 1
su yulos, d
label var yulos "ICU LOS (hrs)"
gen yulosd = round(yulos / 24, 0.1)
label var yulosd "ICU LOS"

replace urin1 = .a if urin1 > 250
label var urin1 "Urine ml/hr - SPOT"

cap drop wcc1
ren wcc wcc1
label var wcc1 "WCC - SPOT"

cap drop gcs1 
ren gcst gcs1
label var gcs1 "GCS - SPOT"

/* Lactate */
cap drop lac1 
ren lactate lac1
label var lac1 "Lactate - SPOT"

/* Platelets */
ren platelets plat1
label var plat1 "Platelets - SPOT"


/* Heart rate */
foreach var of varlist hr1  {
    cap drop `var'_wt
    gen `var'_wt = .
    replace `var'_wt = 14 if `var' <= 39
    replace `var'_wt = 0 if `var' <= 109 & `var'_wt == .
    replace `var'_wt = 1 if `var' <= 119 & `var'_wt == .
    replace `var'_wt = 2 if `var' <= 139 & `var'_wt == .
    replace `var'_wt = 3 if `var' > 139 & `var'_wt == .
    replace `var'_wt = . if `var' >= .
    bys `var'_wt: su `var'
}


/* BP systolic */
foreach var of varlist bps1  {
    cap drop `var'_wt
    gen `var'_wt = .
    replace `var'_wt = 15 if `var' <= 49 & `var'_wt == .
    replace `var'_wt = 9 if `var' <= 59 & `var'_wt == .
    replace `var'_wt = 6 if `var' <= 69 & `var'_wt == .
    replace `var'_wt = 4 if `var' <= 79 & `var'_wt == .
    replace `var'_wt = 2 if `var' <= 99 & `var'_wt == .
    replace `var'_wt = 0 if `var' <= 179 & `var'_wt == .
    replace `var'_wt = 7 if `var' <= 219 & `var'_wt == .
    replace `var'_wt = 16 if `var' > 219 & `var'_wt == .
    replace `var'_wt = . if `var' >= .
    bys `var'_wt: su `var'
}

/* Temperature */

foreach var of varlist temp1  {
    cap drop `var'_wt
    gen `var'_wt = .
    replace `var'_wt = 12 if `var' <= 33.9 & `var'_wt == .
    replace `var'_wt = 7 if `var' <= 35.9 & `var'_wt == .
    replace `var'_wt = 1 if `var' <= 38.4 & `var'_wt == .
    replace `var'_wt = 0 if `var' <= 41 & `var'_wt == .
    replace `var'_wt = 1 if `var' > 41 & `var'_wt == . & `var' != .
    // CHANGED: 2013-04-04 - replace missing and nonsense values with 0 weights
    bys `var'_wt: su `var'
}

/* Respiratory rate */
foreach var of varlist rr1  {
    cap drop `var'_wt
    gen `var'_wt = .
    replace `var'_wt = 1 if `var' <= 5 & `var'_wt == .
    replace `var'_wt = 0 if `var' < 12 & `var'_wt == .
    replace `var'_wt = 1 if `var' < 14 & `var'_wt == .
    replace `var'_wt = 2 if `var' < 25 & `var'_wt == .
    replace `var'_wt = 5 if `var' >= 25 & `var'_wt == .
    replace `var'_wt = . if `var' >= .
    bys `var'_wt: su `var'
}

/* P:F ratio */
// NOTE: 2013-04-04 - replace with room air / unintubated to generate weights
replace rxfio2 = 0 if rxfio2 == .
foreach var of varlist pf1 {
    cap drop `var'_wt
    gen `var'_wt = .
    replace `var'_wt = 6 if `var' <=    13 & !inlist(rxfio2,1,2,3) & `var'_wt == .
    replace `var'_wt = 3 if `var' <=    27 & !inlist(rxfio2,1,2,3) & `var'_wt == .
    replace `var'_wt = 0 if `var' >     27 & !inlist(rxfio2,1,2,3) & `var'_wt == .
    tab `var'_wt
    replace `var'_wt = 8 if `var' <=    13 & inlist(rxfio2,1,2,3) & `var'_wt == .
    replace `var'_wt = 5 if `var' <=    27 & inlist(rxfio2,1,2,3) & `var'_wt == .
    replace `var'_wt = 3 if `var' >     27 & inlist(rxfio2,1,2,3) & `var'_wt == .
    replace `var'_wt = . if `var' >= .
    tab `var'_wt
    bys `var'_wt: su `var'
}



/* pH */
foreach var of varlist ph1  {
    cap drop `var'_wt
    gen `var'_wt = .
    replace `var'_wt = 4 if `var' <= 7.14 & `var'_wt == .
    replace `var'_wt = 2 if `var' <= 7.24 & `var'_wt == .
    replace `var'_wt = 0 if `var' <= 7.32 & `var'_wt == .
    replace `var'_wt = 1 if `var' <= 7.49 & `var'_wt == .
    replace `var'_wt = 4 if `var' >  7.49 & `var'_wt == .
    replace `var'_wt = . if `var' >= .
    bys `var'_wt: su `var'
}

/* Urea */
foreach var of varlist urea1  {
    cap drop `var'_wt
    gen `var'_wt = .
    replace `var'_wt = 0 if `var' <= 6.1 & `var'_wt == .
    replace `var'_wt = 1 if `var' <= 7.1 & `var'_wt == .
    replace `var'_wt = 3 if `var' <= 14.3 & `var'_wt == .
    replace `var'_wt = 5 if `var' >  14.3 & `var'_wt == .
    replace `var'_wt = . if `var' >= .
    bys `var'_wt: su `var'
}

/* Creatinine */
foreach var of varlist cr1  {
    cap drop `var'_wt
    gen `var'_wt = .
    replace `var'_wt = 0 if `var' <= 0.5 * 88.4 & `var'_wt == .
    replace `var'_wt = 2 if `var' <= 1.5 * 88.4 & `var'_wt == .
    replace `var'_wt = 4 if `var' >  1.5 * 88.4 & `var'_wt == .
    replace `var'_wt = . if `var' >= .
    bys `var'_wt: su `var'
}

/* Sodium */

foreach var of varlist na1  {
    cap drop `var'_wt
    gen `var'_wt = .
    replace `var'_wt = 4 if `var' <= 129 & `var'_wt == .
    replace `var'_wt = 0 if `var' <= 149 & `var'_wt == .
    replace `var'_wt = 4 if `var' <= 154 & `var'_wt == .
    replace `var'_wt = 7 if `var' <= 160 & `var'_wt == .
    replace `var'_wt = 8 if `var' >  160 & `var'_wt == .
    replace `var'_wt = . if `var' >= .
    bys `var'_wt: su `var'
}

/* Urine */

foreach var of varlist urin1  {
    cap drop `var'_wt
    gen `var'_wt = .
    replace `var'_wt = 7 if `var' <= 399 / 24 & `var'_wt == .
    replace `var'_wt = 6 if `var' <= 599 / 24 & `var'_wt == .
    replace `var'_wt = 5 if `var' <= 899 / 24 & `var'_wt == .
    replace `var'_wt = 3 if `var' <= 1499 / 24 & `var'_wt == .
    replace `var'_wt = 1 if `var' <= 1999 / 24 & `var'_wt == .
    replace `var'_wt = 0 if `var' >  1999 / 24 & `var'_wt == .
    replace `var'_wt = . if `var' >= .
    bys `var'_wt: su `var'
}

/* White cell count */
foreach var of varlist wcc1  {
    cap drop `var'_wt
    gen `var'_wt = .
    replace `var'_wt = 6 if `var' <= 0.9 & `var'_wt == .
    replace `var'_wt = 3 if `var' <= 2.9 & `var'_wt == .
    replace `var'_wt = 0 if `var' <= 14.9 & `var'_wt == .
    replace `var'_wt = 2 if `var' <= 39.9 & `var'_wt == .
    replace `var'_wt = 4 if `var' >  39.9 & `var'_wt == .
    replace `var'_wt = . if `var' >= .
    bys `var'_wt: su `var'
}

/* GCS */
* NOTE: -11-15 - does not include the weighting for sedated or paralysed
foreach var of varlist gcs1  {
    cap drop `var'_wt
    // CHANGED: 2013-04-06 - default weight zero (but still missing if var is missing)
    gen `var'_wt = 0
    replace `var'_wt = 11 if `var' == 3 & `var'_wt == .
    replace `var'_wt = 9 if `var' == 4 & `var'_wt == .
    replace `var'_wt = 6 if `var' == 5 & `var'_wt == .
    replace `var'_wt = 4 if `var' == 6 & `var'_wt == .
    replace `var'_wt = 2 if `var' <= 13 & `var'_wt == .
    replace `var'_wt = 1 if `var' <= 14 & `var'_wt == .
    replace `var'_wt = 0 if `var' == 15 & `var'_wt == .
    replace `var'_wt = . if `var' >= .
    bys `var'_wt: su `var'
}


cap drop ims1_miss 
egen ims1_miss = rowmiss(*1_wt)
tab ims1_miss 

// now generate variables to report where sofa and news weights are missing
foreach var of varlist *1_wt {
    gen `var'_miss = `var' == .
}

gen sofa_haem_wt = 1
replace sofa_haem_wt = . if missing(plat1)
gen sofa_liver_wt = 1
replace sofa_liver_wt =. if missing(bili)

gen news_spo2_wt = 1
replace news_spo2_wt = . if missing(spo2)
gen news_fio2_wt = 1
replace news_fio2_wt = . if missing(fio2_std)

gen news_neuro_wt = 1
replace news_neuro_wt = . if missing(avpu) & missing(gcs1)

egen news_miss = rowmiss(news_fio2_wt news_neuro_wt news_spo2_wt hr1_wt bps1_wt rr1_wt temp1_wt )
egen sofa_miss = rowmiss(sofa_haem_wt sofa_liver_wt cr1_wt  gcs1_wt pf1_wt )

save ../data/scratch/scratch.dta, replace

* CHANGED: 2014-01-06 - 
* - Figure 3.6: re-draw figures with adjusted x-axis: 
* These plots will inevitably appear with a downward trend because you can only
* get a higher severity score if you're not missing data; they should be
* redrawn using the mean weight of the observed components not the overall total score.

// Now plot the amount of missing data by the ICNARC score
set scheme shbw
use ../data/scratch/scratch.dta, clear
foreach var of varlist *1_wt {
    replace `var' = . if `var'_miss == 1
}

egen icnarc_mean_wt = rowtotal(*1_wt) 
replace icnarc_mean_wt = icnarc_mean_wt / (13 - ims1_miss)
su icnarc_mean_wt

egen icnarc_k20 = cut(icnarc_mean_wt), at(0(0.5)10)
tab icnarc_k20

collapse (mean) ims1_miss (count) n = id, by(icnarc_k20)
list
* drop small categories and outliers
drop if icnarc_k20 >= 10
drop if n <= 20
gen zero = 0
gen x = icnarc_k20 + 0.25
tostring n, gen(barlabel) format(%9.0fc) force
tw ///
    (rbar ims1_miss zero x, barwidth(0.4) color(gs12)) ///
    (scatter ims1_miss x, msym(none) mlabel(barlabel) mlabpos(12) mlabcolor(gs2)) ///
    , ///
    ylabel(0(3)12) ///
    xlabel(0(1)4) ///
    ytitle("Number of missing components") ///
    xtitle("ICNARC score - mean component weight") ///
    subtitle("(C)", position(10) justification(left)) ///
    legend(off)

graph rename plot1, replace
* NOTE: 2014-01-14 - note low scores more often missing data
* and high scores (I assume GCS and non-vent RR)

// Now plot the amount of missing data by the SOFA score
use ../data/scratch/scratch.dta, clear
lookfor sofa
su sofa_score
tab sofa_miss

replace sofa_liver_wt = . if missing(bili)
replace sofa_haem_wt = . if missing(plat1)
gen sofa_resp_wt = sofa_r if !missing(pf1_wt)
gen sofa_renal_wt = sofa_k if !missing(cr1_wt)
gen sofa_neuro_wt = sofa_n if !missing(gcs1_wt)

egen sofa_mean_wt = rowtotal(sofa_haem_wt sofa_liver_wt sofa_resp_wt sofa_renal_wt sofa_neuro_wt)
su sofa_miss sofa_mean_wt
replace sofa_mean_wt = sofa_mean_wt / (5 - sofa_miss)
su sofa_mean_wt, d

egen sofa_mean_wt_k12 = cut(sofa_mean_wt), at(0(0.5)4)

collapse (mean) sofa_miss (count) n = id, by(sofa_mean_wt_k12)
drop if n <= 20
drop if sofa_mean_wt_k12 >= 3

gen zero = 0
gen x = sofa_mean_wt_k12 + 0.25
tostring n, gen(barlabel) format(%9.0fc) force
tw ///
    (rbar sofa_miss zero x, barwidth(0.4) color(gs12)) ///
    (scatter sofa_miss x, msym(none) mlabel(barlabel) mlabpos(12) mlabcolor(gs2)) ///
    , ///
    ylabel(0(1)6) ///
    xlabel(0(0.5)3) ///
    ytitle("Number of missing components") ///
    xtitle("SOFA score - mean component weight") ///
    subtitle("(B)", position(10) justification(left)) ///
    legend(off)

graph rename plot2, replace


// now for the NEWS score
use ../data/scratch/scratch.dta, clear
lookfor news
* Now manually calculate news weights
gen news_resp_wt = .
replace news_resp_wt = 0 if !missing(rr1)
replace news_resp_wt = 1 if (rr1 <= 11 ) & !missing(rr1)
replace news_resp_wt = 2 if (rr1 >= 21 ) & !missing(rr1)
replace news_resp_wt = 3 if (rr1 <= 8 | rr1 >= 25) & !missing(rr1)
su news_resp_wt


gen news_temp_wt = .
replace news_temp_wt = 0 if !missing(temp1)
replace news_temp_wt = 1 if (temp1 <= 36 | temp1 >= 38.1) & !missing(temp1)
replace news_temp_wt = 2 if (temp1 >= 39.1 ) & !missing(temp1)
replace news_temp_wt = 3 if (temp1 <= 35 ) & !missing(temp1)
su news_temp_wt

gen news_bps_wt = .
replace news_bps_wt = 0 if !missing(bps1)
replace news_bps_wt = 1 if (bps1 >= 110 ) & !missing(bps1)
replace news_bps_wt = 2 if (bps1 <= 100 ) & !missing(bps1)
replace news_bps_wt = 3 if (bps1 <= 90 | bps1 >= 220) & !missing(bps1)
su news_bps_wt

gen news_hr_wt = .
replace news_hr_wt = 0 if !missing(hr1)
replace news_hr_wt = 1 if (hr1 <= 50 | hr1 >= 91) & !missing(hr1)
replace news_hr_wt = 2 if (hr1 >= 111 ) & !missing(hr1)
replace news_hr_wt = 3 if (hr1 <= 40 | hr1 >= 131) & !missing(hr1)
su news_hr_wt

cap drop news_spo2_wt
gen news_spo2_wt = .
replace news_spo2_wt = 0 if !missing(spo2)
replace news_spo2_wt = 1 if (spo2 <= 95 ) & !missing(spo2)
replace news_spo2_wt = 2 if (spo2 <= 93 ) & !missing(spo2)
replace news_spo2_wt = 3 if (spo2 <= 91 ) & !missing(spo2)
su news_spo2_wt

cap drop news_avpu_wt
gen news_avpu_wt = .
replace news_avpu_wt = 0 if !missing(avpu)
replace news_avpu_wt = 3 if inlist(avpu,2,3,4) & !missing(avpu)
replace news_avpu_wt = 3 if gcs1 <= 13 & !missing(gcs1)
su news_avpu_wt

egen news_mean_wt = rowtotal(news_fio2_wt news_avpu_wt news_spo2_wt news_hr_wt news_bps_wt news_resp_wt news_temp_wt )
cap drop news_miss
egen news_miss = rowmiss(news_fio2_wt news_avpu_wt news_spo2_wt news_hr_wt news_bps_wt news_resp_wt news_temp_wt )
replace news_mean_wt = news_mean_wt / (7 - news_miss)
su news_mean_wt

egen news_k2 = cut(news_mean_wt), at(0(0.25)3)
collapse (mean) news_miss (count) n = id, by(news_k2)
list
drop if n <= 20
drop if news_k2 >= 2.5
gen zero = 0
gen x = news_k2 + 0.125
tostring n, gen(barlabel) format(%9.0fc) force
tw ///
    (rbar news_miss zero x, barwidth(0.2) color(gs12)) ///
    (scatter news_miss x, msym(none) mlabel(barlabel) mlabpos(12) mlabcolor(gs2)) ///
    , ///
    ylabel(0(1)7) ///
    xlabel(0(0.5)2.5) ///
    ytitle("Number of missing components") ///
    xtitle("NEWS score - mean component weight") ///
    subtitle("(A)", position(10) justification(left)) ///
    legend(off)

graph rename plot3, replace

graph combine plot3 plot2 plot1, cols(1) ysize(8) xsize(4)
graph rename aps_missing, replace
graph display aps_missing
graph export ../outputs/figures/aps_missing.pdf ///
    , name(aps_missing) replace


// quick calcs for writing
use ../data/scratch/scratch.dta, clear

