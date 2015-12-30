#  =======================
#  = Hospitals and sites =
#  =======================
teach <- ff.np('teaching', data=wdt.sites)
# same as above but using dplyr
tdt <- distinct(select(wdt,icode,teaching_hosp))
with(tdt, CrossTable(teaching_hosp, prop.chisq=F, prop.t=F))

summary(wdt.sites$patients)
pts_q <- ff.mediqr('patients', data=wdt.sites, dp=0)
pts_q
summary(wdt.sites$studymonths_n)
smonths <- ff.mediqr('studymonths_n', data=wdt.sites, dp=0)
smonths
summary(wdt.sites$pts_by_hes_n)
pts_overnight <- ff.mediqr('pts_by_hes_n', data=wdt.sites, dp=0)
pts_overnight
# Overnight admissions per month by CCOT provision
with(wdt.sites, tapply(pts_by_hes_n, ccot, summary))

# Critical care outreach
with(wdt.sites, CrossTable(ccot, prop.chisq=F, prop.t=F))
beds <- ff.mediqr('cmp_beds_persite', data=wdt.sites, dp=0)
beds
colocate <- ff.np('units_incmp', data=wdt.sites, dp=0)

tt$tails_all <- wdt.sites[,
    (cmp_patients_permonth*tails_all_percent/100)]
tails_all <- ff.mediqr('tails_all', data=tt, dp=0)
tails_all
tails_p <- ff.mediqr('tails_all_percent', data=wdt.sites, dp=0)
tails_p

#  ======================================
#  = Effects of critical care occupancy =
#  ======================================

with(wdt, CrossTable(room_cmp, prop.chisq=F, prop.t=F, chisq = T))
with(tdt, CrossTable(room_cmp2, prop.chisq=F, prop.t=F, chisq = T))

# Occupancy and effects on Rx
with(wdt,
     CrossTable(room_cmp2, rxlimits,
                prop.chisq=F, prop.t=F, chisq = T))

with(wdt[rxlimits==0],
     CrossTable(room_cmp2, icu_recommend,
                prop.chisq=F, prop.t=F, chisq = T))


# Report model effect to compare ims_delta with baseline
# Using this as a factor loses the advantage of the ordered trend assessment
with(wdt[rxlimits==0 & recommend==1], tapply(ims_delta, room_cmp2, summary))
wdt[, room_cmp2 := relevel(room_cmp2, ref="[ 3,21]")]
m <- lm(ims_delta ~ room_cmp2, data=wdt[rxlimits==0 & recommend==1])
summary(m)


#  ===========================
#  = Patient characteristics =
#  ===========================
# - [ ] TODO(2015-12-17): convert to tdt

#  =================================
#  = Pathways following assessment =
#  =================================
with(wdt, CrossTable(icu_recommend))
with(wdt, CrossTable(icu_recommend, rxlimits))
with(wdt[icu_recommend==0], CrossTable(icu_accept, rxlimits))

with(wdt, CrossTable(bedside.decision))
with(wdt, CrossTable(dead7, bedside.decision))
with(wdt, CrossTable(icucmp, bedside.decision))
with(wdt[bedside.decision=="ward"], CrossTable(dead7, icucmp))
with(wdt[bedside.decision=="ward"], CrossTable(icu_recommend))
with(wdt[bedside.decision=="ward" & icu_recommend==1], CrossTable(dead7, icucmp))
with(wdt, CrossTable(beds_none2, bedside.decision))
with(wdt, CrossTable(beds_none, bedside.decision))
with(wdt[icu_recommend==1], CrossTable(beds_none, bedside.decision))


#  ==================================
#  = Patients with treatment limits =
#  ==================================
rxlimits <- ff.np('rxlimits', data=wdt, dp=0)

age.by.rxlimits <- ff.t.test(wdt, 'age', 'rxlimits', dp=0)
age.by.rxlimits

sofa.by.rxlimits <- ff.t.test(wdt, 'sofa_score', 'rxlimits', dp=1)
sofa.by.rxlimits

dead7.rxlimits <- ff.np('dead7', dp=1, data=wdt[rxlimits==1])
dead90.rxlimits <- ff.np('dead90', dp=1, data=wdt[rxlimits==1])
dead1y.rxlimits <- ff.np('dead1y', dp=1, data=wdt[rxlimits==1])

#  ========================================================
#  = Patients without Rx limits recommended **WARD** care =
#  ========================================================
ward <- ff.np('ward', dp=1, data=wdt)

age.by.ward <- ff.t.test(wdt[rxlimits==0], 'age', 'ward', dp=1)
age.by.ward
sofa.by.ward <- ff.t.test(wdt[rxlimits==0], 'sofa_score', 'ward', dp=1)
sofa.by.ward

recommend <- ff.np('recommend', dp=1, data=wdt)
dead7.ward <- ff.np('dead7', dp=1, data=wdt[ward==1])
with(wdt[rxlimits==0], CrossTable(dead7, recommend, prop.chisq=F, prop.t=F, chisq=T))


wdt[,alive7noICU := ifelse(dead7==0 & icucmp==0,1,0)]
alive7noICU.ward <- ff.np('alive7noICU', dp=1, data=wdt[ward==1])
icucmp.ward <- ff.np('icucmp', dp=1, data=wdt[ward==1])
icucmp.reassess <- ff.np('icu_accept', dp=1, data=wdt[ward==1 & icucmp==1])
wdt[,dead7noICU := ifelse(dead7==1 & icucmp==0,1,0)]
dead7noicu.ward <- ff.np('dead7noICU', dp=1, data=wdt[ward==1])


#  =============================================
#  = Patients recommended to **CRITICAL** care =
#  =============================================
recommend <- ff.np('recommend', dp=1, data=wdt)
accept <- ff.np('accept', dp=1, data=wdt[recommend==1])

# characteristics of those accepted
with(wdt[recommend==1], tapply(age, accept, summary))
age.by.accept <- ff.t.test(wdt[recommend==1], 'age', 'accept', dp=1)
age.by.accept

lookfor("age")
describe(wdt$age80_b)
ff.prop.test(var="age80", byvar="accept", data=wdt[rxlimits==0,.(accept,age80=age<=80)], )

sofa.by.accept <- ff.t.test(wdt[recommend==1], 'sofa_score', 'accept', dp=1)
sofa.by.accept
with(wdt[recommend==1], CrossTable(dead7, accept, prop.chisq=F, prop.t=F, chisq=T))
with(wdt[recommend==1 & accept==1], CrossTable(dead7, icucmp, prop.chisq=F, prop.t=F, chisq=T))

# outcomes for those recommended but not accepted
alive7noICU.rec1.acc0 <- ff.np('alive7noICU', dp=1, data=wdt[recommend==1 & accept==0])
icucmp.rec1.acc0 <- ff.np('icucmp', dp=1, data=wdt[recommend==1 & accept==0])
dead7noicu.rec1.acc0 <- ff.np('dead7noICU', dp=1, data=wdt[recommend==1 & accept==0])

#  =======================================
#  = Delay to admission to critical care =
#  =======================================
# TODO: 2015-11-12 - [ ] redo below after excluding deaths at assesment and theatre admissions

wdt[,.N,by=elgthtr]
wdt[,.N,by=v_disposal]
wdt.timing <- wdt[is.na(elgthtr) | elgthtr ==0]

time2icu <- ff.mediqr('time2icu', data=wdt.timing, dp=0)
time2icu
early4 <- ff.np('early4', wdt.timing[icucmp==1])

# Recommended and accepted
time2icu.acc1 <- ff.mediqr('time2icu', data=wdt.timing[recommend==1 & accept==1], dp=0)
time2icu.acc1
early4.acc1 <- ff.np('early4', wdt.timing[icucmp==1 & recommend==1 & accept==1])

# Recommended not accepted
time2icu.rec1.acc0 <- ff.mediqr('time2icu', data=wdt.timing[recommend==1 & accept==0], dp=0)
time2icu.rec1.acc0
early4.rec1.acc0 <- ff.np('early4', wdt.timing[icucmp==1 & recommend==1 & accept==0])

# Not recommended but later admitted
time2icu.ward <- ff.mediqr('time2icu', data=wdt.timing[ward==1], dp=0)
time2icu.ward
early4.ward <- ff.np('early4', wdt.timing[icucmp==1 & ward==1])







