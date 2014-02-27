* Steve Harris
* Example code from references below
* [Silcocks, 2009, #39146]
* Silcocks P. Hazard ratio funnel plots for survival comparisons. J Epidemiol Community Health. 2009;63:856-861.

/*

Appendix 2: Stata Code


Stata example code to create centred log hazard ratios and obtain funnel plots. In the example data set the institutions 

to be compared are denoted by the variable "centre", and the observations have been age-stratified into the variable "group".

The stratification variable in the example dataset can be ageband (equal cases/band) or agebandd (equal deaths/band)

The basic, overdispersed and overdispersed (Winsorised) plots are produced and saved automatically in the current directory

The metabias Stata add-on needs to be installed for evaluation of asymmetry 


*/ 

clear

set mem 50m
set more off

cd Z:\PaulS\Funnel_Bak\Final_Resub

use "Z:\PaulS\Funnel_Bak\Final_Resub\Final_LA_Example.dta", clear

quietly {

local Wval = 0.2
local group = "agebandd"

if "`group'" == "ageband" {
  local K = "eqC"
  }

if "`group'" == "agebandd" {
  local K = "eqD"
  }

  local G1 = "`K'"+"LA_Funnel_Basic"
  local G2 = "`K'"+"egger_plot_raw"
  local G3 = "`K'"+"LA_Funnel_OD"
  local G4 = "`K'"+"egger_plot_od"
  local G5 = "`K'"+"LA_Funnel_W"
  local G6 = "`K'"+"egger_plot_W"

 /* perform Cox regression */
xi: stcox i.centre, strata(`group')

/* extract coefficient vector and transpose into column vector */
matrix B = e(b)
matrix B = B'


/* create augmented coefficient vector to include reference category with value equal to zero */
local rows = rowsof(B)+1
matrix Bplus = J(`rows',1,0)
matrix Bplus[2,1]=B     
svmat Bplus   


/* create transformation matrix to centre regression coefficients on zero */
matrix Jt = J(`rows',`rows',1)/`rows'
matrix I = I(`rows')
matrix T = (I - Jt)

/* centre regression coefficients and transform covariance matrix */
matrix newB = T*Bplus
svmat newB
rename newB1 CtrB     /* CtrB is the vector of centred log hazard ratios ) */


/* extract covariance matrix |H1 */
matrix V = e(V)

/* likewise create augmented covariance matrix |H1 with first row and column values equal to zero */
matrix Vplus= J(`rows',`rows',0)
matrix Vplus[2,2] = V

/* create transformation matrix to centre regression coefficients */
matrix Jt = J(`rows',`rows',1)/`rows'
matrix I = I(`rows')
matrix T = (I - Jt)

/* Transform covariance matrix |H1 */
matrix newV = T*Vplus*T'
matrix newB = T*Bplus

/* extract variances|H1 of centred coefficients and save original and new coefficients */
matrix S2 = vecdiag(newV)'
svmat S2
replace S21 = sqrt(S21)   /* needed for meta-analysis plots */


/*  obtain covariance matrix under H0  using logrank test (option gives covariance covariance matrix of the score under H0) */
sts test centre, strata(`group') mat(U V0)   

/* estimate overdispersion */
scalar df = r(df)
scalar phi =  r(chi2)/df
scalar phi = max(1, phi)

/* Obtain covariance matrix |H0 for regression coefficients */
matrix V0=inv(V0[2..`rows',2..`rows'])   /* NB VLR is singular - need to drop first row and column before inverting */
matrix V0plus= J(`rows',`rows',0)
matrix V0plus[2,2] = V0

/* transform H0 covariance matrix */
matrix newV0 = T*V0plus*T'

/* extract H0 variances of centred coefficients and save */
matrix S02 = vecdiag(newV0)'
svmat S02


/* get z score & estimate overdispersion from Winsorised z score  */
matrix U0 = U[1,2..`rows']
matrix U0 = U0'
matrix rtV = cholesky(V0)

matrix c2 = rtV'*U0
svmat c2                            /* into variable c21 */

rename c21 z_score
summ z_score

local Wlo = 100*`Wval'/2
local Whi = 100*(1-`Wval'/2)
_pctile z_score,  percentile(`Wlo', `Whi')   /* these are the percentiles for Winsorising */

gen z_score_W = z_score
replace z_score_W = r(r2) if z_score_W>r(r2) & z_score ~=.
replace z_score_W = r(r1) if z_score_W<r(r1) & z_score ~=.
gen z_score_W_sqd = z_score_W^2
egen S_zW2 = sum(z_score_W_sqd)
scalar phiW = S_zW2/df

scalar phi = max(1, phi) 
scalar phiW = max(1, phiW)


/* =================================== */

/* Calculate control limits */
gen LCtrlL95 = -1.96*sqrt(S021)
gen UCtrlL95 =  1.96*sqrt(S021)

gen LCtrlL99 =  -2.576*sqrt(S021)
gen UCtrlL99 =   2.576*sqrt(S021)

gen ODLCtrlL95 = -1.96*sqrt(phi*S021)
gen ODUCtrlL95 =  1.96*sqrt(phi*S021)

gen ODLCtrlL99 =  -2.576*sqrt(phi*S021)
gen ODUCtrlL99 =   2.576*sqrt(phi*S021)

gen ODLWCtrlL95 = -1.96*sqrt(phiW*S021)
gen ODUWCtrlL95 =  1.96*sqrt(phiW*S021)

gen ODLWCtrlL99 =  -2.576*sqrt(phiW*S021)
gen ODUWCtrlL99 =   2.576*sqrt(phiW*S021)


keep if CtrB~=.
replace centre = _n

/* lines to exclude observation for meta-analysis */
gen abs_dev = abs(CtrB)
egen minabs_dev = min(abs_dev)
gen use = 1 
replace use = 0 if abs_dev == minabs_dev
drop abs_dev minabs_dev

gen Precision = 1/S021    /* precision measure for plotting */

/* meta-analysis for bias: omits centre with coefficient closest to zero (to ensure independence) */
gen var_H0 = S021
gen var_H0_od = phi*S021
gen var_H0_W = phiW*S021

} /* <----- end of quietly loop */

/* ============ Plotting =============== */

/* Raw plot */
twoway (scatter CtrB Precision , sort mcolor(black)  mlabcolor(black) /// 
 mlabel(centre) ylabel(#10) )  ///
(line LCtrlL95 Precision , sort lcolor(black) lpattern(solid)) ///
 (line UCtrlL95 Precision , sort lcolor(black) lpattern(solid)) ///
 (line LCtrlL99 Precision, sort lcolor(black) lpattern(dash)) ///
 (line UCtrlL99 Precision , sort lcolor(black) lpattern(dash)),  ///
scheme(s1mono) saving("`G1'", replace)

metabias CtrB var_H0 if use ==1, var graph( egger) saving("`G2'", replace)       


/* Allowing for overdispersion */
twoway (scatter CtrB Precision , sort mcolor(black)  mlabcolor(black) /// 
 mlabel(centre) ylabel(#10) )  ///
(line ODLCtrlL95 Precision , sort lcolor(black) lpattern(solid)) ///
 (line ODUCtrlL95 Precision , sort lcolor(black) lpattern(solid)) ///
 (line ODLCtrlL99 Precision, sort lcolor(black) lpattern(dash)) ///
 (line ODUCtrlL99 Precision , sort lcolor(black) lpattern(dash)),  ///
scheme(s1mono) saving("`G3'", replace)

metabias CtrB var_H0_od if use ==1, var graph( egger) saving("`G4'", replace)       



/* Winsorised over-dispersed */
twoway (scatter CtrB Precision , sort mcolor(black)  mlabcolor(black) /// 
 mlabel(centre) ylabel(#10) )  ///
(line ODLWCtrlL95 Precision , sort lcolor(black) lpattern(solid)) ///
 (line ODUWCtrlL95 Precision , sort lcolor(black) lpattern(solid)) ///
 (line ODLWCtrlL99 Precision, sort lcolor(black) lpattern(dash)) ///
 (line ODUWCtrlL99 Precision , sort lcolor(black) lpattern(dash)),  ///
scheme(s1mono) saving("`G5'", replace)

metabias CtrB var_H0_W if use ==1, var graph( egger) saving("`G6'", replace)


display "Phi = " phi ", PhiW = " phiW "  K = " "`K'"