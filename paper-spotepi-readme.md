Readme
======

Todo:
=====

- writing
	- model decision to admit as binary excluding patients with a treatment limitation order
		- tidying tasks
			- extract MOR @done(2015-12-10)
			- re-run with SOFA score to keep severity adjustment consistent
			- exclude patients with level 3 support  and replace v_ccmds_now with organ_support (soup)
			- redo exact OR in text after updating model
			- redo MOR excluding patient level factors
		- sensitivity models
			- full cohort without rxlimit exclusion
			- sensitivity using time2icu as the dependent var	
			- early admission as the dependent var instead
			- within subgroup with a recommendation for critical care
		- comment in text on
			- effect of occupancy
				- number of additional patients who would be predicted to be admitted were occupancy OK (overall, and amongst those recommended) 
			- inter site variability via MOR
				- translate into predicted admissions too?
	
	- finish with mortality model for decision to admit 
		- for all patients 
		- for patients recommended to critical care
		show similar outcomes, in discussion then comment on incomplete adjustment which sets up next paper
	- table comparing the three pathways



FIXME:
======

FIXME: 2015-11-27 - [ ] problem with stata connecting via ODBC; seems to hang; for now all prep files drop this and just copied in completed work
FIXME: 2015-11-27 - [ ] problem with waf; seem to need to run it twice for it to work

Log
===

2015-11-27
- now rewriting as per BMJ submission
- maybe introduce the ideas of patient groups to follow as per the rewrite in progress for paper-spotearly

140509
- there are patients in the sample that were admitted to ICU after one week (because they were permitted during the match) but I think my original intention was to match them but then replace their ICU admission time as missing
	+ done this today (70 patients) and corrected the text and the ICU admission numbers

140506
TRY - drop survival errors early so that you have the same number of patients in the initial analyses as you do in the survival analysis

140506
- Thought about include occupancy of ICU in severity models (at least to show that this _doesn't_ have an effect)? **No** -- leave this out for now: this should go into the survival and delay paper
- converted output of ts_model_count_combine_news.do from xls to csv

140505
- ts_model_ward_severity.do previously called tb_model_ward_severity.do: renamed
- modified ts_model_ward_severity.do so that it writes to a csv file which is then linked to the tables spreadsheet

140413
- added outsheet commands to table files in order that I can generate tables for publication from data
	- table 1a completed
    - table 1b completed
    - supp table 1 - site chars - completed
    - supp table 2 - incidence by news risk class - completed
- replaced all spot_ward references with mas_spotepi (incl those in vcode/spot_ward) so that I don't forget when working in the future with new transfers
- created wr08_sensitivity analysis

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

These are notes on the analysis to be performed for the spot-epi paper.
The code here will largely come from the code used for spot_ward. In fact, it the directory is a branch published from the spot_ward repo.
For now, I have moved _all_ files into a subfolder called spot_ward so that I have a fresh start. I will then move the relevant files out one-by-one.


Archive:
	- use data set up structure from paper-spotearly @now @done(2015-12-10)
		+ copied the prep folder and made the same @done(2015-12-10)
	- include occupancy @done(2015-12-08)
	- convert from room_cmp to room_cmp2 @done(2015-12-08)
	- exclude patients with Rx limits @done(2015-12-08)
	- basic summary in text @done(2015-12-02)
		✔ descriptive figure @done (15-12-02 13:38)
	- include description of patient groups as per draft from paper spot early  @done(2015-12-04)
		- show differences via stream graph which allows inspection of mortality  @done(2015-12-04)
		- facet stream graph by occupancy
		- repeat for those recommended for critical care
	- switch to waf or make file structure @done(2015-11-27)
	+ copied data folder and made the same @done(2015-11-27)
		+ symlinked the project_paths files from bld 
	- fix tb_model_count_news_high @done(2015-12-01)
		- problem with number of sites @done(2015-12-01)
		- check constant for IRR @done(2015-12-01)
	    - place under waf control @done(2015-12-01)
	* - [ ] TODO(2015-12-01): test code for figure count_news_high @done(2015-12-01)
	    - place under waf control @done(2015-12-01)