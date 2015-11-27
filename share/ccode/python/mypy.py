"""
This is a docstring.
It marks the beginning of this module file.
Module files are libraries of python code
Don't forget to import other modules that will be needed at the beginning
"""
import sys
import re


def printsyspath():
    print 'Your sys.path is ...\n'
    print sys.path

def printhello(name):
    print "Hello %s" % name


def sql_multistmt(cursor, multi_statement):
    """
    Parse and execute a block of SQL statements one by one
    Needs a cursor object and statement string
    NB: Only handles /* */ comment types not line prefixed comments --
    """
    # regex that with positive look behind for ';' as line terminator
    sql_line = re.compile(r"""
                \n+         # starting from a new line sequence
                (?!(--|\n)) # if not followed by a comment start "--" 
                (.*?)       # need brackets here else doesn't match
                (?=;)       # ending with a semicolon
                          """, re.DOTALL|re.VERBOSE|re.MULTILINE)
    stmts = sql_line.findall(multi_statement)

    # print stmts

    for stmt in stmts:
        stmt = stmt[1]
        # remove unnecessary whitespace 
        # CHANGED: 2012-08-12 - substitute with single white space else
        # new liaWnes indented with tabs will merge with previous lines
        stmt = re.sub(r"[\n|\t|\r|\f]", ' ', stmt) + ';'
        if len(stmt) > 0:
            # DEBUGGING: 2012-10-01 - commented out below
            # print stmt
            # print
            cursor.execute(stmt)

