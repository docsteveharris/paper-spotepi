Steve Harris
Created 140227
These are notes on the analysis to be performed for the spot-epi paper.
The code here will largely come from the code used for spot_ward. In fact, it the directory is a branch published from the spot_ward repo.
For now, I have moved _all_ files into a subfolder called spot_ward so that I have a fresh start. I will then move the relevant files out one-by-one.

Log
===

140413
- sometime away from the project: reviewing the old notes

140328

- created a single record per patient survival data set by modifying cr_survival
    + see working_survival_single.dta
    + tried then running the laplace command in stata; nice because it directly estimates percentile survival; but I can't seem to pull out a random effect estimate for the site effect (fixed only)
- go back to estimating the median odds ratio; according to this [answer](http://www.stata.com/statalist/archive/2012-11/msg00307.html) it is not possible to derive a confidence interval for this (easily) in stata
    + exp(sqrt(2*V*invnormal(0.75)) where V is the random effects variance when the random effects are normally distributed
- median hazard ratio??
    + need to transform the above equation to work with the gamma distribution since this is used for the random effects in stata
        + frailty in stata has mean 1 (assumed) and variance \theta (which is estimated from the data)
    + the invnormal(0.75) term now needs to be replaced with the upper quartile from the an F distribution which has a numerator and denominator (2V,2V) (see ref [Bengtsson and Dribe, 2010, #60939] appendix) 

    * So to estimate the MHR you now need to
    local twoinvtheta2 = 2 / (e(theta)^2)
    local mhr = exp(sqrt(2*e(theta))*invF(`twoinvtheta2',`twoinvtheta2',0.75))
    di "MHR: `mhr'" 

- produced relative survival estimates using strel2 from LSHTM
- combined all this code into wr06_mortality.do


140324

- added in mortality section wr06_mortality.do
- ts_model_count_news_combine completed but stops before producing latex table and the output goes directly into a spreadsheet for formatting

140318

- re-run tb_model_ward_severity.do: works much better and figure no longer has Ulster as an outlier
- recreated hes_providers table in spot db after correcting the total admissions for Northern Ireland sites in the [original spreadsheet](/Users/steve/analysis/spot_study/data/DoH/140318_IS_HES_Providers_EWNI_compiled_by_hand.xls)
    - this meant re-running import_excel.py, index_table.py, and make_table.py
    - then re-creating the derived tables sites_within_hes and sites_early
    - then running cr_sites.do

140313

- corrected the tb_model_count_news_high model so that days without admissions are included
- corrected sites_early table by re-running make_table.py for
    + sites_within_hes
    + sites_within_cmpd
    + sites_early
    Now includes HES data for Wales and Northern Ireland

## 140311

- new system for analysis files: use wrXX_ prefix for results paragraphs in paper
- similarly
    + ts_ prefix for "table supplementary"
    + tb_ prefix for "table"
    + fs_ prefix for "figure supplementary"
    + fg_ prefix for "figure"


## 140227

- added back in all cr_* files. These will allow creation of the data set.
- I have not actually re-created all the data via SQL and Python code in /ccode
- source table in SQL is spot_early.working_early - connecting and downloading this table creates `working_raw.dta`
- STROBE diagram data checked and all working up to cr_working.do

