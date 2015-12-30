# doit file for Norad project
from __future__ import print_function

def task_cr_working():
    """Build working.dta from working_raw_epi.dta
    This last file is stored on the 'phd' encrypted volume"""

    # print("Running cr_working.do via Stata")

    return {
        "file_dep": ["prep/cr_working.do", "data/original/working_raw_epi.dta"],
        "targets": ["data/working_all.dta", "data/working.dta", "logs/cr_working.txt"],
        "actions":  ["stata-mp -bq do ${PWD}/prep/cr_working.do",
                    "mv cr_working.log logs/cr_working.log",
                    "if tail logs/cr_working.log | egrep 'r([:digit:]+)' -c; then tail logs/cr_working.log && echo '!!! Stata dofile error?' && exit 1; else exit 0; fi"
           ] 
    }


