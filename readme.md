Steve Harris
Created 140227
These are notes on the analysis to be performed for the spot-epi paper.
The code here will largely come from the code used for spot_ward. In fact, it the directory is a branch published from the spot_ward repo.
For now, I have moved _all_ files into a subfolder called spot_ward so that I have a fresh start. I will then move the relevant files out one-by-one.

Log
===

## 140227

- added back in all cr_* files. These will allow creation of the data set.
- I have not actually re-created all the data via SQL and Python code in /ccode
- source table in SQL is spot_early.working_early - connecting and downloading this table creates `working_raw.dta`
- STROBE diagram data checked and all working up to cr_working.do

