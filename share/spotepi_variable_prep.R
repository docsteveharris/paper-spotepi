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

source("../share/derive.R")

prep.wdt <- function(data=wdt) {
    tdt <- wdt[,.(
            site,               # hospital level ID
            icode,
            id,                 # patient level ID
            v_timestamp,
            last_trace,
            dead,
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
            sepsis,
            sepsis_site,
            v_ccmds,            # exisiting level of care
            cc.reco = v_ccmds_rec,  
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
            news_risk,
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
            match_quality_by_site,
            elgthtr
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
    tdt[, bedside.decision := factor(bedside.decision, levels=c("icu", "ward", "rxlimits")), ]

    tdt[, sofa2.r := gen.sofa.r(pf, fio2_std)]

    tdt[, odys := ifelse(
        (sofa_score>1 & sofa_r <= 1) |
        (!is.na(sofa2.r) & sofa2.r > 1),1,0)]

    tdt[, osupp := ifelse( rxrrt==1 | rx_resp==2 | rxcvs == 2,1,0)]
    tdt[, osupp2 := ifelse( osupp==1 | v_ccmds == 3,1,0)]

    tdt[, elg.timing :=  ifelse(is.na(elgthtr) | elgthtr == 0, 1, 0)]

    # str(tdt$v_timestamp)
    # str(tdt$last_trace)
    tdt[, t.trace :=round(difftime(last_trace,v_timestamp,units="days"),2)]
    # head(tdt[,.(id,dead,v_timestamp,last_trace,t.trace)])
    # str(tdt$t.trace)


    # Relevel variables
    tdt[, `:=`(
        age_k               = relevel(factor(age_k), 2),
        v_ccmds             = relevel(factor(v_ccmds), 2),
        cc.reco             = relevel(factor(cc.reco), 2),
        sepsis_dx           = relevel(factor(sepsis_dx), 1),
        room_cmp2            = relevel(factor(room_cmp2), "[ 3,21]"),
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

# Double check surv data OK
# d <- merge(tdt,wdt.surv1[,c("id","_t","_d"),with=FALSE],by="id",all.x=TRUE)
# setnames(d,"_t", "stata_t")
# setnames(d,"_d", "stata_d")
# str(d)
# head(d[,.(id,dead,stata_d,v_timestamp,last_trace,t.trace,stata_t)])