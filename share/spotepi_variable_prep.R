# author: Steve Harris
# date: 2015-12-17
# subject: generic function to clean and prepare variables for paper

# Readme
# ======


# Todo
# ====


# Log
# ===
# Date: 2015-12-17
# - file created
require(data.table)
require(Hmisc)
require(datascibc)

source(paste0(PATH_SHARE, "/derive.R"))

prep.wdt <- function(data=wdt) {
    tdt <- wdt[,.(
            site,               # hospital level ID
            icode,
            id,                 # patient level ID
            dead7,              # 7 day mortality,  1==dead
            dead90,             # 90 day mortality, 1==dead
            open_beds_cmp,      # beds available at time of ward assessment
            rxlimits,           # treatment limitations set (i.e. not for ICU)
            icu_recommend,      # recommended for critical care at assessment
            icu_accept,         # accepted to critical care at assessment
            icucmp,             # admitted to ICU in week following assessment
            time2icu,           # delay to admission in hours
            early4,             # admitted within 4 hours, 1==true
            age,                # age in years
            age_k,
            male,               # male sex
            sepsis_dx,          # reported sepsis diagnosis (0==not septic)
            v_ccmds,            # exisiting level of care
            v_ccmds_rec,        # recommended level of care - levels 0,1,2,3
            delayed_referral,   # assessor considers referral delayed
            periarrest,         # assessor considers patient peri-arrest
            out_of_hours,       # assessed 7pm-7am
            weekend,            # assessed saturday or sunday
            winter,             # assessed dec-mar
            icnarc_score,       # physiological severity of illness (integer score)
            ims1,
            ims2,
            ims_delta,
            news_score,         # physiological severity of illness (ward vital signs)
            sofa_score,         # physiological severity of illness (with allowance for organ support)
            sofa_r,
            hrate,              # heart rate
            bpsys,              # systolic bp
            temperature,        # temperatuer
            rrate,              # respiratory rate
            rxfio2,             # level of respiratory organ support at assement
            pf,
            fio2_std,
            ph,                 # pH of blood
            sodium,             # serum sodium
            wcc,                # white cell count (marker of infection)
            pf_ratio,           # invasive marker of lung injury
            urea,               # biochemical marker of renal function
            creatinine,         # biochemical marker of renal function
            uvol1h,             # urine output (renal function)
            sf_ratio,           # non-invasive marker of lung injury
            bpdia,
            bpmap,
            rxcvs_sofa,         # level of cardiovascular organ support
            platelets,          # marker of haematological organ dysfunction
            bili,               # marker of liver function
            gcst,               # level of consciousness
            avpu,               # level of consciousness (crude but simple)
            lactate,            # blood lactate
            rxrrt,
            rxcvs,
            rx_resp,
            teaching_hosp,
            hes_overnight_c,
            hes_emergx_c,
            cmp_beds_max_c,
            cmp_throughput,
            patients_perhesadmx_c,
            ccot_shift_pattern,
            studymonth,
            match_quality_by_site
                ) ]

    # Further variable generation
    tdt[, recommend := ifelse(icu_recommend==1 & rxlimits==0,1,0)]
    tdt[, ward := ifelse(icu_recommend==0 & rxlimits==0,1,0)]
    tdt[, accept := ifelse(icu_recommend==1 & rxlimits==0 & icu_accept,1,0)]
    tdt[, room_cmp2 := cut2(open_beds_cmp, c(1,3), minmax=T )]
    tdt[, beds_none2 := cut2(open_beds_cmp, c(1), minmax=T )]
    tdt[, bedside.decision :=
        ifelse(rxlimits == 1, "rxlimits",
        ifelse(icu_accept == 0, "ward", "icu"))]

    tdt[, sofa2.r := gen.sofa.r(pf, fio2_std)]

    tdt[, odys := ifelse(
        (sofa_score>1 & sofa_r <= 1) |
        (!is.na(sofa2.r) & sofa2.r > 1),1,0)]

    tdt[, osupp := ifelse( rxrrt==1 | rx_resp==2 | rxcvs == 2,1,0)]

    # Relevel variables
    tdt[, `:=`(
        age_k               = relevel(factor(age_k), 2),
        v_ccmds             = relevel(factor(v_ccmds), 2),
        sepsis_dx           = relevel(factor(sepsis_dx), 1),
        room_cmp2            = relevel(factor(room_cmp2), 3),
        ccot_shift_pattern  = relevel(factor(ccot_shift_pattern), 4),
        icode               = factor(icode)
        )]

    return(tdt)
}


# Testing
# rm(list=ls(all=TRUE))
# setwd('/Users/steve/aor/academic/paper-spotepi/src/analysis')
# source("project_paths.r")
# library(datascibc)
# rm(wdt)
# load(paste0(PATH_DATA, '/paper-spotepi.RData'))
# lookfor("month")
# tdt <- prep.wdt(wdt)