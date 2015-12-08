\<!-- pandoc -o mas\_spotepi.odt paper-spotepi\_text.md --smart --\>

Title page
==========

Working title
-------------

Mortality among deteriorating ward patients referred to critical care: a
prospective observational cohort study in 49 NHS hospitals

Authors
-------

-   Steve Harris

-   Mervyn Singer

-   Colin Sanderson

-   David Harrison

-   Kathy Rowan

Abstract
========

Background
----------

Recent policy has placed emphasis identifying and responding to deterioration
among ward patients, and providing early access to critical care. However, the
data underpinning this policy comes from small retrospective studies and
qualitative work. The incidence, disposition, and outcomes of these patients is
not known.

Methods
-------

We conducted a prospective cohort study of consecutive deteriorating ward
patients assessed for consideration of admission to critical care in 49 NHS
hospitals (1 November 2010 --- 31 December 2011). We linked to a national
critical care audit database to define fact and timing of admission in the
subsequent week, and death registrations for survival to one year. Incidence
models were stratified by the NHS National Early Warning Score (NEWS) risk
class, and used generalised estimating equations. Cox proportional hazards with
a shared hospital frailty were used for survival.

Findings
--------

We included 15,602 patients. Nearly half of patients (7022 patients, 45·0%) met
criteria for the highest NEWS risk class with an incidence of 4·6 (95%CI
3·6--5·5) patients per 1,000 overnight admissions, or 22 patients per month
(95%CI 18--26). About a third of patients (5,326, 34·1%) were admitted to
critical care. There were 2,787 (17·9%), and 6,989 (44·8%) deaths at 1-week, and
1-year respectively (Kaplan-Meier failure function). A greater proportion of
deaths occurred amongst those admitted to ICU during the subsequent week (959,
18.4%), but a similar number of patients (934, 11.4%{\>\>check these numbers,
need wrXX file for abstract\<\<}) without treatment limitation orders died on
the ward without ICU care. There was significant variation in mortality between
hospitals even after adjustment for patient level risk-factors (Median Hazard
Ratio 1·34, 95%CI xx-yy @todo ).

Interpretation
--------------

Deteriorating ward patients are common, and have a high mortality which varies
significantly between hospitals. A minority of patients are admitted to ICU, and
many deaths occur without ICU admission.

Funding
-------

Wellcome Trust, NIHR Service Support Costs, and the Intensive Care National
Audit & Research Centre

Introduction
============

There are more than 160 acute hospitals in England that care for more than 11
million overnight hospital admissions per annum. Each patient spends a mean of 5
days on a hospital ward.[Centre, 2012, \#17089] These inpatients undergo a
process of continual triage, and those who deteriorate are referred to critical
care. This interface between the ward and critical care has been a priority area
for the English National Health Service (NHS), but available data derive from
qualitative work such as the NHS National Patient Safety Agency report[Luettel
et al., 2007, \#734], relatively small retrospective studies[McQuillan et al.,
1998, \#605], or voluntary reporting systems[Cullinane et al., 2005, \#15159].

International reports indicate that episodes of deterioration are common, and
have poor outcome. Inpatient referrals to critical care outreach teams (CCOT),
or their equivalent, appear to run between 25--50 per 1,000 hospital
admissions.[Bell et al., 2006, \#17133; Buist et al., 2007, \#17325; Jones et
al., 2009, \#17139] For such patients, hospital mortality rates are reported as
26% (Australia), and 30-day mortality as 28% (Israel).[Buist et al., 2007,
\#17325; Simchen et al., 2004, \#705] This greatly exceeds the 8·9% inpatient
30-day mortality recently reported in Scottish NHS hospitals.[Clark et al.,
2014, \#86524]

Critical care provision in the NHS is constrained despite a one-third increase
in funding for beds in 2000. In 2010, the United Kingdom (UK) was ranked 24 out
of 28 European countries in terms of provision of critical care beds per capita
population.[Rhodes et al., 2012, \#15692] Similar results are found when the
comparison is with North American health care systems.[Wunsch et al., 2008,
\#761] This ought to imply that access to critical care for the deteriorating
ward patient is correspondingly constrained, and that delay to admission to
critical care is a problem.

The objective of the (SPOT)light study was two-fold. The first objective was to
measure the incidence, the disposition, and the outcome of the deteriorating
ward patient referred to critical care, and to quantify the degree of
heterogeneity between hospitals. These results will be reported here. The second
objective was to measure the magnitude and the effect of delay to admission, and
this will be reported in an accompanying paper.

Methods
=======

Study design and participants
-----------------------------

The (SPOT)light study was a prospective observational cohort study of the
deteriorating ward patient referred to critical care. The physiological status
of the patient at the time of the first bedside assessment by critical care was
prospectively recorded along with the recommendation made at the end of the
assessment. By linking the records generated at the time of the bedside
assessment, to the Intensive Care National Audit & Research Centre's Case Mix
Programme Database (ICNARC CMPD), the fact and timing of admission to critical
care was identified. Similarly, by linking to the NHS Information Service then
vital status up to 1 year was recorded.

Patients were eligible if they were inpatients on general hospital wards who had
been referred to, and assessed by, critical care. The assessment had to be
performed at the bedside by a member of the critical care team. This was defined
broadly to include members of the critical care outreach service, or members of
the critical care medical or nursing staff. Only the first assessment for a
given episode of illness was eligible. Cardiac arrests, planned admissions, and
visits that were retrievals of patients where a decision to admit had already
been made were not eligible.

Patient demographics, and the date, time and location of the visit were
recorded, along with the level of care at the time of the visit.[2000, \#1009]
Available patient physiology (vital signs, arterial blood gas and laboratory
measurements) at the time of, or immediately preceding, the visit was abstracted
along with organ support, antibiotic therapy, and a subjective assessment of the
likelihood of sepsis, and its source. The assessor was then asked to report the
level of care recommended, and the outcome of the decision to admit to critical
care. Treatment limitation orders were recorded for those not admitted.

Procedures
----------

The study was registered on the National Institute of Health Research (NIHR)
research portfolio, and hospitals were eligible if they participated in the CMP.
Research teams at each hospital attended a Dataset Familiarisation Course, and a
data collection manual containing definitions of items to be collected was
provided. The Clinical Trials Unit at ICNARC provided support for research
queries during the study.

Hospitals were asked to report all consecutive ward referrals to the critical
care team. Where possible, data collection was to be contemporaneous, and
hospitals were requested to identify and submit missed referrals. We used the
proportion of emergency ward admissions in the ICNARC CMP that were successfully
linked to the (SPOT)light database to quality control the study. Data quality
was judged on a monthly basis, and all data from individual months falling below
a minimum standard of 80% data linkage were excluded. Reporting was via a secure
online web portal which performed real-time field and record level validation.
Further on-line validation reports were completed by all hospitals before the
database was locked in September 2012. Fact and date of death were then
requested from the NHS Information Service. CCOT provision was reported by
participating hospitals, and contemporaneous CMP data and Hospital Episode
Statistics (HES) were used to define critical care provision, occupancy, and
hospital characteristics.

Statistical analysis
--------------------

The primary outcome was 90-day mortality. Sample size was calculated to evaluate
mortality increases from delay to admission using estimates from 2007 ICNARC CMP
data. The target sample size was 12,075--20,125 patients referred to critical
care which allowed for delays to occur in 10--40% of admissions and mortality
effect sizes of 5--10%.

Three definitions of physiological severity of illness on the ward were
constructed from the physiological data collected at the time of the bedside
assessment: the NHS National Early Warning Score (NEWS); the acute physiology
component of the ICNARC score, and SOFA score.[Physicians, 2012, \#9726;
Harrison et al., 2007, \#1640; Vincent et al., 1996, \#719] The NEWS score
additionally defines three risk classes (Low, Medium, and High) designed to
trigger an escalating clinical response. Missing variables were assigned a zero
weight equivalent to assuming that the unobserved physiology was within the
normal range.[Harrison et al., 2007, \#1640]

Incidence models were stratified by NEWS risk class. The unit of analysis was a
study week so that weekly fluctuations in lagged critical care occupancy could
be examined. Estimation was via generalised estimating equations (GEE) with
hospitals as clusters, and week-by-week correlations modelled using a first
order autoregressive structure. Cox proportional hazards were used to model
survival with a shared frailty (random effect) for hospitals which was is
reported as a Median Hazard Ratio (MHR).[Bengtsson and Dribe, 2010, \#60939] The
proportional hazards assumption was checked by inspecting plots of smoothed
exponentiated standardised Schoënfeld residuals, and re-entering terms using
time-varying co-efficients where necessary.

Categorical data were reported as counts and percentages, and continuous data as
mean (SD) or median (IQR) values. Effect measures are reported with their 95%
confidence intervals. In tables, where effect measures from different models are
reported alongside each other for the purposes of comparison then the 95%
confidence intervals are replaced with asterisks to improve legibility. One
asterisk is used when the probability of a type I error is less than 5%
(p\<0·05), two asterisks are used when the risk is less than 1% (p\<0·01), and
three when the risk is less than 0·1% (p\<0·001).

Role of the funding source
--------------------------

The study was centrally funded by the Wellcome Trust, sponsored by ICNARC, and
supported at NHS hospitals through the National Institute of Health Research
service support costs. The funders of the study had no role in the study design;
gathering, analysis, and interpretation of the data; writing of the report; and
decision to submit the report for publication. The corresponding author had full
access to all the data (including statistical reports and tables); takes
responsibility for the integrity of the data and the accuracy of the data
analysis; and takes final responsibility for the decision to submit for
publication.

Results
=======

48 hospitals reported 20893 visits over 435 months. 2694 visits (12.9%) did not
meet the inclusion criteria including 1860 (8.9%) repeat rather than first
visits, and 586 (2.8%) patients recently discharged from critical care. Data
linkage was incomplete (\< 80%) for 66 (15%) study-months excluding a further
2440 (11.7%) visits. Therefore 15759 patients were recruited to the study, of
which 15158 (96.1%) completed follow-up without error and were available for
analysis ([Figure FFF][figureFFF]). Final data linkage (ward visits to critical
care admissions) was 93% complete.

Hospitals
---------

The participating hospitals comprised 10 teaching and 38 general hospitals that
each collected data between September 2010 and December 2011 for a median of 8
months (range 2--12 months). Each hospital contributed a median of 253 patients
(range 80--1305) equivalent to 6 patients referred to critica care (IQR 3--9)
per 1,000 overnight admissions.

Critical Care Outreach Teams operated 24 hours/day and 7 days/week in 14 (29%)
hospitals, less than 24 hours/day in 19 (40%) hospitals, and less than 7
days/week in 13 (27%) hospitals ([supplementary Table TTT](<stableTTT>)). As
outreach provision decreased, the numbers of patients assessed by critical care
also fell (8, 5, and 4 per 1,000 overnight admissions). Two (4%) hospitals had
no CCOT, but nonetheless saw 8 patients per 1,000 overnight admissions.

There was a median of 12 (IQR 9--18) critical care beds per hospital (mixed
Level 2 --- typically intensive monitoring or single organ support, and Level 3
--- ventilated or multiple organ support), most often in a single physical
location (45 hospitals). These units admitted a median 20 (IQR 14--26) unplanned
admissions from the ward per month which represented 36% of all critical care
admissions (IQR 31-43%).

### Critical care occupancy

There were 1198 (8%) patients assessed when the unit was full, 3757 (25%)
assessed when there were either one or two beds available, and 10197 (67%)
assessed when there were more than two beds available (Table TTT). Critical care
occupancy fluctuated with time of the day, day of the week, and season of the
year.([Supplementary Figure FFF](<sfigureFFF>)).

Patients
--------

Table TTT shows the baseline data for all ward patients assessed. Sepsis was
reported in (9296, 61%) patients; of these, the respiratory system was
considered to be the source in half (4772, 51%). Organ failure, defined as a
SOFA score greater than or equal to two, was present in 5164 (34%) of patients.
1427 patients (9%) were in respiratory failure, 2931 (19%) were in renal
failure, and overall 4636 (31%) were shocked.

Septic shock (defined by cross-tabulating the reported sepsis diagnosis with
physiology) was present in 1641 (11%) of patients: 845 (51%) met the definition
on the basis of hypotension (systolic \< 90mmHg), 593 (36%) on the basic of an
arterial lactate \> 2·5 mmol/l, and hypotension and hypo-perfusion coexisted in
203 (12%).

Organ support at the time of assessment was uncommon (870 patients, 6%).

Severity of illness
-------------------

The median acute physiology scores on the NEWS, SOFA and ICNARC scales were 6
(IQR 4--9), 3 (IQR 2--4), and 15 (95%CI 10--20) respectively. 6759 (45%)
patients met the criteria for highest NEWS risk class with 4250 (28%) and 3768
(25%) in the Medium and Low risk categories.

Overall, 2708 (18%) patients died in the 7-days following ward assessment.There
was a clear correlation between physiological severity and early (7-day)
mortality using either ward based (NEWS) or critical care scoring systems (SOFA,
ICNARC) (Supplementary Figure FFF).

Patients referred out-of-hours (7pm-7am), and older patients had higher mean
physiology scores across all three scoring systems at the time of the assessment
([supplementary Table SSS][stableSSS]). Patients with a reported sepsis
diagnosis, regardless of the underlying cause, were also markedly more unwell.

-   [ ] TODO(2015-11-28): run model for NEWS and SOFA @later

Incidence and case-finding
--------------------------

Hospitals reported 10.5 (95%CI 8·0--13·0) patients per 1,000 overnight
admissions. Of these, 4·6 (95%CI 3·6--5·5) per 1,000 overnight admissions were
in the NEWS High Risk class. This was equivalent to 22 (95%CI 18--26) NEWS High
Risk patients per month for a typical hospital (one with 54,000 overnight
admissions per year, 11 critical care beds, CCOT cover 24 hours/day and 7
days/week, and 5--15 patient's assessed by critical care per 1,000 overnight
hospital admissions). Case finding for high risk patients increased linearly
with referral incidence but may have begun to plateau for the hospitals with
referral rates in the highest quartile ([sFigure
FFF](<../out/figures/count_news_high_rcs.jpg>)).

Patient pathways following referral to critical care
----------------------------------------------------

### Patients with treatment limits

2141 (14%) patients, who were refused critical care admission, remained on the
ward with a treatment limitation order in place. These patients were older (77
vs 65 years, 95%CI for difference 11--12 years), and more acutely unwell (3.6 vs
3.1 SOFA points, 95%CI for difference 0.4--0.6). Both 7-day and 90-day
mortalities were substantial (41% (881 deaths), and 65% (1402 deaths)
respectively), but more than a fifth of patients (24%, 506 patients) survived a
year despite the treatment limitation order.

### Patients recommended ward care

8041 (53%) patients were recommended for ward care without treatment limits.
Those recommended ward care were older (66 vs 65 years, 95%CI for difference
0.7-1.9 years), less acutely unwell (2.7 vs 3.9 SOFA points, 95%CI for
difference 1.1-1.3) and had a lower 7-day mortality (11% vs 20%, p\<0.0001).

6116 (76%) of those recommended ward care survived that week without critical
care admission. However, 1303 patients (16%) went on to receive later critical
care, and 622 patients (8%) died during the next 7 days without admission to
critical care.

### Patients recommended critical care

4976 (33%) were recommended for critical care at the initial assessment. Of
these, 3375 (68%) were offered admission. Those offered admission were
marginally younger (by 1 year, 95%CI 0--2), more acutely unwell (4.1 vs 3.5 SOFA
points, 95%CI 0.5-0.7), and had a higher 7-day mortality of (21% vs 18%,
p=0.0121). 40 deaths (6%) occured on the ward before admission could be
arranged.

Of the 1601 (32%) of the patients recommended to critical care but not offered
admission, 842 (53%) survived the subsequent week without critical care. 580
(36%) were offered critical care later, and 179 (11%) died on the ward within
the week, and without critical care.

 

ICU admission
-------------

5,248 patients (33·4%) were admitted to critical care during the week following
their assessment. This included 40·7% (2,859) patients in the NEWS High Risk
class, and 29·8% (1,294), and 25·9% (999) in the Medium and Low risk classes.

Mortality
---------

There were 706 deaths by the end of the first day, 2,787 by the end of the first
week, 4,561 by the end of the first month, and 6,989 by the end of the first
year. The risk of death at these time points was 4·5%, 17·9%, 29·2%, and 44·8%
respectively (Kaplan-Meier failure function). The period of greatest risk
immediately followed the referral, falls rapidly, but remained elevated even at
one-year (excess mortality 0·103 deaths/patient-year, 95%CI
0·076--0·130.([Figure 4][figure4]).[Cancer Research UK Cancer Survival Group,
2006, \#91622]

During the week following the ward visit, the majority (1767, 63·4%) of deaths
occurred without admission to critical care. The majority of these patients
(934, 52·9%) had no treatment limitation order reported at the time of their
initial evaluation ([Figure 5][figure5]). These patients were less unwell (SOFA
score -0·68, 95%CI -0·46 to -0·91), but older (6·3 years, 95%CI 5·1--7·5) than
those deaths occurring in ICU ([supplementary Table
4](<stb04_ward_vs_icu_deaths.ods>)). A small proportion (66, 7·1%) of the ward
deaths had been accepted to critical care, but died before the admission was
realised. In contrast, among those with treatment limitation orders, 472 (23·1%)
patients survived to one year without admission to critical care in that first
week.

A series of models were fitted with 90-day survival as the dependent variable.
The final best model [Table 4](<tb03_ward_survival_final.ods>) incorporated a
time-varying effect for acute physiological severity so that the effect of
severity on survival was greatest in the first days following assessment (see
supplementary [supplementary Figure
1](<sfig01_survival_icnarc0_ssresidual.pdf>)). Other patient level risk factors
were consistent with the existing literature on outcomes in similar patients:
older patients, males, patients receiving a higher level of care, and those with
sepsis (other than genito-urinary) had worse outcomes.[Harrison, 2007] Patients
admitted during the winter months had an adjusted hazard ratio of 1·12 (95%CI
1·04--1·20), but neither time of day, nor day of the week affected survival.

At the hospital level, with the exception of the two hospitals without a CCOT
service, there was weak stepwise decrease in survival as the provision of CCOT
services expanded. No other hospital level factors were associated with outcome.
The final best model demonstrated significant hospital level variation (variance
0·030, 95%CI 0·013--0·046, [supplementary Figure
2](<sfig02_survival_reffects.pdf>)). This gives a Median Hazard Ratio (MHR)
between hospitals of 1·28 in the final model which was not markedly affected by
adjustment for patient characteristics (MHR 1·29 in a model excluding these).

Discussion
==========

*to be written!*

References
==========

Electronic Supplementary Material
=================================

Sensitivity Analyses
--------------------

### Data linkage quality

Data linkage rates between the (SPOT)light data and the ICNARC CMP data were
used throughout the study to monitor quality. Where eligible admissions to a
critical care unit were reported to the ICNARC CMP but not found in the
(SPOT)light reports, then the concern was that ward referrals to ICU were not
being captured. Hospitals were required to meet a minimum standard of 80%
capture during the first three months, and, even after this period, those months
where the data quality fell below this standard were also excluded.

The incidence, severity, and survival models were therefore repeated using the
additional data submitted that was 70--80% complete --- the 'all' data set. This
included an additional 11 hospitals, 85 study months and 3,670 patients.
Similarly, the analysis was repeated amongst those hospitals meeting a higher
95% threshold --- the 'best' data set (44 hospitals, 219 study months, and 9,179
patients). The mean data linkage proportions in the 'all', 'study' and 'best'
data sets were 92·3%, 93·5%, and 99·8%.

The baseline incidence of NEWS High Risk patients was slightly lower among the
44 hospitals in the 'best' data set with an estimated incidence of 4·5 (95%CI
4·1--4·9) versus 5·0 (95%CI 4·7--5·4) patients per hospital per week. Otherwise
the approximate magnitude and direction of the effect of all hospital and timing
risk factors were very similar

### Alternative provision of critical care

4 of the 49 hospitals reported critical care capacity in units that were not
monitored by the ICNARC CMP. Only one hospital had unmonitored Level 3 capacity,
and this was in a designated post-operative critical care unit unlikely to
receive direct admissions from the ward. The unmonitored beds at the other 3
hospitals were in coronary care units (2 hospitals), post-operative critical
care units (1 hospital), and a general HDU (1 hospital).

Since it is unlikely that direct emergency ward admissions would have been
admitted to these units, the hospitals were included in the primary analysis;
however, the estimates of the proportion of patients dying without admission to
critical care have been repeated excluding 749 patients from these 4 hospitals.

During the week following the ward visit in the 45 remaining hospitals, the
majority (1621, 63·3%) of deaths occurred without admission to critical care. In
turn, the majority of these patients (862, 53·2%) had no treatment limitation
order reported at the time of their initial evaluation. These proportions are
near identical to those in the primary analysis.

Estimation of relative survival
-------------------------------

Estimation of relative survival was performed using the `strel2` package in
Stata where the expected survival was derived from life tables based on data
from the UK census and Office of National Statistics (ONS) records. These were
compiled by the Cancer Research UK Cancer Survival Group at the London School of
Hygiene and Tropical Medicine, and were downloaded from
http://www.lshtm.ac.uk/eph/ncde/cancersurvival/tools/registered/lifetables.html
in May 2014.