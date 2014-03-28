use ../data/working.dta, clear
qui include cr_preflight.do
save ../data/scratch/scratch.dta, replace

*  ======================================
*  = Set up hierarchical nature of data =
*  ======================================

xtset site
/* Example of how to inspect for within/between variation */
xtsum age sex visit_hour visit_dow visit_month ccot_shift_pattern ///
	count_patients count_all_eligible

/* Examine the outcome variable */
su icnarc_score,d
hist icnarc_score, s(0) w(1) percent
* NOTE: 2013-01-16 - note small spike at zero
gen icnarc_score0 = icnarc_score == 0

