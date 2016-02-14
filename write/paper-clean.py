#! python
# NOTE: 2015-01-16 - [ ] shebang will use local version of python
# author: Steve Harris
# date: 2015-01-16
# subject:

# Readme
# ======
# Text cleaning - including as many of the pedantic checks as possible
# Ideally produce a report as well as make the edits
# - do this by piping / redirect
# Should organise by function


# Todo
# ====
# - change to 0 decimal places for percentages
# - check that have incorporated all of Merv's feedback
# - em-dashes etc
# - en-dashes in tables need to go to actual characters if in office




# Log
# ===
# 2015-01-16
# - file created
# - intial working version for error correction only
# 2015-01-17
# - now handles UTF8 decode and encode correctly
# - opens a version in Marked for inspection
# - factored out dictionary functions
#   to permit separate error and review dicts
#   takes filename from commandline

# Build interactively
from __future__ import print_function, unicode_literals
import os, re, sys
import subprocess

try:
    print(sys.argv)
    _file = sys.argv[1]
    print(_file)
except Exception as e:
    print(e)
    print("You must pass the filename to the script: ", _file)
    sys.exit(1)

# Global vars
# ===========
_file_path, _file_basename = os.path.split(_file)
_file_name, _file_ext = os.path.splitext(_file)
print(_file_path, _file_basename, _file_ext)
# Use Marked app to inspect file when finished
_app = r"/Applications/Marked\ 2.app"

# Use this for debugging
_text_in = """
### Patient pathways


A total of 3279 (26\%) patients were offered critical care at the end of the bedside assessment. These patients were younger (by 1.5 years [95\%CI 0.7--2.2]), and more acutely ill (an additional 4.4 ICNARC physiology points [95\%CI 4.1--4.8]). Patients older than 80 years were less likely to be offered admission (OR 0.55 [95\%CI (0.47--0.65)]) even after risk adjustment (Table 2).
"""

# TODO: 2015-01-17 - [ ] factor this out int a YAML dictionary
_errors = {
    "decimal":                  # item name
        [r"(\d+)(\.)(?=\d+)",   # regular expression to match
        r"\1\u00b7"]                # replacement
    ,
    "repeated_spaces":
        [r" {2,}", r" "]        # avoid \s - would capture \n
    ,
    "triple_newlines":
        [r"\n{3,}", r"\n\n"]
    ,
    "trailing_spaces":
        [r"(?m)[ \t]+$", r""]
    ,
    "critic_markup_comment":
        [r"\{>>.*?<<\}", r""]
    ,
    "pandoc_citation2bookends1":
        [r"\[((?=.*?@).*?)\]", r"{\1}"]
    # ,                         # disabled since this stops 1 above?
    # "pandoc_citation2bookends2": 
    #     [r"(@)(.*?\W)", r"\2"]
    }


# Items to be reviewed
_highlight_match = r"__\1__"
_checks_generic = {
    # check capitalised correctly
    "level_of_care":
        [r"(levels? of care|level [0123])",
        _highlight_match]
    ,
"past_not_present_tense":
        [r"(\bis\b|\bare\b)",
        _highlight_match]
    ,
"hyphenate_xx_day_if_noun":
        [r"(\b\d+\-days?(?! +(mortality|survival)))",
        _highlight_match]
        ,
"hyphenate_xx-day_if_adjective":
        [r"(\b\d+ days?(?= +(mortality|survival)))",
        _highlight_match]
,
        "plural_data":
            [r"(the|this)(?= data\b)|((?<=data ) *is\b)",
            _highlight_match]


}
# Items to be reviewed that are likely specific to this document
_checks_specific = {
    "hospitals_not_sites":
    [r"(?i)(\bsites?\b)",
    _highlight_match]
}
_checks = dict(_checks_generic.items() + _checks_specific.items())

def dict_compile(_dict=None):
    """
    Take dictionary & return compiled regex objects
    Run alone so that compile is only done once
    Dictionary structure: Name: [regex_to_match, regex_to_replace]
    """
    dict_clean = {}
    for _key, _val in _dict.items():
        print(_key)
        dict_clean[_key] = [re.compile(_val[0]), _val[1]]
    return dict_clean


def re_dict_clean(_t_in, re_dict):
    """
    Compile regular expressions if not already done
        by calling re_dict_compile
    Then cleans text for each item found in the dictionary
    Returns the cleaned text
    """
    _t_out = _t_in
    for _val in re_dict.values():
        _t_out = _val[0].sub(_val[1], _t_out)
    return _t_out


# Put the main code in here
if __name__ == '__main__':
    # Load file to be cleaned
    try:
        with open(_file) as _f:
            _t_orig = _f.read()
            _text_in = _t_orig.decode("utf8")
    except Exception as e:
        print(e)
        print("Could not open file named: ", _file)
        sys.exit(1)

    # Prepare dictionaries
    _errors = dict_compile(_errors)
    _checks = dict_compile(_checks)

    # Clean errors
    # ------------
    _text_out = re_dict_clean(_text_in, re_dict = _errors)
    print(_text_out.encode("utf8"))

    # Mark for checks for review
    # --------------------------
    _text_review = re_dict_clean(_text_out, re_dict = _checks)


    # Save a back-up
    with open(_file_name + '.bak', 'w') as _f_bak:
        _chk = _f_bak.write(_t_orig)

    # Save a (review) copy and open with Marked to inspect
    _text_review = _text_review.encode("utf8")
    _f_tmp = os.path.expanduser("~/tmp/" + _file_name + "_review" + _file_ext)
    with open(_f_tmp, 'w') as _f_out:
        _chk = _f_out.write(_text_review)
        _proc = subprocess.Popen("open -a %s %s" % (_app, _f_tmp), shell=True)

    # Save the new work
    # Convert back from UTF8
    _text_out = _text_out.encode("utf8")
    with open(_file, 'w') as _f_out:
        _chk = _f_out.write(_text_out)


    sys.exit(0)

