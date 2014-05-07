* Steve Harris
* Created 140311

* Results - Section - Patients
* ============================

* Log
* ===
* 140311	- initial set-up

/*

## Patients

More than 50% of the patients were aged 70 years or older. The study data collected for the patients are presented in Tables [1a][table1a] and [1b][table1b]. At the time of assessment, most patients were being cared for on acute hospital wards without organ support (15,447 patients, 97.4%). Where organ support was provided, this was most often non-invasive ventilation (327 patients, 78%).

Almost two-thirds (9,583, 61.9%) of the patients were reported 'likely' or 'very likely' to have sepsis, and, where sepsis was reported, then the respiratory system was identified as the source in half of the cases (4,918, 51.3%). Cross-tabulating the reported sepsis diagnosis with the physiological severity defined 1,730 patients (10.9%) with septic shock; 891 (51.5%) met the diagnosis on the basis of hypotension (Systolic < 90 mmHg), 623 (36.0%) on the basic of an arterial lactate > 2.5 mmol/l, and hypotension and hypo-perfusion coexisted in 212 (12.5%). Another 4,313 (27.2%) had both reported sepsis and organ dysfunction thereby meeting the definition for severe sepsis.

{>>Report severity of patients here as will need this to explain incidence and outcomes<<}

*/

use ../data/working_postflight.dta, clear

* Q: Proportion of patients > 70
su age
gen age70 = age >= 70 & age != .
tab age70

* Q: Level of care at time of assessment
tab v_ccmds

tab rxrrt
tab rxfio2
tab rxcvs
label list rxcvs
tab rx_resp
label list rx_resp

gen rx_organ_support = rxrrt == 1 | rxcvs == 2 | rx_resp == 2
tab rx_organ_support
tab v_ccmds rx_organ_support

gen ward_unsupported = rx_organ_support & v_ccmds <= 1
tab ward_unsupported

tab rx_resp ward_unsupported, row

* Q: Sepsis status
tab sepsis
gen sepsis_likely = inlist(sepsis,3,4)
tab sepsis_likely
tab sepsis_site if sepsis_likely

tab sepsis2001
tab sepsis_severity

tab sepsis2001 if sepsis_severity == 4

