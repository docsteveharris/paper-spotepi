# doit file for Norad project
from __future__ import print_function

#  ============================
#  = Create data for analysis =
#  ============================

# #      _____                                     _       _        
#     |  __ \                                   | |     | |       
#     | |__) | __ ___ _ __   __ _ _ __ ___    __| | __ _| |_ __ _ 
#     |  ___/ '__/ _ \ '_ \ / _` | '__/ _ \  / _` |/ _` | __/ _` |
#     | |   | | |  __/ |_) | (_| | | |  __/ | (_| | (_| | || (_| |
#     |_|   |_|  \___| .__/ \__,_|_|  \___|  \__,_|\__,_|\__\__,_|
#                    | |                                          
#                    |_|                                          

def task_cr_working():
    """Build working.dta from working_raw_epi.dta
    This last file is stored on the 'phd' encrypted volume"""

    # print("Running cr_working.do via Stata")

    return {
        "file_dep": ["prep/cr_working.do", "data/original/working_raw_epi.dta"],
        "targets":  ["data/working_all.dta", "data/working.dta", "logs/cr_working.txt"],
        "actions":  ["stata-mp -bq do ${PWD}/prep/cr_working.do",
                    "mv cr_working.log logs/cr_working.log",
                    "if tail logs/cr_working.log | egrep 'r(\d+)' -c; then tail logs/cr_working.log && echo '!!! Stata dofile error?' && exit 1; else exit 0; fi"
                    ] 
    }

# - [ ] NOTE(2015-12-30): fails b/c ?problem with ODBC connection and Stata
# def task_cr_sites():
#     """Build sites.dta
#     """

#     return {
#         "file_dep": ["cr_sites.do"],
#         "targets":  ["data/sites.dta"],
#         "actions":  ["stata-mp -bq do ${PWD}/prep/cr_sites.do"]
#                     "mv cr_sites.log logs/cr_sites.log",
#                     "if tail logs/cr_sites.log | egrep 'r(\d+)' -c; then tail logs/cr_sites.log && echo '!!! Stata dofile error?' && exit 1; else exit 0; fi"
#                     ]
#     }

# - [ ] NOTE(2015-12-30): assume cr_units will fail too, task not written

def task_cr_preflight_occupancy():
    """Prepare working_occupancy.dta from working.dta and working_occupancy24 """

    return {
        "file_dep": ["prep/cr_preflight_occupancy.do",
                    "data/original/working_occupancy24.dta",
                    "data/working.dta"],
        "targets":  ["data/working_occupancy.dta"],
        "actions":  ["stata-mp -bq do ${PWD}/prep/cr_preflight_occupancy.do",
                    "mv cr_preflight_occupancy.log logs/cr_preflight_occupancy.log",
                    "if tail logs/cr_preflight_occupancy.log | egrep 'r(\d+)' -c; then tail logs/cr_preflight_occupancy.log && echo '!!! Stata dofile error?' && exit 1; else exit 0; fi"
                    ] 
    }

def task_cr_working_tails():
    """Prepare working_tails.dta"""

    return {
        "file_dep": ["prep/cr_working_tails.do",
                    "data/original/working_tails.dta"],
        "targets":  ["data/working_tails.dta"],
        "actions":  ["stata-mp -bq do ${PWD}/prep/cr_working_tails.do",
                    "mv cr_working_tails.log logs/cr_working_tails.log",
                    "if tail logs/cr_working_tails.log | egrep 'r(\d+)' -c; then tail logs/cr_working_tails.log && echo '!!! Stata dofile error?' && exit 1; else exit 0; fi"
                    ] 
    }

def task_cr_working_occ():
    """Prepare working_occupancy.dta from working.dta and working_occupancy24 """

    return {
        "file_dep": ["prep/cr_working_occ.do",
                    "data/working_occupancy.dta",
                    "data/working_tails.dta",
                    "data/unitsFinal.dta",
                    "data/working.dta"],
        "targets":  ["data/working_merge.dta"],
        "actions":  ["stata-mp -bq do ${PWD}/prep/cr_working_occ.do",
                    "mv cr_working_occ.log logs/cr_working_occ.log",
                    "if tail logs/cr_working_occ.log | egrep 'r(\d+)' -c; then tail logs/cr_working_occ.log && echo '!!! Stata dofile error?' && exit 1; else exit 0; fi"
                    ] 
    }

def task_results_spotearly_do():
    """Prepare working_postflight.dta from working.dta and working_merge """

    return {
        "file_dep": ["prep/results_spotearly.do",
                    "data/working_merge.dta",
                    "data/working.dta"],
        "targets":  ["data/working_postflight.dta"],
        "actions":  ["stata-mp -bq do ${PWD}/prep/results_spotearly.do",
                    "mv results_spotearly.log logs/results_spotearly.log",
                    "if tail logs/results_spotearly.log | egrep 'r(\d+)' -c; then tail logs/results_spotearly.log && echo '!!! Stata dofile error?' && exit 1; else exit 0; fi"
                    ] 
    }

def task_cr_survival():
    """Prepare working_survival and working_survival_single"""

    return {
        "file_dep": ["prep/cr_survival.do",
                    "data/working_postflight.dta"],
        "targets":  ["data/working_survival.dta",
                    "data/working_survival_single"],
        "actions":  ["stata-mp -bq do ${PWD}/prep/cr_survival.do",
                    "mv cr_survival.log logs/cr_survival.log",
                    "if tail logs/cr_survival.log | egrep 'r(\d+)' -c; then tail logs/cr_survival.log && echo '!!! Stata dofile error?' && exit 1; else exit 0; fi"
                    ] 
    }

def task_results_spotearly_R():
    """Prepare paper-spotepi.RData"""

    return {
        "file_dep": ["prep/results_spotearly.R",
                    "data/working_postflight.dta",
                    "data/working_occupancy.dta",
                    "data/sites.dta",
                    "data/unitsFinal.dta"
                    ],
        "targets":  ["data/paper-spotepi.RData"],
        "actions": ["R CMD BATCH prep/results_spotearly.R ../logs/results_spotearly.Rout"]
    }

#      _____                                            _ _       
#     |  __ \                                          | | |      
#     | |__) |_ _ _ __   ___ _ __   _ __ ___  ___ _   _| | |_ ___ 
#     |  ___/ _` | '_ \ / _ \ '__| | '__/ _ \/ __| | | | | __/ __|
#     | |  | (_| | |_) |  __/ |    | | |  __/\__ \ |_| | | |_\__ \
#     |_|   \__,_| .__/ \___|_|    |_|  \___||___/\__,_|_|\__|___/
#                | |                                              
#                |_|                                              



def task_table1():
    """Prepare Table 1"""
    # - [ ] NOTE(2015-12-31): be careful: do not delete target - contains
    #   formatting and caption for table

    return {
        "file_dep": ["tables/tb_table1_all.R",
                    "data/paper-spotepi.RData"],
        "targets":  ["write/tables/table1_all.xlsx"],
        "actions": ["R CMD BATCH tables/tb_table1_all.R ../logs/tb_table1_all.Rout"]
    }

def task_sfig_hazard_survival():
    """Prepare hazard and survival - all (in eps format)"""

    return {
        # "uptodate": [False], # forces task to run - useful when debugging
        "file_dep": ["figures/fg_hazard_and_survival_all.do",
                    "data/working_survival.dta"],
        "targets":  ["write/figures/hazard_and_survival_all.eps"],
        "actions":  ["stata-mp -bq do ${PWD}/figures/fg_hazard_and_survival_all.do",
                    "mv fg_hazard_and_survival_all.log logs/fg_hazard_and_survival_all.log",
                    "if tail logs/fg_hazard_and_survival_all.log | egrep 'r(\d+)' -c; then tail logs/fg_hazard_and_survival_all.log && echo '!!! Stata dofile error?' && exit 1; else exit 0; fi"
                    ] 
    }

def task_sfig_dead7_aps():
    """Prepare supp figure dead7 vs APS (SOFA, ICNARC, NEWS)"""

    return {
        "file_dep": ["figures/fg_dead7_aps_severity.R",
                    "data/paper-spotepi.RData"],
        "targets":  [
                    "write/figures/fg_dead7_sofa.pdf",
                    "write/figures/fg_dead7_icnarc.pdf",
                    "write/figures/fg_dead7_news.pdf"
                    ],
        "actions": ["R CMD BATCH figures/fg_dead7_aps_severity.R ../logs/fg_dead7_aps_severity.Rout"]
    }

def task_table_incidence_all():
    """Run incidence model in Stata (all patients)"""

    return {
        # "uptodate": [False], # forces task to run - useful when debugging
        "file_dep": ["tables/tb_model_count_news_all.do",
                    "data/working_postflight.dta",
                    "data/sites.dta"],
        "targets":  ["write/tables/tb_incidence_news_all.csv"],
        "actions":  ["stata-mp -bq do ${PWD}/tables/tb_model_count_news_all.do",
                    "mv tb_model_count_news_all.log logs/tb_model_count_news_all.log",
                    "if tail logs/tb_model_count_news_all.log | egrep 'r(\d+)' -c; then tail logs/tb_model_count_news_all.log && echo '!!! Stata dofile error?' && exit 1; else exit 0; fi"
                    ] 
    }

def task_table_incidence_high():
    """Run incidence model in Stata (NEWS high risk)"""

    return {
        # "uptodate": [True], # forces task to run - useful when debugging
        "file_dep": ["tables/tb_model_count_news_high.do",
                    "data/working_postflight.dta",
                    "data/sites.dta"],
        "targets":  ["write/tables/tb_incidence_news_high.csv"],
        "actions":  ["stata-mp -bq do ${PWD}/tables/tb_model_count_news_high.do",
                    "mv tb_model_count_news_high.log logs/tb_model_count_news_high.log",
                    "if tail logs/tb_model_count_news_high.log | egrep 'r(\d+)' -c; then tail logs/tb_model_count_news_high.log && echo '!!! Stata dofile error?' && exit 1; else exit 0; fi"
                    ] 
    }

def task_sfig_count_news_high_rcs():
    """Plot restricted cubic spline of incidence vs case finding model
    (Supplementary Figure 3"""

    return {
        "uptodate": [False], # forces task to run - useful when debugging
        "file_dep": ["tables/tb_model_count_news_high.do",
                    "figures/fg_count_news_high_rcs.do"
                    ],
        "targets":  ["write/figures/count_news_high_rcs.eps"],
        "actions":  ["stata-mp -bq do ${PWD}/figures/fg_count_news_high_rcs.do",
                    "mv fg_count_news_high_rcs.log logs/fg_count_news_high_rcs.log",
                    "if tail logs/fg_count_news_high_rcs.log | egrep 'r(\d+)' -c; then tail logs/fg_count_news_high_rcs.log && echo '!!! Stata dofile error?' && exit 1; else exit 0; fi"
                    ] 
    }

def task_sfig_occupancy_over_time():
    """Plot occupacny over time"""

    return {
        "uptodate": [False], # forces task to run - useful when debugging
        "file_dep": ["figures/fg_occupancy_over_time.R",
                    "data/working_occupancy.dta"],
        "targets":  [
                    "write/figures/fg_occupancy_over_time.jpg"
                    ],
        "actions": ["R CMD BATCH figures/fg_occupancy_over_time.R ../logs/fg_occupancy_over_time.Rout"]
    }


def task_tb_occupancy_effects_all():
    """Prepare Table 2 - occupancy (all patients)"""
    # - [ ] NOTE(2015-12-31): be careful: do not delete target - contains
    #   formatting and caption for table

    return {
        "file_dep": ["tables/tb_table1_occupancy_effects.R",
                    "data/paper-spotepi.RData"],
        "targets":  ["write/tables/tb_occupancy_effects_all.xlsx"],
        "actions": ["R CMD BATCH tables/tb_table1_occupancy_effects.R ../logs/tb_table1_occupancy_effects.Rout"]
    }

def task_tb_occupancy_effects_reco():
    """Prepare Table 2 - occupancy (recommended patients)"""
    # - [ ] NOTE(2015-12-31): be careful: do not delete target - contains
    #   formatting and caption for table

    return {
        "file_dep": ["tables/tb_table1_occupancy_effects_reco.R",
                    "data/paper-spotepi.RData"],
        "targets":  ["write/tables/tb_occupancy_effects_reco.xlsx"],
        "actions": ["R CMD BATCH tables/tb_table1_occupancy_effects_reco.R ../logs/tb_table1_occupancy_effects.Rout"]
    }

def task_tb_model_icu_accept_all():
    """Prepare Table 3a - decision to admit (all admissions)"""
    return {
        # "uptodate": [False], # forces task to run - useful when debugging
        "file_dep": ["tables/tb_model_logistic.R",
                    "data/paper-spotepi.RData"],
        # Debugging version
        # "targets":  ["write/tables/tb_model_accept_all_sims10.xlsx"],
        "targets":  ["write/tables/tb_model_accept_all_sims100.xlsx"],
        # Use Rscript not R CMD BATCH b/c accepts command line args then tee pipes to file and stout
        # Debugging version
        # "actions": ["Rscript tables/tb_model_logistic.R --outcome=icu_accept --subgrp=all --nsims=10 | tee ../logs/tb_model_icu_accept_all.Rout"]
        "actions": ["Rscript tables/tb_model_logistic.R --outcome=icu_accept --subgrp=all --nsims=100 | tee ../logs/tb_model_icu_accept_all.Rout"]
    }

def task_tb_model_icu_accept_recommend():
    """Prepare Table 3b - decision to admit (those recommended)"""
    # - [ ] NOTE(2015-12-31): be careful: do not delete target - contains
    #   formatting and caption for table
    # - [ ] TODO(2016-01-19): the dependency checking doesn't seem to work

    # - [ ] NOTE(2016-01-19): **UNCOMMENT BOTH TARGET AND ACTION LINES WHEN SWITCHING TO LIVE VERSION
    return {
        # "uptodate": [False], # forces task to run - useful when debugging
        "file_dep": ["tables/tb_model_logistic.R",
                    "data/paper-spotepi.RData"],
        # Debugging version
        # "targets":  ["write/tables/tb_model_accept_recommend_sims10.xlsx"],
        "targets":  ["write/tables/tb_model_accept_recommend_sims100.xlsx"],
        # Debugging version
        # "actions": ["Rscript tables/tb_model_logistic.R --outcome=icu_accept --subgrp=icu_recommend --nsims=10 | tee ../logs/tb_model_icu_accept_recommend.Rout"]
        "actions": ["Rscript tables/tb_model_logistic.R --outcome=icu_accept --subgrp=icu_recommend --nsims=100 | tee ../logs/tb_model_icu_accept_recommend.Rout"]
    }

def task_tb_model_icu_accept_all_siteonly():
    """Extract Median Odds Ratio without adjustment for patient level factors"""
    return {
        # "uptodate": [False], # forces task to run - useful when debugging
        "file_dep": ["tables/tb_model_logistic.R",
                    "data/paper-spotepi.RData"],
        # Debugging version
        # "targets":  ["write/tables/tb_model_accept_all_sims10_siteonly.xlsx"],
        "targets":  ["write/tables/tb_model_accept_all_sims100_siteonly.xlsx"],
        # Use Rscript not R CMD BATCH b/c accepts command line args then tee pipes to file and stout
        # Debugging version
        "actions": ["Rscript tables/tb_model_logistic.R --siteonly --outcome=icu_accept --subgrp=all --nsims=100 | tee ../logs/task_tb_model_icu_accept_all_siteonly.Rout"]
    }


def task_tb_model_icu_early4_all():
    """Prepare Table - early admission (all admissions)"""
    return {
        # "uptodate": [False], # forces task to run - useful when debugging
        "file_dep": ["tables/tb_model_logistic.R",
                    "data/paper-spotepi.RData"],
        # Debugging version
        # "targets":  ["write/tables/tb_model_early4_all_sims10.xlsx"],
        "targets":  ["write/tables/tb_model_early4_all_sims100.xlsx"],
        # Use Rscript not R CMD BATCH b/c accepts command line args then tee pipes to file and stout
        # Debugging version
        # "actions": ["Rscript tables/tb_model_logistic.R --outcome=icu_accept --subgrp=all --nsims=10 | tee ../logs/tb_model_early4_all.Rout"]
        "actions": ["Rscript tables/tb_model_logistic.R --outcome=icu_accept --subgrp=all --nsims=100 | tee ../logs/tb_model_early4_all.Rout"]
    }

def task_tb_model_survival_all():
    """Prepare Table - survival (no limits)"""
    return {
        # "uptodate": [False], # forces task to run - useful when debugging
        "file_dep": ["tables/tb_model_survival.R",
                    "data/paper-spotepi.RData"],
        # Debugging version
        # "targets":  ["write/tables/tb_model_early4_all_sims10.xlsx"],
        "targets":  ["write/tables/tb_model_survival_nolimits__sims100.xlsx"],
        # Debugging version
        "actions": ["Rscript tables/tb_model_survival.R --subgrp=nolimits --nsims=100 | tee ../logs/tb_model_survival_nolimits__sims100.Rout"]
    }

def task_tb_model_survival_siteonly():
    """Prepare Table - survival (no limits)"""
    return {
        # "uptodate": [False], # forces task to run - useful when debugging
        "file_dep": ["tables/tb_model_survival.R",
                    "data/paper-spotepi.RData"],
        "targets":  ["write/tables/tb_model_survival_nolimits__sims100_siteonly.xlsx"],
        "actions": ["Rscript tables/tb_model_survival.R --subgrp=nolimits --siteonly --nsims=100 | tee ../logs/tb_model_survival_nolimits__sims100_siteonly.Rout"]
    }


#      _____                                                            _       _   
#     |  __ \                                                          (_)     | |  
#     | |__) | __ ___ _ __    _ __ ___   __ _ _ __  _   _ ___  ___ _ __ _ _ __ | |_ 
#     |  ___/ '__/ _ \ '_ \  | '_ ` _ \ / _` | '_ \| | | / __|/ __| '__| | '_ \| __|
#     | |   | | |  __/ |_) | | | | | | | (_| | | | | |_| \__ \ (__| |  | | |_) | |_ 
#     |_|   |_|  \___| .__/  |_| |_| |_|\__,_|_| |_|\__,_|___/\___|_|  |_| .__/ \__|
#                    | |                                                 | |        
#                    |_|                                                 |_|        

def task_results():
    """Convert R markdown results sections of manuscript"""
    # - [ ] TODO(2016-06-02): rmarkdown build for abstract
    # - [ ] TODO(2016-06-02): rmarkdown build for results


def task_manuscript():
    """Prepare manuscript"""
    return {
        # "uptodate": [True], # forces task to run - useful when debugging
        "targets":  ["write/manuscript/paper.docx"],
        "actions": [
            """pandoc \
                --smart \
                --normalize \
                --reference-docx=write/manuscript/pandoc-reference.docx  \
                write/1_title.md \
                write/what_this_paper_adds.md \
                write/2_abstract.md \
                write/3_intro.md \
                write/4_methods.md \
                write/5_results.md \
                write/6_discussion.md \
                -o write/manuscript/paper.docx"""]
    }