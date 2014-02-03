*  ======================================================
*  = Sample of working data for the purposes of sharing =
*  ======================================================

cd ~/data/spot_ward/vcode
use ../data/working_postflight.dta, clear
keep id icode dead28 age sex icnarc_score v_disposal
set seed 3001
sample 1000, count
list  in 1/10
save ../data/working_sample_1000.dta, replace

