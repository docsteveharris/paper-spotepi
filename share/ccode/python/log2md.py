#!/usr/bin/python

#  ## log2md - utility to convert stata log to markdown
# _____________________________________________________
# CreatedBy:	Steve Harris

# CreatedAt: 	120621
# ModifiedAt:	120621

# Filename:	log2md.py
# Project:

# ## Description
# Phase 1
# - pass a stata log file ont the command line
# - then run through the file and
#	- remove the prepend of single line comments
#	- remove the . prepend
#	- handle line continuation characters >
#	- convert everything between /* */ markers to text
#	- convert everything else to a code block

# Phase 2
# - insert graphs as inline images with links



# - write this out as an md file
# - consider producing a pdf at the same time?

# ## Dependencies

# - pandoc installation? if you convert out at the end

# ____

# Step 1 get the file
# Open and read it line by line
# Print it back to the new file

import os
import re    	# regular expressions
import sys   	# file input / output
import string	# string routines
import argparse

debug = False
#  ====================
#  = Define functions =
#  ====================

def check_file(path2check,filename_regex):
    """
    Check proposed file name is OK
    Needs a string containing the proposed path
    Needs a regex to check the filename format
    """


    # check string is valid path
    if not os.path.isfile(path2check):
        print "Error: %s is not a file\n" % path2check
        sys.exit(1)

    filepath, filename = os.path.split(path2check)
    if not filename_regex.match(filename):
        print "Error: Expects *.do/txt/log but got %s" % filename
        sys.exit(1)

    return filename, filepath


#  ===========================
#  = Parse command line args =
#  ===========================
parser = argparse.ArgumentParser(description =
    """Usage: log2md stata_log.txt ... will then convert "stata_log.txt" to stata_log.md""")
# Mandatory args (positional)
parser.add_argument("given_filepath", help=":path to log file to convert")
args = parser.parse_args()
parser.parse_args()

# define the regex to match the filename
filename_regex = re.compile(r"""\w+?\.[txt|log|do]""")
filename, filepath = check_file(args.given_filepath, filename_regex)
print filename, filepath


with open(args.given_filepath, 'r') as input_file_object:
	file_text = input_file_object.read()

# print file_text

# Compile regular expressions
horizontal_line		= re.compile(r"""^`|-|\*+$""")
log_date_line		= re.compile(r"""^\s*(opened|paused|resumed) on:.*$""")
log_path_line		= re.compile(r"""/users/steve/""", re.IGNORECASE)
line_continuation 	= re.compile(r"""^>.*$""")

comment_prepend  	= re.compile(r"""^\s*\*(?!/) ?""")
comment_block_start 	= re.compile(r"""^\s*/\*""")
comment_block_end 		= re.compile(r"""^\s*\*/""")
comment_block_end_same_line	= re.compile(r"""^.*?\s*\*/""")
# CHANGED: 2012-11-13 - now will not match /// but will match //
comment_append		= re.compile(r"""\s//(?!/).*$""")
commented_out  	= re.compile(r"""^\s*// ?""")

comment_header = re.compile(r"""^\s*=\s*(.*?)=.*$""")
figure_path = re.compile(r"""\s*graph export \.\./logs/(.*?),.*""")

# Now parse each line of text and write it out

old_lines = file_text.splitlines(0)
print "Length: %d" % len(old_lines)
i=0
new_lines = [""]
new_text = ""
comment_block_flag = False

for line in old_lines:
	command_line_flag = False
	# handle command input or command lines which start with a period
	if len(line)>0 and (line[0]=="." or line[0] == ">"):
		new_line = line[2:]
		command_line_flag = True
	else:
		new_line = line

	# Line continuation found
	if line_continuation.match(new_line) and command_line_flag == True:
		new_line = new_lines.pop() + new_line[1:]
		new_lines.append(new_line)
		continue


	# remove horizontal line
	if horizontal_line.match(new_line) and i == 0:
		new_line = """___"""
	# remove dates
	if log_date_line.match(new_line):
		new_line = """"""
	# remove log path
	if log_path_line.search(new_line):
		continue

	comment_flag = False
	comment_to_add_flag = False
	# remove comment prepends
	if comment_prepend.match(new_line):
		new_line = comment_prepend.sub("", new_line) + "  \n"
		comment_flag = True
	elif commented_out.match(new_line):
		new_line = "* " + commented_out.sub("", new_line) + "  \n"
		comment_flag = False
	# Look for inline comment blocks
	elif comment_block_start.match(new_line):
		comment_block_flag = True
		new_line = comment_block_start.sub("", new_line) + "  \n"
		# Now check to see if the comment also ends on this line
		if comment_block_end_same_line.match(new_line):
			new_line = comment_block_end_same_line.sub("", new_line) + "  \n"
			comment_block_flag = False
	elif comment_block_end.match(new_line):
		comment_block_flag = False
		new_line = comment_block_end.sub("", new_line) + "  \n    "
	# Look for appended comments
	elif comment_append.findall(new_line):
		comment_to_add_flag = True
		comment_to_add = string.strip(comment_append.findall(new_line)[0]) + "  \n"
		# print comment_to_add
		new_line = comment_append.sub("", new_line)

	# Otherwise prepend 4 spaces (indicates code)
	if comment_block_flag == False and comment_flag == False:
		# CHANGED: 2012-11-13 - using backticks for each line if not comment
		# CHANGED: 2012-11-13 - changed back: does not compile with backticks
		new_line = """    """ + new_line + """"""

	# Finally ...
	if comment_to_add_flag == True:
		new_lines.append(comment_to_add)
	if comment_header.match(new_line):
		new_line = comment_header.match(new_line).group(1)

	print "old: %s \nnew: %s" % (line, new_line)
	new_lines.append(new_line)

	# Figures and images
	if figure_path.match(new_line):
		path_to_figure = figure_path.match(new_line).group(1)
		md_link = """\n  \n  ![stata_figure](%s)\n  \n  """ % path_to_figure
		new_lines.append(md_link)

	# break early while debugging
	i += 1
	if i > 50:
		if debug:
			break

# ending code block delimiter
# new_lines.append("""``""")

# add 2 spaces before the new line to ensure prints OK
# print '%s' % '  \n'.join(new_lines)
text_out =	'%s' % '  \n'.join(new_lines)


print "New length: %d" % len(new_lines)
print "Completed\n"

#  =====================
#  = Now save the text =
#  =====================
file_out = filepath + "/" + re.sub(r"""(?<=\w)\.\w{3}\b""",".md",filename)
# print file_out
with open(file_out, 'w') as output_file_object:
	output_file_object.write(text_out)

print "OK: Success - log2md complete"
