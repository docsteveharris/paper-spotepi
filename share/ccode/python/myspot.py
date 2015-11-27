#!/usr/local/bin/python
# Module of functions that I am regularly re-using in the SPOT work
# Steve Harris
# 120727

import sys
sys.path.append('/usr/local/lib/python2.7/site-packages')

#  =========================================
#  = Main function module for spot project =
#  =========================================

import mypy     # my python functions
import os       # interaction with operating system
import re       # regular expressions
import yaml     # YAML parser
# import pymysql  # CHANGED: 2014-01-27 - replaces MySQLdb
import MySQLdb  # MySQL database wrapper
import xlrd
import datetime
import time     # Contains the strptime for string -> date/time conversion

global XL_DATEMODE
# global XL_CELL_EMPTY  =   0 # empty string u''
# global XL_CELL_TEXT   =   1 # a Unicode string
# global XL_CELL_NUMBER     =   2 # float
# global XL_CELL_DATE   =   3 # float
# global XL_CELL_BOOLEAN    =   4 # int; 1 means TRUE, 0 means FALSE
# global XL_CELL_ERROR  =   5 # int representing internal Excel codes; for a text representation, refer to the supplied dictionary error_text_from_code
# global XL_CELL_BLANK  =   6 # empty string u''. Note: this type will appear only when open_workbook(..., formatting_info=True) is used.


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

    filename = os.path.basename(path2check)
    if not filename_regex.match(filename):
        print "Error: Expected SIT_YYMMDD.xls, but got %s" % filename
        sys.exit(1)


def extract_fields_from(sql_stmt):
    "Return a list of fields from an SQL SELECT ... FROM statements"
    # first extract everything between SELECT ... FROM
    sql_select_fields = re.match(
        r'.*?SELECT(.*?)FROM\s',
        sql_stmt, re.IGNORECASE | re.DOTALL).group(1)
    # now remove everything inside brackets (i.e. functions)
    delimited = False
    clean = []
    stack = []

    # print sql_select_fields
    for ch in sql_select_fields:
        if ch in "\n":
            continue

        if ch in "([{":
            stack.append(ch)
            delimited = True
        elif (ch in "})]" and len(stack) > 0
            and {")": "(", "]": "[", "}": "{"}[ch] == stack[-1]):
            stack.pop()

        elif len(stack) == 0:
            delimited = False

        if not delimited:
            clean.append(ch)

    sql_select_fields = ''.join(clean)
    # print sql_select_fields

    sql_select_fields = re.findall(r"(\w+\s*)(?=,|FROM|$)", sql_select_fields, re.IGNORECASE)
    # print sql_select_fields

    sql_select_fields = [re.sub(r'\s|\t|\r|\n', '', f) for f in sql_select_fields]
    # sys.exit(1)
    return sql_select_fields


def get_yaml_dict(dict_name, return_type='list', local_dict=False, path_to=None):
    """
    Read in yaml file
    - field dictionary
    - table dictionary
    Return a Python data object
    - if local_dict = True then will use relative path to /local/lib_phd
    - assumes that code is running in project dir which also contains above dir
    """
    if local_dict:
        if path_to is None:
            path_to = os.path.join(os.getcwd(),'share/specs/')
        else:
            path_to = path_to + '/'
    else:
        path_to = '/Users/Steve/usr/lib/uni/lib_phd/'

    if dict_name == 'field':
        dict_file = 'dictionary_fields.yml'
    elif dict_name == 'table':
        dict_file = 'dictionary_tables.yml'
    elif dict_name == 'checks':
        dict_file ='dictionary_checks.yml'
    elif dict_name == 'corrections':
        dict_file = 'dictionary_corrections.yml'
    else:
        print "ERROR: %s is not a valid dictionary name" % dict_name
        sys.exit(1)

    dict_file = path_to + dict_file
    print "NOTE: %s dictionary extracted from %s" % (dict_name, dict_file)

    # get field dictionary as python data structure
    with open(dict_file, 'r') as ffile:
        yaml_dict_as_list = yaml.load(ffile.read())

    # if dict flag is set then return as a dict rather than a list
    if return_type == 'dictionary':
        keyname =  {'field': 'fname',
                    'table': 'tablename',
                    'checks': 'checkname'}[dict_name]
        ttemp =[i[keyname] for i in yaml_dict_as_list]
        if len(ttemp) > len(set(ttemp)):
            print "ERROR: Duplicate field names found in dictionary %s" % dict_name
            sys.exit(1)
        else:
            yaml_lookup = {}
            for i in yaml_dict_as_list:
                yaml_lookup[i[keyname]] = i
            return yaml_lookup
    else:
        return yaml_dict_as_list

def clean_field_names(alias_list):
    """
    Takes a list of field aliases and returns a list of standardised names
    """
    fdict = get_yaml_dict('field')
    findex = {}
    for field in fdict:
        fname = field['fname']
        # enter the name itself
        findex[fname] = fname
        # if there is no alias then skip
        if 'talias' not in field:
            continue
        falias = field['talias'].values()
        for f in falias:
            findex[f] = fname

    clean_list = []
    for alias in alias_list:
        if alias in findex:
            clean_list.append(findex[alias])
        else:
            print "%s not found in field dictionary" % alias
            clean_list.append("ALIAS_NOT_IN_FIELD_DICT")

    return clean_list

def clean_field_aliases(alias_list, source_tab):
    """
    Takes a list of aliases (field names), and translates this to the true field name
    - if an alias is specified in 'talias' uses this
    - if a unique alias exists elsewhere in talias (that is not used as a field name) uses this
    - else looks in the list of field names
    """
    debug = False
    # import pdb; pdb.set_trace()
    fdict = get_yaml_dict('field', return_type='dictionary', local_dict = True)
    # convert all names to lower case
    fdict_fields = {k.lower(): k for k in fdict.keys()}

    source_tab = source_tab.lower()
    # Now prepare your alias lists
    alias_table, alias_unique, aliases = [], [], []
    for f, fspec in fdict.items():
        if 'talias' not in fspec:
            continue
        if len(fspec['talias']) == 0:
            continue
        for table, table_alias in fspec['talias'].items():
            if table_alias is None:
                print "ERROR: You did not complete the talias spec for %s" % f
                sys.exit(1)
            # print fspec
            # print f, table, table_alias
            # simple list of all aliases in use
            aliases.append(table_alias.lower())
            # list of aliases that only appear once
            alias_unique.append((table_alias.lower(), f.lower()))
            # list of all aliases with table specifier
            alias_table.append((table_alias.lower(), table.lower(), f.lower()))

    # remove duplicate aliases
    alias_unique = dict([i for i in alias_unique if aliases.count(i[0]) == 1])
    # keep duplicate aliases which are specified for this table
    alias_table = dict([(i[0],i[2]) for i in alias_table
            if aliases.count(i[0]) > 1 and i[1] == source_tab])

    if debug:
        print "Debugging ..."
        print alias_table
        print
        print alias_unique
        print
        print fdict.keys()

    field_list = []
    for alias in alias_list:
        alias = alias.lower()
        if alias in alias_table:
            # check first in the alias_table for aliases that are specific
            field_list.append(alias_table[alias])
        elif alias in alias_unique:
            # check among other aliases that are specified only once and should therefore be unique
            field_list.append(alias_unique[alias])
        elif alias in fdict_fields:
            # otherwise use the alias as the field name
            field_list.append(alias)
        else:
            print "WARNING: field %s not found in fdict even as alias" % alias
            field_list.append('ALIAS_NOT_IN_FIELD_DICT')
            continue

        print "NOTE: %s mapped to %s" % (alias, field_list[-1])

    # check that each alias has been resolved
    unresolved = alias_list.count('ALIAS_NOT_IN_FIELD_DICT')
    if unresolved:
        print "\nWARNING: %d aliases not resolved ... please correct field dictionary\n" % unresolved
    else:
        return field_list

def make_talias_dict(fdict):
    """
    Create a dictionary based on the talias entries
    Structure is a dictionary of dictionaries
    Key 1 = table name : Value 1 = dictionary of alias names
    Key 2 = alias name : Value 2 = true field name
    """
    talias_list = []
    for fspec in fdict:
        if 'talias' in fspec:
            if len(fspec['talias']) > 0:
                for item in fspec['talias'].items():
                    # tuple = alias, table, field
                    talias_list.append((item[1], item[0], fspec['fname']))
            else:
                talias_list.append((fspec['fname'], 'no_alias', fspec['fname']))
        else:
            talias_list.append((fspec['fname'], 'no_alias', fspec['fname']))
            # print "WARNING: no talias for ", talias_list[-1]

    # Now double check there are no duplicate entries
    if len(talias_list) != len(set(talias_list)):
        error_list = [i for i in talias_list if talias_list.count(i) > 1]
        print error_list
        print "ERROR: Duplicate table, field tuple found in among table aliases"
        # dups = [d for d in talias_list if talias_list.count(d) > 1]
        # print dups
        sys.exit(1)
    else:
        tables = set([t[1] for t in talias_list])
        talias_dict = {}
        for table in tables:
            talias_dict[table] = (
                {t[0]:t[2]  for t in talias_list if t[1] == table})

    return talias_dict

def reverse_field_dict(local_dict = True):
    """
    Reverse the field dictionary so it can be searched using field aliases
    - Returns a dictionary of dictionaries - returns everything
    - each known table has a dictionary
    - each field is then listed in that
    - with the key with the value being the true name
    """
    # print os.getcwd()
    # TODO: 2012-08-20 - this function should be retired in favour of make_talias_dict above

    # TODO: 2012-07-30 - stop looking for all tables and just work with
    # tab_name and the no_alias fields

    # Loop through field names and check to see if talias is listed
    # From this extract all tables (i.e. the keys of the talias dict)
    # Add this to your set of tables (set not list so no dups)

    # CHANGED: 2012-08-17 - local fdict may now override main dict
    # helps with localisation so you make sure you are using local repo
    fdict = get_yaml_dict('field', local_dict=local_dict)

    table_set = set()

    # for fitem in fdict:
    #   print fitem
    #   if 'talias' in fitem:
    #       print fitem['talias']
    #       table_set.update(fitem['talias'].keys())

    [table_set.update(fitem['talias'].keys())
        for fitem in fdict if 'talias' in fitem]

    # Convert table_set to a dictionary
    talias_dict = {}
    for table in table_set:
        talias_dict[table] = {}

    # Loop through all tables
    for table in talias_dict.keys():
        falias_dict = {} # empty field alias dictionary

        # inner loop through all fields
        for fitem in fdict:
            # where table aliases exist
            if fitem.has_key('talias') and len(fitem['talias']) > 0:
                # check an alias exists for this table
                if fitem['talias'].has_key(table):

                    # this is the field alias from the talias dictionary
                    # Create new dictionary entry for this table
                    # LHS: value from the talias dictionary for that field
                    # RHS: true field name

                    new_key = fitem['talias'][table]
                    falias_dict[new_key]  = fitem['fname']

        # Add a 'no_alias' key to talias dictionary for fields which have no aliases
        # now assign this dictionary to the 'no_alias' table dict item
        talias_dict[table] = falias_dict
        del falias_dict

    # fields without specified alias ...

    falias_dict = {}
    for fitem in fdict:
        # fields without specified alias ...
        if (not fitem.has_key('talias')) or len(fitem['talias']) == 0:
            fname = fitem['fname']
            falias_dict[fname] = fname

    # add no_alias dictionary to the full table dictionary
    talias_dict['no_alias'] = falias_dict

    return talias_dict

def dict_get_keys(table, t_dict):
    """
    List comprehension to filter table dicitonary
    primary key is just a list of fields
    """
    try:
        # Use list comprehension with 'if' clause as a filter
        pkeys = [item for item in t_dict
                        if item['tablename'] == table][0]['pkey']
        return pkeys
    except:
        print ("""
    ERROR: Primary key not found for table %s
    i.e. %s not found in YAML dictionary_tables
    """ % (table, table))
        sys.exit(1)


def sql_connect(
        ddatabase,
        ddsn={'host': 'localhost', 'user': 'steve', 'pass': '[po-09'},
        connection=False):
    """
    Given a connection dictionary
    Then check connection to MySQL db
    Return a cursor
    If the connection flag is set then will return connection and cursor
    Useful if you need to use connection methods such as commit
    """
    # NOTE: 2014-11-17 - [ ] old connection
    # ddsn={'host': 'localhost', 'user': 'stevetm', 'pass': ''},

    try:
        my_conn = MySQLdb.connect(
            host=ddsn['host'],
            db=ddatabase,
            user=ddsn['user'],
            passwd=ddsn['pass'])
        print """OK: Connected to MySQL database "%s" """ % ddatabase
        my_cursor = my_conn.cursor()
    except MySQLdb.Error, e:
        print "Cannot connect to MySQL database"
        print "Error code:", e.args[0]
        print "Error message:", e.args[1]
        sys.exit(0)

    if connection == False:
        return my_cursor
    else:
        return my_cursor, my_conn


def sql_tab_exists(ddatabase, tab_name):
    """
    Check to see if table already exists
    Return True or Fale
    """
    ccursor = sql_connect('information_schema')
    stmt = """  SELECT count(*)
            FROM information_schema.tables
            WHERE table_schema = '%s'
            AND table_name = '%s';
        """ % (ddatabase, tab_name)
    ccursor.execute(stmt)
    if ccursor.fetchone()[0] == 1:
        return True
    elif ccursor.fetchone() is None:
        return False
    else:
        print "ERROR: Duplicate tables found"
        sys.exit(1)

def sql_get_cols(db, table):
    "Return list of fields for MySQL table using information_schema"
    cursor = sql_connect('information_schema')
    stmt = """
    SELECT COLUMN_NAME FROM COLUMNS
    WHERE TABLE_SCHEMA = '%s' AND TABLE_NAME = '%s'
    """ % (db, table)
    cursor.execute(stmt)
    cols = cursor.fetchall()
    return [col[0] for col in cols]

def sql_get_updatetime(target_db, table):
    "Return update time for MySQL table using information_schema"
    cursor = sql_connect('information_schema')
    stmt = """
    SELECT UPDATE_TIME FROM TABLES
    WHERE TABLE_SCHEMA = '%s' AND TABLE_NAME = '%s'
    """ % (target_db, table)
    cursor.execute(stmt)
    updatetime = cursor.fetchone()
    return updatetime[0]

def sql_append_headed_list(sql_cursor, table_name, headed_list):
    """
    Given a table name, a mysql connection object AND a list of lists
    where the first item in the list is a list of column names
    and the remaining items are lists of data
    Then insert this list into the MySQL table
    """
    # first extract the field names and remove the header row
    field_names = [str(field_name) for field_name in headed_list[0]]
    headed_list = headed_list[1:]

    # now loop through the rows
    for row in headed_list:
        # CHANGED: 2012-08-16 - factored out the prepare insert bit
        stmt = sql_prepare_insert(table_name, field_names, row)
        # print stmt
        sql_cursor.execute(stmt)

def sql_prepare_insert(table, fields, values):
    """
    Parses lists of strings correctly
    Returns a suitable statement to execute
    """
    field_names = [str(field_name) for field_name in fields]
    # extract the the field values as strings
    field_values = []
    for v in values:
        if v is None:
            field_values.append('NULL')
        elif isinstance(v, str) and len(v) == 0:
            # insert zero length strings as zero length strings
            field_values.append('')
        else:
            field_values.append(MySQLdb.escape_string(str(v)))

    # prepare SQL statement
    statement = ("INSERT INTO %s (%s) VALUES ('%s') " %
            (table,
            ", ".join(field_names),
            "', '".join(field_values)))

    # Replace 'NULL' with NULL so inserts properly
    # else string 'NULL' is inserted
    statement = re.sub(r"'NULL'", r"NULL", statement)
    # print statement
    return statement



def cr_mysql_tab(
        ddatabase,
        tab_name,
        field_list,
        raw_flg = 0,
        import_flg = 0,
        replace_flg = 0):
    """
    Create correctly specified table from a raw table

    - both converts incoming field name to a standardised one
    - and creates a field definition as per the dicitonary
    - replace_flg - means that any existing table will be overwritten

    - will automatically add the following metafields
        - modifiedat
        - source
        - createdat (i.e. timestamp of the source)

    Given a list of fields (whether from MySQL or from Excel import)
    Use field dictionary to create a correctly specified MySQL table
    Assumes the data dictionary is a YAML specified list of field names
    And 'talias' is a dictionary of aliases for that field
    If talias is empty of unspecified then assumes that field has no aliases

    Also creates a raw table if requested
    Automatically appends '_import' to table name if import flag set
    """
    if import_flg:
        tab_name_sql = tab_name + '_import'
    else:
        tab_name_sql = tab_name

    if raw_flg:
        suffix_list = ['', '_raw']
    else:
        suffix_list = ['']

    # Get cursor in database
    ccursor = sql_connect(ddatabase)

    # check this table does not already exist
    if replace_flg == 0:
        if (sql_tab_exists(ddatabase, tab_name_sql) or
            (raw_flg and sql_tab_exists(ddatabase, tab_name_sql + '_raw'))):
            print "ERROR: %s table[_raw] already exists" % (tab_name)
            sys.exit(1)
    else:
        for suffix in suffix_list:
            stmt = """ DROP TABLE IF EXISTS %s """ % (tab_name_sql + suffix)
            ccursor.execute(stmt)

    # Get reverse field dictionary
    reverse_dict = reverse_field_dict()

    f= reverse_dict['no_alias'].items()
    if tab_name in reverse_dict:
        f.extend(reverse_dict[tab_name].items())
    falias_dict = dict(f)
    # print falias_dict

    for suffix in suffix_list:
        stmt = """
        CREATE TABLE %s (
        modifiedat timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
        sourceFile char(128) DEFAULT NULL,
        sourceFileTimeStamp timestamp NULL DEFAULT NULL); """ % (tab_name_sql + suffix)
        ccursor.execute(stmt)

    # Fields are in field_list ... and will be looked up using talias_dict

    fdict = get_yaml_dict('field', local_dict=True)
    fdict_lookup = {f['fname']:f for f in fdict}

    field_list_notfound = []
    for field_orig in field_list:
        if field_orig in falias_dict:
            # Look-up original name
            fname = falias_dict[field_orig]
        elif field_orig in fdict_lookup:
            fname = field_orig
        else:
            field_list_notfound.append(field_orig)
            continue

        fspec = fdict_lookup[fname]
        if fspec.has_key('sqltype'):
            if fspec.has_key('sqllen'):
                sqltype = "%s(%d)" % (fspec['sqltype'], fspec['sqllen'])
            # CHANGED: 2014-09-16 - default length for unspecified char fields
            elif fspec['sqltype'] == 'char':
                sqltype = "CHAR(16)"
            else:
                sqltype = fspec['sqltype']
        else:
            sqltype = 'CHAR(32)'

        # Raw table
        if raw_flg:
            stmt = ("""ALTER TABLE %s ADD COLUMN %s %s; """
            % (tab_name_sql + '_raw', fname, 'CHAR(255)'))
            # print stmt
            ccursor.execute(stmt)


        stmt = ("""ALTER TABLE %s ADD COLUMN %s %s;"""
        % (tab_name_sql, fname, sqltype))
        # print stmt
        ccursor.execute(stmt)

    if len(field_list_notfound) > 0:
        print ("WARNING: The following %d field(s) not matched\n... %r"
                % (len(field_list_notfound), field_list_notfound))
    else:
        print ("OK: All %d fields found in dictionary" % len(field_list))

def quick_mysql_tab(cursor,  fdict, table, fields):
    """
    Quick version of cr_mysql_tab where no field name conversion is needed
    - database is defined by cursor passed
    """
    success = False

    # import pdb; pdb.set_trace()
    stmt = "DROP TABLE IF EXISTS %s" % table
    cursor.execute(stmt)

    stmt = """
        CREATE TABLE %s (
        modifiedat timestamp NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP);
        """ % table
    cursor.execute(stmt)

    # fdict look-up -> flu
    flu = {f['fname'].lower():f for f in fdict}
    fields = [i.lower() for i in fields]

    for field in fields:
        # print field, type(field)
        try:
            fspec = flu[field]
        except KeyError:
            print "ERROR: field %s not found in field dictionary - check lowercase?" % field
            sys.exit(1)

        # CHANGED: 2013-02-07 - now uses the updated sql type derived from the valias type
        if 'sqltype_new' in fspec:
            sqltype = fspec['sqltype_new']
        else:
            sqltype = fspec['sqltype']

        try:
            if 'sqllen' in fspec and sqltype.lower() in ['char','varchar']:
                sqltype = "%s(%s)" % (fspec['sqltype'], fspec['sqllen'])
            elif sqltype == 'char':
                sqltype = "CHAR(16)"
        except KeyError:
            print "ERROR: Unable to specify sql type/len for %s" % field

        # CHANGED: 2012-09-27 - forces timestamp to default to zero else null becomes current date
        # note subtle distinction you are defining timestamp null and not timestamp default null
        if sqltype == 'timestamp':
            stmt = "ALTER TABLE %s ADD COLUMN %s TIMESTAMP NULL" % (
                table, field)
        else:
            stmt = "ALTER TABLE %s ADD COLUMN %s %s" % (
                table, field, sqltype)


        # print stmt
        # DEBUGGING: 2012-10-01 - step through
        # import pdb; pdb.set_trace()
        cursor.execute(stmt)

    success = True
    return success

def xl_get_col_headers(xlsheet):
    """
    Given an excel sheet object, return a list of column headings
    Should work OK for any square table of data on the sheet
    """
    # TODO: 2012-07-31 - headers must be in row zero:
    # might want to relax this later

    # Searches for the 1st non-blank row
    # i = 0
    # while len(xlsheet.row(i)) == 0:
    #   i += 1

    cells = xlsheet.row(0)
    # Convert to a lower case list of strings
    cells = [cell.value.lower() for cell in cells]
    # Check that headings are unique
    if len(set(cells)) < len(cells):
        print "ERROR: Column headers are not unique"
        sys.exit(1)
    # Check there are no orphan cells (without a col heading)
    if xlsheet.ncols > len(cells):
        print "ERROR: Cells found without column headings"
        sys.exit(1)

    return cells




def xl_col2list(xlsheet, col_name):
    """
    Take an excel sheet object and the column header name
    Find the column containing that data
    Return as a python list of cell objects
    """
    # extract row 1 of the sheet
    xlheaders = [header.lower() for header in xlsheet.row_values(0)]
    # find the index of col_name
    try:
        col_index = xlheaders.index(col_name)
        # use column_values method to return the list
        # iterate through list and convert dates / times
        cells = xlsheet.col(col_index)
    except:
        print ("Error: Failed to extract col %s from sheet %s" %
            (col_name, xlsheet.name))
        sys.exit(1)

    return cells

def xl_2mysql(cell, sqltype, sqllen, valias_dict):
    """
    Take an excel cell object and the field spec (type, len)
    Return a MySQL escaped string if value meets spec
    Else return an empty string
    Also return a tuple containing
        - validaton_ok
        - validation_msg
        - MySQL escaped raw string value
    """
    toreturn = {} # empty dictionary

    cell_type = cell.ctype
    cell_value = cell.value
    # print cell_type, cell_value

    # CHANGED: 2012-12-13 - now convert if valias provided and value matches
    # and the return directly
    if valias_dict:
        if isinstance(cell_value, str) or isinstance(cell_value, unicode):
            cell_value = cell_value.lower()
        if cell_value in valias_dict:
            cell_value = valias_dict[cell_value]
            toreturn['cell_value'] = cell_value
            toreturn['raw_value'] = MySQLdb.escape_string(str(cell.value))
            toreturn['validation_ok'] = True
            toreturn['validation_msg'] = None
            return toreturn


    na_regex = re.compile(r"\bND|NR|NA|N/A|MISSING|UNKNOWN|ERROR|UNANSWERED|Z+(\.Z+)?\b.*")

    num_types = ['tinyint', 'smallint', 'float', 'int', 'mediumint']
    char_types = ['char', 'text']
    date_types = ['date', 'time', 'timestamp']

    # handle properly empty cells
    if cell_value is None:
        result = {}
        result['cell_value'] = 'NULL'
        result['validation_ok'] = False
        result['validation_msg'] = 'Empty cell'

    # handle empty strings
    elif len(str(cell_value)) == 0:
        result = {}
        result['cell_value'] = 'NULL'
        result['validation_ok'] = False
        result['validation_msg'] = 'Empty cell'

    # handle UNTIMED / NA etc
    elif na_regex.match(str(cell_value)):
        result = {}
        result['cell_value'] = 'NULL'
        result['validation_ok'] = True
        result['validation_msg'] = 'Reported missing'
        # import pdb; pdb.set_trace()

    elif sqltype in num_types:
        result = xl_2mysql_num(cell, sqltype)

    elif sqltype in char_types:
        result = xl_2mysql_char(cell, sqltype, sqllen)

    elif sqltype in date_types:
        result = xl_2mysql_datetime(cell, sqltype)

    else:
        print "Error: sqltype %s is not recognised" % sqltype
        sys.exit(1)

    toreturn['cell_value'] = result['cell_value']
    toreturn['raw_value'] = MySQLdb.escape_string(str(cell.value))
    toreturn['validation_ok'] = result['validation_ok']
    toreturn['validation_msg'] = result['validation_msg']

    return toreturn

def sql_2mysql(value, sqltype, sqllen, format=None):
    """
    Takes a python value and tries to convert it as specified
    TODO: 2012-08-16 - does not handle incorrect lengths
    """

    if value is None:
        return True, None
    try:
        if format == 'iso' and sqltype == 'date':
            value = re.match(r"\d\d\d\d-\d?\d-\d?\d",str(value)).group(0)
            format = '%Y-%m-%d'
        if format == 'iso' and sqltype == 'time':
            value = re.match(r"\d?\d:\d\d",str(value)).group(0)
            format = '%H:%M'
        if format == 'iso' and sqltype == 'datetime':
            value = re.match(r"\d\d\d\d-\d?\d-\d?\d \d?\d:\d\d",str(value)).group(0)
            format = '%Y-%m-%d %H:%M'
    except AttributeError:
        # should catch regular expression error where no match and hence group(0) fails
        return False, None

    char_types = ['char', 'text']
    decimals = ['float', 'decimal', 'double']

    if sqltype in char_types:
        if isinstance(value, str):
            return True, value
        else:
            return False, str(value)

    elif sqltype[-3:].lower() == 'int':
        if isinstance(value, int):
            return True, value
        else:
            result = extract_number(value)
            if isinstance(result, int):
                return True, result
            elif isinstance(result, float):
                return False, int(round(result))
            else:
                return False, None

    elif sqltype.lower() in decimals:
        if isinstance(value, float):
            return True, value
        else:
            result = extract_number(value)
            if isinstance(result, float):
                return True, result
            elif isinstance(result, int):
                return False, float(result)
            else:
                return False, None

    elif sqltype.lower() == 'date':
        if isinstance(value, datetime.date):
            return True, value
        elif format != None:
            # try using the provided format first
            result = datetime.datetime.strptime(value, format).date()
            if result is not None:
                return True, result
        else:
            result = extract_datetime(value, 'date')
            if result is not None:
                    return True, result
        print "ERROR: Failed to parse date for %s" % value
        return False, None

    elif sqltype.lower() == 'time':
        if isinstance(value, datetime.time):
            return True, value
        elif format != None:
            # try using the provided format first
            result = datetime.datetime.strptime(value, format).time()
            if result is not None:
                return True, result
        else:
            result = extract_datetime(value, 'time')
            if result is not None:
                return True, result
        print "ERROR: Failed to parse time for %s" % value
        return False, None

    elif sqltype.lower() == 'timestamp':
        if isinstance(value, datetime.datetime):
            return True, value
        elif format != None:
            # try using the provided format first
            result = datetime.datetime.strptime(value, format).timestamp()
            if result is not None:
                return True, result
        else:
            result = extract_datetime(value, 'timestamp')
            if result is not None:
                return True, result
        print "ERROR: Failed to parse timestamp for %s" % value
        return False, None
        return False, None


def xl_2mysql_char(cell, sqltype, sqllen):
    toreturn = {}
    cell_value = str(cell.value).lower()


    validation_ok = True
    validation_msg = ''

    if len(cell_value) > sqllen:
        cell_value = cell_value[0:sqllen - 1]
        validation_ok = False
        validation_msg = 'String too long for field spec - truncated at %d' % sqllen

    toreturn['cell_value'] = cell_value
    toreturn['validation_ok'] = validation_ok
    toreturn['validation_msg'] = validation_msg

    return toreturn

def xl_2mysql_num(cell, sqltype):
    toreturn =  toreturn = {}

    validation_ok = True
    validation_msg = ''

    # Handle empty cells
    # if len(cell.value) == 0:
    #   toreturn['cell_value'] = ''
    #   toreturn['validation_ok'] = validation_ok
    #   toreturn['validation_msg'] = 'Empty cell'

    #   return toreturn

    # if not empty then check cell type
    if cell.ctype in [2,4]: # excel number, boolean 1,0
        cell_value = cell.value

    if cell.ctype == 1: # excel text
        cell_value = extract_number(cell.value)
        if cell_value is None:
            toreturn['cell_value'] = None
            toreturn['validation_ok'] = False
            toreturn['validation_msg'] = 'Text in numerical field'

            return toreturn

    if sqltype != 'float' and cell_value < 0:
        cell_value = None
        validation_ok = False
        validation_msg = 'Negative integers not permitted'
    elif sqltype == 'tinyint' and cell_value > 127:
        cell_value = None
        validation_ok = False
        validation_msg = 'Value > 127 - cannot store as tinyint'
    elif sqltype == 'smallint' and cell_value > 32767:
        cell_value = None
        validation_ok = False
        validation_msg = 'Value > 32767 - cannot store as smallint'



    toreturn['cell_value'] = cell_value
    toreturn['validation_ok'] = validation_ok
    toreturn['validation_msg'] = validation_msg

    return toreturn

def extract_number(num_str):
    "Attempt to extract number from string"
    num_str = str(num_str)
    # print num_str
    if len(num_str) > 0:
        # Remove white space
        num_str = ''.join([char for char in num_str if char != ' '])
        # CHANGED: 2014-09-15 - drop if contains '.'
        if num_str == '.':
            return None
        # CHANGED: 2014-11-18 - [ ] handle numbers recorded as 123.X etc
        dotx_regex = re.compile(r"^(.*)\.[XYZ]+$")
        dotx_result = dotx_regex.match(num_str)
        if dotx_result:
            num_str = dotx_result.group(1)
        # CHANGED: 2012-09-06 - to handle + signs before numbers
        num_regex = re.compile(r"^(?:\+)?(\d*(\.\d*)?)$")
        result = num_regex.match(num_str)
        if result:
            return float(result.group(1)) if '.' in num_str else int(result.group(1))
    else:
        return None


def xl_2mysql_datetime(cell, sqltype):
    toreturn = {}

    validation_ok = True
    validation_msg = ''
    cell_value = ''


    # Handle empty cells
    # if len(cell.value) == 0:
    #   toreturn['cell_value'] = ''
    #   toreturn['validation_ok'] = validation_ok
    #   toreturn['validation_msg'] = 'Empty cell'

    #   return toreturn

    if cell.ctype == 1: # excel text
        cell_value = extract_datetime(cell.value, sqltype)
        if cell_value is None:
            toreturn['cell_value'] = None
            toreturn['validation_ok'] = False
            toreturn['validation_msg'] = 'Cannot parse text date-time'
        else:
            # convert the datetime object to ISO string
            # python uses the T separator between date and time as default
            # replace this with a space
            cell_value = cell_value.isoformat().replace('T', ' ')
            toreturn['cell_value'] = cell_value
            toreturn['validation_ok'] = validation_ok
            toreturn['validation_msg'] = validation_msg

    if cell.ctype == 3:
        try:
            year, month, day, hour, minute, second = (
                xlrd.xldate_as_tuple(cell.value, xlrd.XL_DATEMODE))
            cell_value = datetime.datetime(year, month, day,
                hour, minute, second).isoformat(' ')
        except:
            toreturn['cell_value'] = None
            toreturn['validation_ok'] = False
            toreturn['validation_msg'] = 'Cannot extract Excel date to MySQL isoformat'

    return toreturn

def extract_datetime(dt_str, sqltype):
    """
    Parse a string into a date/time iso-formatted string
    Returns 'None' if parse fails
    """
    try:
        if len(dt_str) == 0:
            return None

        if sqltype == 'time' and re.match(r"UNTIMED", dt_str):
            # NOTE: 2012-08-08 - handled untimed vals in TableVisit
            # Convert all of these to 00:01:01 (1 min and 1 sec after midnight)
            # This should be the only time value to include seconds hence easy to filter
            return datetime.time(0,1,1)


        elif sqltype == 'time':
            # Check the string looks like a time - assumes 24h clock
            time24_regex = re.compile(
                r"""\b
                ([01]?\d|2(?=[0-3])\d)
                ([:|.])?
                ([0-5]?\d)
                \b""", re.VERBOSE)
            match_obj = time24_regex.match(dt_str)

            if match_obj is not None:
                # Constructs a time format string based on the regex
                time_format = ''.join(str(item) for item in
                    ['%H', match_obj.group(2),  '%M']
                    if item is not None)
                # Returns a structured time tuple with hour,min in pos 3,4
                dt = time.strptime(dt_str, time_format)
                return datetime.time(dt[3],dt[4])
            else:
                raise Error()

        elif sqltype == 'date':
            # Check the string looks like a date -  assumes year 2000+ if YY
            date_regex = re.compile(r"^\d{1,2}(?P<separator>/|-)?\d{1,2}(?P=separator)?(19|20)?\d{2}$")
            match_obj = date_regex.match(dt_str)
            if match_obj is not None:
                if (match_obj.group(2)) is None:
                    year_format = '%y'
                else:
                    year_format = '%Y'
                # Constructs a time format string based on the regex
                date_format = ''.join(str(item) for item in
                    ['%d', (match_obj.group(1)),  '%m', (match_obj.group(1)), year_format]
                    if item is not None)
                # Returns a structured time tuple with hour,min in pos 3,4
                # print dt_str, date_format
                dt = time.strptime(dt_str, date_format)
                return datetime.date(dt[0],dt[1],dt[2])

        elif sqltype == 'timestamp':
            # Check the string looks like HH:MM DD/MM/[20]YY
            # Separators can be :/-
            timestamp_regex = re.compile(
                    r"""^\d{1,2}            # hour
                    ([:|.])                 # time separator
                    \d{2}               # minute
                    (\s+)               # mandatory white space betw time and date
                    \d{1,2}             # day
                    (?P<separator>/|-)  # date separator
                    \d{1,2}             # month
                    (?P=separator)      # date separator
                    (19|20)?            # century (optional)
                    (\d{2})$""",            # year
                    re.VERBOSE)

            match_obj = timestamp_regex.match(dt_str)

            if match_obj is not None:
                if (match_obj.group(4)) is None:
                    year_format = '%y'
                else:
                    year_format = '%Y'

                # Constructs a time format string based on the regex
                date_format = ''.join(str(item) for item in
                    ['%H', (match_obj.group(1)),  '%M', match_obj.group(2),
                    '%d', (match_obj.group(3)),  '%m', (match_obj.group(3)), year_format]
                    if item is not None)

                # Returns a structured time tuple with hour,min in pos 3,4
                dt = time.strptime(dt_str, date_format)
                return datetime.datetime(dt[0],dt[1],dt[2],dt[3],dt[4])

    except:
        print "WARNING: Failed to parse %s as %s" % (dt_str, sqltype)
        return None

