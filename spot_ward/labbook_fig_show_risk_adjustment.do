* Steve Harris
* Created 131010
* Produce a series of plots demonstrating how risk adjustment working_survival
* Log
* 131010 - initial code


cd ~/data/spot_early/vcode
use ../data/working_survival.dta, clear
stset

stcox i.early4, noshow
stcurve, at(early4 = 0) at1(early4 = 1) hazard kernel
