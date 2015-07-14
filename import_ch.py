#!/usr/bin/python
# coding: utf-8

# populate the chotel and related tables by brute-force
# the input is a spreadsheet table in CSV format

#FIXME geolocations are imported as separate lat/log coordinates
# they should use the Postgres point datatype and the table
# indexed using the "gist" access method and the appropriate
# operator class (box_ops?)

import csv
import sys
import string
import getopt

# data structures:
#
# ma       is a dictionary of dictionaries relating database-related metainformation
#          to column names in the spreadsheet
#      
# da       is an array of dictionaries in the same order as columns in the spreadsheet
#          each dictionary is taken from ma
#
# daf      is the filtered version of da only including actual columns going into
#          the chotel database table.  Each dictionary has an additional key 'col'
#          to relate back to the spreadsheet column number
#
# col_netw is the column number of the ISP networks in the spreadsheet

def define_tables(conn, ma):
    # create the three tables with comments

    # first the chnetwork table
    all_nets = Networks(conn)
    all_nets.define()

    # secondly the chotel table
    conn.query("drop table if exists chotel cascade")
    cols=['id integer primary key']
    comments=[]
    for k in ma:
        if ma[k]['dbname']:
            cols.append(ma[k]['dbname']+" "+ma[k]['dbtype'])
            comments.append("comment on column chotel.%s is '%s'" % (ma[k]['dbname'], k))
    conn.query("create table chotel ("+(",".join(cols))+")")
    conn.query("comment on table chotel is 'Carrier Hotel info from Nancy''s spreadsheet'")
    for com in comments:
        conn.query(com)
    conn.query("create index idx_address on chotel (address)")
    conn.query("grant select on chotel to public")

    # third, the ch_networks table
    conn.query("drop table if exists ch_networks cascade")
    conn.query("create table ch_networks ("+
                   "ch_id integer references chotel (id) on delete cascade,"+
                   "net_id integer references chnetwork (id) on delete cascade)")
    conn.query("comment on table ch_networks is 'Links tables chotel and chnetwork'")
    conn.query("comment on column ch_networks.ch_id is 'ID from carrier hotel (chotel) table'")
    conn.query("comment on column ch_networks.net_id is 'ID from chnetwork table'")
    conn.query("grant select on ch_networks to public")

def clean_tables(conn):
    # start with a fresh slate each time
    conn.query("delete from chotel")
    conn.query("delete from chnetwork")
    conn.query("delete from ch_networks")

def make_insert_cmd(table_name, daf):
    cmd = "insert into "+table_name+" ("
    cmd += ','.join([d['dbname'] for d in daf])
    cmd += ') values ('
    cmd += ','.join([d['dbfmt'] for d in daf])
    cmd += ')'
    return cmd
          
def make_update_cmd(table_name, daf, pkey):
    fmt_pkey = [d['dbfmt'] for d in daf if d['dbname'] == pkey][0]
    index_pkey = [i for i in range(len(daf)) if daf[i]['dbname'] == pkey][0]
    cmd = "update "+table_name+" set ("
    cmd += ','.join([d['dbname'] for d in daf if d['dbname'] != pkey])
    cmd += ') = ('
    cmd += ','.join([d['dbfmt'] for d in daf if d['dbname'] != pkey])
    cmd += ') where %s=%s' % (pkey, fmt_pkey)
    return index_pkey, cmd
          
def assign_col_numbers(ma, header):
    da=[]
    for i in range(len(header)):
        key = header[i]
        da.append(ma[key])
        ma[key]['col'] = i
    return da

def from_dms(l):
    d_s , rest = l.split('°')
    d = int(d_s)
    m_s , rest = rest.split("'")
    m = float(m_s)
    s_s , rest = rest.split('"')
    s = float(s_s)
    hemi = rest[0]
    f = d + m/60.0 + s/3600.0
    if hemi in 'SW':
        f = -f
    #print d, m, s, hemi
    return f

def make_value_tuple(daf, row):
    t=[]
    for d in daf:
        val = row[d['col']]
        if d['dbfmt'] == '%d':
            val = int(val)
        elif d['dbfmt'] == '%.9g':
            try:
                val = float(val)
            except ValueError:
                #print val
                try:
                    val = from_dms(val)
                except ValueError:
                    val = None
        elif d['dbtype'] == 'boolean':
            if val == '':
                val = 'f'
        t.append(val)
    return tuple(t)

class Networks(object):
    def __init__(self, conn):
        self.nets = {}
        self.conn = conn
        self.id = 0

    def contains(self, net):
        return self.nets.has_key(net)

    def add(self, net):
        if not self.contains(net):
            self.id += 1
            self.nets[net] = self.id
            net_rr = string.replace(net, "; Inc.", ", Inc.")
            conn.query("insert into chnetwork (id, name) values (%d, '%s')" % (self.id, net_rr))
        return self.nets[net]

    def ident(self, net):
        return self.nets[net]

    def define(self):
        self.conn.query("drop table if exists chnetwork cascade")
        self.conn.query("create table chnetwork (id integer primary key, name varchar(120))")
        self.conn.query("comment on table chnetwork is 'Networks from the Carrier Hotel spreadsheet'")
        self.conn.query("comment on column chnetwork.id is 'Network ID'")
        self.conn.query("comment on column chnetwork.name is 'Network name'")
        self.conn.query("grant select on chnetwork to public")
    
class DBConnect(object):
    # this is a stand-in for the real DBConnect class
    def __init__(self):
        pass

    # output queries to stdout instead of a database
    def query(self, s):
        print s+';'

ma = {
      'ID':                              {'dbfmt': "%d",    'dbname': 'id',             'dbtype':  'integer'},
      'NSA':                             {'dbfmt': "'%s'",  'dbname': 'nsa',            'dbtype':  'varchar(6)'},
      'Info Source for NSA':             {'dbfmt': "'%s'",  'dbname': 'nsa_src',        'dbtype':  'varchar(512)'},
      'CH Owner of Building':            {'dbfmt': "'%s'",  'dbname': 'ch_build_owner', 'dbtype':  'varchar(100)'},
      'CH Operator':                     {'dbfmt': "'%s'",  'dbname': 'ch_operator',    'dbtype':  'varchar(100)'},
      'Info Source for owner-operator':  {'dbfmt': "'%s'",  'dbname': 'ch_src',         'dbtype':  'varchar(512)'},
      'Lat':                             {'dbfmt': "%.9g",  'dbname': 'lat',            'dbtype':  'double precision'},
      'Long':                            {'dbfmt': "%.9g",  'dbname': 'long',           'dbtype':  'double precision'},
      'City':                            {'dbfmt': None,    'dbname': None,             'dbtype':  None},
      'State':                           {'dbfmt': None,    'dbname': None,             'dbtype':  None},
      'Additional Info':                 {'dbfmt': None,    'dbname': None,             'dbtype':  None},
      'Image':                           {'dbfmt': "'%s'",  'dbname': 'image',          'dbtype':  'varchar(512)'},
      'Address':                         {'dbfmt': "'%s'",  'dbname': 'address',        'dbtype':  'varchar(120)'},
      'ISP Networks':                    {'dbfmt': None,    'dbname': None,             'dbtype':  None},
      'Info Source - ISPs':              {'dbfmt': "'%s'",  'dbname': 'isp_src',        'dbtype':  'varchar(512)'},
      'Core Routers':                    {'dbfmt': None,    'dbname': None,             'dbtype':  None},
      'Info Source':                     {'dbfmt': "'%s'",  'dbname': 'rtr_src',        'dbtype':  'varchar(512)'},
      'MPLS networks':                   {'dbfmt': None,    'dbname': None,             'dbtype':  None},
     }

#ss_cols = ['NSA', 'NSA Info Source',      'CH Owner of Building', 'CH Operator', 'CH Info Source', 'Lat',
#    'Long', 'Image', 'Address', 'ISP Networks', 'ISP Info Source', 'Core Routers', 'Router Info Source', 'MPLS networks']

def help():
    print """Use: import_ch.py [-g][-u] file

file is a spreadsheet saved in CSV format

Options:
-g    set Google mode - if address is empty, compose it from City and State
-u    update latitude and longitude to greater precision
"""

is_google = False
is_update = False
progname = sys.argv[0]
try:
    (opts, fnames) = getopt.getopt(sys.argv[1:], "hgu")
except getopt.GetoptError, exc:
    print >>sys.stderr, "%s: %s" % (progname, str(exc))
    sys.exit(1)

for flag, value in opts:
    if flag == '-g':
        is_google = True
    elif flag == '-u':
        is_update = True
    elif flag == '-h':
        help()
        sys.exit(0)

reader = csv.reader(open(fnames[0]))

header = reader.next()

conn = DBConnect()
if not is_update:
    define_tables(conn, ma)
    clean_tables(conn)

#print header
da = assign_col_numbers(ma, header)
daf = [d for d in da if d['dbname']]
col_netw = ma['ISP Networks']['col']
col_address = ma['Address']['col']
col_city = ma['City']['col']
col_state = ma['State']['col']
all_nets = Networks(conn)
#print daf

if is_update:
    daf = [d for d in daf if d['dbname'] in ['lat', 'long', 'id']]
    id_index, chotels_fmt = make_update_cmd('chotel', daf, 'id')
else:
    chotels_fmt = make_insert_cmd('chotel', daf)

#print chotels_fmt

for row in reader:
    #print len(row)
    #print row
    if is_google:
        if row[col_address] == '':
            row[col_address] = "Google Facility in "+row[col_city]+" "+row[col_state]
    try:
        chotels_val = make_value_tuple(daf, row)
    except ValueError:
        continue
    #print chotels_fmt
    #print chotels_val
    id = chotels_val[0]
    if is_update:
        chotels_val = chotels_val[:id_index]+chotels_val[id_index+1:]+((chotels_val[id_index],))
    try:
        conn.query(chotels_fmt % chotels_val)
    except TypeError:
        continue
    if is_update:
        continue
    nets = row[col_netw]
    nets = string.replace(nets, ", Inc,", ", Inc.,")
    nets = string.replace(nets, ", Inc.", "; Inc.")
    nets = string.replace(nets, "\n", " ")
    nets = nets.split(',')
    nets = [string.strip(net) for net in nets]
    #print nets
    old_nets = [net for net in nets if all_nets.contains(net)]
    new_nets = [net for net in nets if not all_nets.contains(net)]
    #print "old: ", old_nets
    #print "new: ", new_nets
    for net in new_nets:
        all_nets.add(net)
    for net in nets:
        net_id = all_nets.ident(net)
        conn.query("insert into ch_networks (ch_id, net_id) values (%d, %d)" % (id, net_id))


