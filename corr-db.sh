#!/bin/bash
# this script updates city information in the DB to match the longitude and latitudes (which have been changed by corr-latlong.sh)

# removed, since this is already running through cronjab
#scripts/corr-latlong.sh -u

now=`date +%Y%m%d`
tmpdir=$HOME/tmp
datadir=$HOME/ix-data/mm-data

psql ixmaps -A -F ' ' -t \
    -c "select lat,long,ip_addr from ip_addr_info where gl_override is not null" \
    >${tmpdir}/lat_long_ip-${now}.out
/home/ixmaps/scripts/mmdba_apr8 -a -N -C -P ${tmpdir}/lat_long_ip-${now}.out ${datadir}/GeoLiteCity.dat \
    >${tmpdir}/fixup-${now}.out
# wait 30 minutes
python /home/ixmaps/scripts/db_fix.py ${tmpdir}/fixup-${now}.out ${tmpdir}/fixup-${now}.sql
psql ixmaps <${tmpdir}/fixup-${now}.sql

#clean up some outliers that Maxmind has listed too inexactly or exactly
psql ixmaps -c "update ip_addr_info set mm_city='Toronto' where lat='43.72' and long='-79.34';"

rm ${tmpdir}/*${now}*
