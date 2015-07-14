#!/usr/bin/python
# this script converts .out to .sql (for use by corr-db.sh)

import sys
import string

def us2bl(s):
    s = "''".join(s.split("'"))   # render "St. John's" properly
    s = string.replace(s, "_", " ")
    return unicode(s, 'latin1', 'ignore').encode('utf-8')


set_str = "set mm_country='%s', mm_region='%s', mm_city='%s', mm_postal='%s', mm_area_code=%d, mm_dma_code=%d "
in_fname = sys.argv[1]
out_fname = sys.argv[2]

fdi = open(in_fname)
fdo = open(out_fname, "w")
while True:
   line = fdi.readline()[:-1]
   if len(line) < 1:
       break
   (ip_addr, country, region, city, pcode, junk, lat, lng, area_c, dma_c, dist) = eval("["+line+"]")
   data = [country, us2bl(region), us2bl(city), us2bl(pcode), area_c, dma_c]
   qstr = ("update ip_addr_info "+set_str+"where ip_addr='%s';") % tuple(data+[ip_addr])
   print >>fdo, qstr
