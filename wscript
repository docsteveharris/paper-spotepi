#! python
# encoding: utf-8

# author: Steve Harris
# date: 2015-11-27
# subject: waf script to build and run paper-spotepi

# Readme
# ======
# Moving build system over to waf from make
# Some of the initial set-up
# shares the same python script and temporary file which leads to
# errors. You can get round this by running the scripts in serial rather
# than parallel. Use the -j1 switch in waf


# Todo
# ====


# Log
# ===
# 2015-11-27
# - file created (duplicated from paper-spotearly)

print("*****: STARTING WAF: Welcome to paper-spotepi")

# Load python libs
import os, sys

# Check MySQL server is running
shell_cmd = 'mysql.server status | grep -i success'
if len(os.popen(shell_cmd).read()) == 0:
    print("!!!!!: ERROR: Is MySQL running?")
    sys.exit(1)

# Standard waf architecture starts here
# The project root directory and the build directory.
top = '.'     # making root one dir up to separate data out of version control
out = 'bld'

def set_project_paths(ctx):
    """Return a dictionary with project paths represented by Waf nodes."""

    pp = {}
    pp['PROJECT_ROOT'] = '.'
    pp['CODE'] = '.'
    # pp['DATA'] = '{}/out/data'.format(out)
    pp['DATA'] = 'data'
    pp['DATA_ORIGINAL'] = 'data/original'
    pp['LOGS'] = 'logs'
    pp['FIGURES'] = 'figures'
    pp['TABLES'] = 'tables'

    # Convert the directories into Waf nodes.
    for key, val in pp.items():
        pp[key] = ctx.path.make_node(val)

    return pp

def path_to(ctx, pp_key, *args):
    """Return the relative path to os.path.join(*args*) in the directory
    PROJECT_PATHS[pp_key] as seen from ctx.path (i.e. the directory of the
    current wscript).

    Use this to get the relative path---as needed by Waf---to a file in one
    of the directory trees defined in the PROJECT_PATHS dictionary above.

    We always pretend everything is in the source directory tree, Waf takes
    care of the correct placing of targets and sources.

    """

    # Implementation detail:
    #   We find the path to the directory where the file lives, so that
    #   we do not accidentally declare a node that does not exist.
    dir_path_in_tree = os.path.join('.', *args[:-1])
    # Find/declare the directory node. Use an alias to shorten the line.
    pp_key_fod = ctx.env.PROJECT_PATHS[pp_key].find_or_declare
    dir_node = pp_key_fod(dir_path_in_tree).get_src()
    # Get the relative path to the directory.
    path_to_dir = dir_node.path_from(ctx.path)
    # Return the relative path to the file.
    return os.path.join(path_to_dir, args[-1])

def configure(ctx):
    ctx.env.PYTHONPATH = os.getcwd()
    # Disable on a machine where security risks could arise
    ctx.env.PDFLATEXFLAGS = '-shell-escape'
    # ctx.load('biber')
    ctx.load('run_py_script')
    ctx.load('run_r_script')
    ctx.load('run_do_script')
    # ctx.load('sphinx_build')
    ctx.load('write_project_headers')


# 	 ______           _          __    __ _ _      
# 	|  ____|         | |        / _|  / _(_) |     
# 	| |__   _ __   __| |   ___ | |_  | |_ _| | ___ 
# 	|  __| | '_ \ / _` |  / _ \|  _| |  _| | |/ _ \
# 	| |____| | | | (_| | | (_) | |   | | | | |  __/
# 	|______|_| |_|\__,_|  \___/|_|   |_| |_|_|\___|
# 	                                               
# 	                                               
print("*****: ENDING WAF: Welcome to paper-spotepi")