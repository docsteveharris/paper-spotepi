# doit file for Norad project
from __future__ import print_function

#  ============================
#  = Create data for analysis =
#  ============================

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