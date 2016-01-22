# Paper Spot Epi 

Avoiding all analyses of the 'effectiveness' of ICU (i.e. effect of decision to admit, or early admission)
Factors affecting outcome for patients _not_ admitted
Examining the effect of occupancy
	- in the frailty model allows for confounding by hospital
	- but removes the effect of hospital	that operates _through_ occupancy
Recast results to emphasise interest in outcomes of patients referred to and not immediately admitted (esp. those with a recommendation for critical care)

inbox:
	- double check occupancy order in markdown now you have re-levelled room_cmp2 

@continue:
	- one tricky later paragraph
	- see @resume tag below
		- tidy up decision models to use cleaner set of predictors as per mortality model

@next:
	- redo predictors
			- add in time-varying covariates to survival models
			- drop site level predictors except from incidence model
				- simplify site level predictors (drop ?emergency admissions, CMP throughput) ... or just remove through out
			- switch to ccmds 2 or 3 (now) (back from osupp)
	- bootstrap CI 
		- check/read about which SE to use after bootstrap (simple vs ...)
			at present assuming central limit theorem holds and sampling by bootstrap creates this distn then use Z
	abstract:
		- 95%CI for delay when refusing admission
		- 95%CI for delay with high occupancy
	intro:
		- explain concept of tracking patients not admitted
			emphasise USP that we have followed all patients
	methods:
		- explain why mortality analysis in subgroup of patients rejected
	results:
		
		- occupancy univariate effects table
			- fix errors in recommended subgroup table @done(2016-01-22)
		- outcome models
			- basic mortality description
			- run survival model in full cohort
				- ensure matches  structure of other models
				- run MHR bootstrap (since don't need competing risks)
				maybe add in interaction between room_cmp and recommendation
		
	discussion

@later:
	
	
	
	- writing
		- model decision to admit as binary excluding patients with a treatment limitation order
			- tidying tasks
				- re-run with SOFA score to keep severity adjustment consistent
				- exclude patients with level 3 support	and replace v_ccmds_now with organ_support (soup)
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
						get at the weighted mean by taking `n.extra` and dividing by the study pop
						- full model
						- in subgroup recommended (this might be the model to present)
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
- go back to estimating the median odds ratio; according to this [answer](http://www.stata.com/statalist/archive/2012-11/msg00307.html) it is not possible to derive a confidence interval for this (easily) in stata
- median hazard ratio??
	
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

## 140311

- new system for analysis files: use wrXX_ prefix for results paragraphs in paper
- similarly


## 140227

- added back in all cr_* files. These will allow creation of the data set.
- I have not actually re-created all the data via SQL and Python code in /ccode
- source table in SQL is spot_early.working_early - connecting and downloading this table creates `working_raw.dta`
- STROBE diagram data checked and all working up to cr_working.do

These are notes on the analysis to be performed for the spot-epi paper.
The code here will largely come from the code used for spot_ward. In fact, it the directory is a branch published from the spot_ward repo.
For now, I have moved _all_ files into a subfolder called spot_ward so that I have a fresh start. I will then move the relevant files out one-by-one.


Archive:
	- tables @done(2016-01-18) @project(results)
		- table 1 @done(2016-01-18)
	- sfig 1: occupancy over time	@done(2016-01-18) @project(results)
	- tidy up vars to match limited subset @done(2016-01-18) @project(results)
	- command line option for sims and subgroup @resume @done(2016-01-19) @project(results)
	- for all patients @done(2016-01-19) @project(results)
	- for those recommended @done(2016-01-19) @project(results)
	- siteonly @done(2016-01-19) @project(results)
	- effect of occupancy @done(2016-01-19) @project(results)
	- inter-site variability @done(2016-01-19) @project(results)
	- comparison by using model without patient level vars @done(2016-01-19) @project(results)
	- all @done(2016-01-19) @project(results)
	- delay to admission models @done(2016-01-22) @project(results)
		for the purpose of demonstrating that decision making is key
		hence need to include icu_accept
		- convert to updated set of predictors @done(2016-01-21)
		- add back in decision and work with 
			- full cohort
			- recommended subgroup
			- 
		- effect of occupancy
		- intersite variability
			cannot get at this in a competing risks model - could use early4 in a logistic regression to estimate this, but capture the hazard ratios from the main competing risks models
			- build early4 model as per accept
				- adjust code @done(2016-01-21)
				- update doit @resume @done(2016-01-22)
	✔ start work converting participating hospitals to Rmarkdown @resume(2016-01-01) @done (16-01-01 18:18) @project(@continue)
	- occupancy paragraph	@done(2016-01-13) @project(@continue)
		- occupancy table @done(2016-01-13)
		- occupancy figure @done(2016-01-12)
	- incidence models paragraph @done(2016-01-13) @project(@continue)
		- incidence table 
			- ta_model_count_news_all @done(2016-01-12)
			- tb_model_count_news_high @done(2016-01-12)
		- incidence figure @done(2016-01-12)
	✔ patient characteristics paragraph @done (15-12-31 11:47) @project(inbox)
	✔ table 1 @done (15-12-31 12:28) @project(inbox)
	✔ supp figure 1 (mortality pattern) @done (15-12-31 12:49) @project(inbox)
	✔ supp figure 1 (severity - dead7 association) @done (15-12-31 13:00) @project(inbox)
	+ done this today (70 patients) and corrected the text and the ICU admission numbers @project(FIXME)
	+ see working_survival_single.dta @project(FIXME)
	+ tried then running the laplace command in stata; nice because it directly estimates percentile survival; but I can't seem to pull out a random effect estimate for the site effect (fixed only) @project(FIXME)
	+ exp(sqrt(2*V*invnormal(0.75)) where V is the random effects variance when the random effects are normally distributed @project(FIXME)
	+ need to transform the above equation to work with the gamma distribution since this is used for the random effects in stata @project(FIXME)
	+ frailty in stata has mean 1 (assumed) and variance \theta (which is estimated from the data) @project(FIXME)
	+ the invnormal(0.75) term now needs to be replaced with the upper quartile from the an F distribution which has a numerator and denominator (2V,2V) (see ref [Bengtsson and Dribe, 2010, #60939] appendix)	@project(FIXME)
	+ sites_within_hes @project(FIXME)
	+ sites_within_cmpd @project(FIXME)
	+ sites_early @project(FIXME)
		Now includes HES data for Wales and Northern Ireland
	+ ts_ prefix for "table supplementary" @project(FIXME)
	+ tb_ prefix for "table" @project(FIXME)
	+ fs_ prefix for "figure supplementary" @project(FIXME)
	+ fg_ prefix for "figure" @project(FIXME)
	- skim and check methods @done(2015-12-19) @project(@continue)
	- incidence figures from GEE model	@done(2015-12-29) @project(results)
		- report model as supplementary table?
		- remove elective emergency indicator
		- swap beds_none for room_cmp2
		- remove referral pattern adjustment
		- add back in weekend
		- remove mp_throughput
		- check incidence per 1000 is for NEWS high risk ? @done(2015-12-29)
	- basic @done(2015-12-29) @project(results)
	- add in major groups @done(2015-12-29) @project(results)
	- write abstract @done(2015-12-18)
		- report	occupancy and decision from time2icu model
		- report mortality models
			- run mortality model in cohort not recommended without limits
				this asks the qn: who should be offered critical care esp if you use combined endpoint of death or admission to critical care in the next week
	- model code @done(2015-12-18) @project(Mortality models)
	- overall 7 and 90 day survival models @done(2015-12-18) @project(Mortality models)
	- subgroup @done(2015-12-18) @project(Mortality models)
	- model outputs @done(2015-12-18) @project(Mortality models)
	- sanity check: add in report of model w/o frailty @done(2015-12-18) @project(Mortality models)
	- why  missing 'p' (b/c only 1 sim) @done(2015-12-18) @project(Mortality models)
	- recommended and refused @done(2015-12-18) @project(Mortality models)
	- refused @done(2015-12-18) @project(Mortality models)
	- interaction of recommendation? @done(2015-12-18) @project(Mortality models)
		probably can drop this since you are looking at within subgroup effects 
	- frailty / site level variation @done(2015-12-17) @project(Mortality models)
	- use re-sampling code - but is v slow; will need to run overnight? @done(2015-12-18) @project(Mortality models)
	- model time to admission for those recommended with MHR etc as before @done(2015-12-16)
		- next steps
			- 
		- would need to include competing risk of death since censoring is _not_ independent  @done(2015-12-16)
	- fit simplified version of model @done(2015-12-15)
	- add in frailty @done(2015-12-15)
	- examine impact of 'correct decision' (i.e. what is the cost of being refused if admitted in the end) @done(2015-12-15)
	- just do simple model with CR but not frailty since combination is difficult @done(2015-12-16)
	- extract MOR @done(2015-12-10)
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

