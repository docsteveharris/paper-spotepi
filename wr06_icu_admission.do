* Steve Harris
* Created 140418

* Results - Section - ICU admission
* =================================

* Log
* ===
* 140418	- initial set-up

use ../data/working_postflight.dta, clear
count
tab icucmp, miss

tab icucmp news_risk, col
