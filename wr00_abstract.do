
use ../data/working_postflight.dta, clear
sort v_timestamp
list v_timestamp in 1
list v_timestamp in -1

use ../data/working_survival.dta, clear
stset dt1, id(id) failure(dead_st) exit(time dt0+365) origin(time dt0)
sts list, at(0 1 7 28 30 90 365) fail
sts list, at(0 7) fail noshow
sts list, at(0 28) fail noshow
sts list, at(0 90) fail noshow
sts list, at(0 365) fail noshow

