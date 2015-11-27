#!/usr/local/bin/python
# Take clipboard and pre-pend 4 spaces before each line
# hence format as code in python
#import sys
#sys.path.append("/Users/steve/usr/local/lib")
import pyperclip
clipboard = pyperclip.paste()
lines = clipboard.splitlines(True)
clipboard = ''.join(['    ' + line for line in lines])
# print clipboard
pyperclip.copy(clipboard)
# Return 0 if script terminated OK
print 0
