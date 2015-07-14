#!/bin/bash

# this script generates a set of tables that are required for analysis of Canadian routes, boomerang routes, non-boomerang routes, etc

echo "Generating tables for export..."

echo ""
echo "Dropping old versions of the tables..."
psql ixmaps -c "drop table if exists full_routes_large;"
psql ixmaps -c "drop table if exists ca_origin;"
psql ixmaps -c "drop table if exists ca_destination;"

echo ""
echo "Generating full_routes_large"
psql ixmaps -c "select t.traceroute_id,t.hop,i.ip_addr,i.hostname,i.asnum,i.mm_lat,i.mm_long,i.lat,i.long,i.mm_city,i.mm_region,i.mm_country,i.mm_postal,i.gl_override into script_temp1 from ip_addr_info as i join tr_item as t on i.ip_addr=t.ip_addr where attempt=1;"
psql ixmaps -c "select script_temp1.*,as_users.short_name,as_users.name into script_temp2 from script_temp1 join as_users on script_temp1.asnum=as_users.num;"
psql ixmaps -c "select script_temp2.*,traceroute.dest,traceroute.dest_ip,traceroute.sub_time,traceroute.submitter,traceroute.zip_code into full_routes_large from script_temp2 join traceroute on script_temp2.traceroute_id=traceroute.id order by traceroute_id,hop;"

echo ""
echo "Generating ca_origin..."
psql ixmaps -c "select * into ca_origin from full_routes_large where hop=1 and mm_country='CA';"

echo ""
echo "Generating ca_destination..."
psql ixmaps -c "select traceroute_id_lh,hop_lh,ip_addr_lh,mm_country into ca_destination from tr_last_hops join ip_addr_info on ip_addr_lh=ip_addr where mm_country='CA';"

echo ""
echo "Generating dcan..."
# (all routes with CA origin and CA termination)
# we are using Last Hop as Terminal here (ie, the end of the traceroute is defined as the last hop, as opposed to the the destination)
psql ixmaps -c "select traceroute_id,hop_lh,ip_addr_lh into script_temp3 from ca_origin join ca_destination on traceroute_id=traceroute_id_lh order by traceroute_id;"
psql ixmaps -c "select full_routes_large.*,script_temp3.hop_lh,script_temp3.ip_addr_lh into dcan from full_routes_large join script_temp3 on full_routes_large.traceroute_id=script_temp3.traceroute_id order by full_routes_large.traceroute_id, full_routes_large.hop;"

echo ""
echo "Generating dcan_nodup..."
# we are assuming here that a duplicate route is one that has the same first hop, same last hop, same destination and same length (ie total number of hops, last hop number - hop_lh). TODO: I am not sure how the duplicates are being chosen - does not to seem to follow a pattern
psql ixmaps -c "select traceroute_id,ip_addr,ip_addr_lh,dest_ip,hop_lh,dest,submitter,zip_code into script_temp4 from dcan where hop = 1;"
psql ixmaps -c "select distinct on (ip_addr,ip_addr_lh,dest_ip,hop_lh,dest,submitter,zip_code) * into script_temp5 from script_temp4;"                  # script_temp5 is TRs no dup
psql ixmaps -c "select dcan.* into dcan_nodup from dcan join script_temp5 on dcan.traceroute_id = script_temp5.traceroute_id;"

echo ""
echo "Generating dcan_nouoft..."
# list of excluded zip_codes: iSouth, OISE, robarts, UofT, M5S3G6, M5S, M5S 1C6, M5S 1C7, M5S1C7 45W, M5S 1V5, M5S2L6, M5S2M8, M5S3G6, M5S 3G6, M5S  45Wil
# list of excluded submitters: gbby_iSouth, gbby_isouth, gbby_oise, lodeanto.Robarts, lodeanto.robarts, lodeanto.robarts.6, lodeanto.UofT.Tunnel, lodeanto.UofT.tunnel, lodeanto.uoft.tunnel.last, sgh-uoft
psql ixmaps -c "select * into dcan_nouoft from dcan where zip_code not like '%M5S%' and zip_code not like '%OISE%' and zip_code not like '%iSouth%' and zip_code not like '%robarts%' and zip_code not like '%UofT%' and submitter not like '%gbby_iSouth%' and submitter not like '%gbby_isouth%' and submitter not like '%gbby_oise%' and submitter not like '%lodeanto.Robarts%' and submitter not like '%lodeanto.robarts%' and submitter not like '%lodeanto.UofT.Tunnel%' and submitter not like '%lodeanto.uoft.tunnel%' and submitter not like '%sgh-uoft%';"

echo ""
echo "Generating dcan_nouoft_nodup..."
psql ixmaps -c "select dcan_nouoft.* into dcan_nouoft_nodup from dcan_nouoft join script_temp5 on dcan_nouoft.traceroute_id = script_temp5.traceroute_id;"

echo ""
echo "Generating dcan_bo..."
# this works because we already know first and last hop are CA
psql ixmaps -c "select * into dcan_bo from dcan where traceroute_id in (select distinct traceroute_id from dcan where mm_country='US');"

echo ""
echo "Generating dcan_bo_nodup..."
psql ixmaps -c "select * into dcan_bo_nodup from dcan_nodup where traceroute_id in (select distinct traceroute_id from dcan_nodup where mm_country='US');"

echo ""
echo "Generating dcan_bo_nouoft..."
psql ixmaps -c "select * into dcan_bo_nouoft from dcan_nouoft where traceroute_id in (select distinct traceroute_id from dcan_nouoft where mm_country='US');"

echo ""
echo "Generating dcan_bo_nouoft_nodup..."
psql ixmaps -c "select * into dcan_bo_nouoft_nodup from dcan_nouoft_nodup where traceroute_id in (select distinct traceroute_id from dcan_nouoft_nodup where mm_country='US');"

echo ""
echo "Generating dcan_nobo..."
psql ixmaps -c "select * into dcan_nobo from dcan where traceroute_id not in (select distinct traceroute_id from dcan where mm_country='US');"

echo ""
echo "Generating dcan_nobo_nodup..."
psql ixmaps -c "select * into dcan_nobo_nodup from dcan_nodup where traceroute_id not in (select distinct traceroute_id from dcan_nodup where mm_country='US');"

echo ""
echo "Generating dcan_nobo_nouoft..."
psql ixmaps -c "select * into dcan_nobo_nouoft from dcan_nouoft where traceroute_id not in (select distinct traceroute_id from dcan_nouoft where mm_country='US');"

echo ""
echo "Generating dcan_nobo_nouoft_nodup..."
psql ixmaps -c "select * into dcan_nobo_nouoft_nodup from dcan_nouoft_nodup where traceroute_id not in (select distinct traceroute_id from dcan_nouoft_nodup where mm_country='US');"

echo ""
echo "Cleaning up temp tables..."
psql ixmaps -c "drop table script_temp1;"
psql ixmaps -c "drop table script_temp2;"
psql ixmaps -c "drop table script_temp3;"
psql ixmaps -c "drop table script_temp4;"
psql ixmaps -c "drop table script_temp5;"

declare -a tables=('dcan' 'dcan_nodup' 'dcan_nouoft' 'dcan_nouoft_nodup' 'dcan_bo' 'dcan_bo_nodup' 'dcan_bo_nouoft' 'dcan_bo_nouoft_nodup' 'dcan_nobo' 'dcan_nobo_nodup' 'dcan_nobo_nouoft' 'dcan_nobo_nouoft_nodup');

echo ""
if [ -z "$1" ]; then
    echo -e "Do you want to export the created tables? (y/n) \c"
    read input
else
    input=$1
fi
if [ $input = "y" ]; then
    echo "Exporting tables..."
    TODAY=$(date +"%d-%m-%Y")
    for i in "${tables[@]}"
    do
        psql ixmaps -c "\copy "$i" to '"$i"_"$TODAY".csv' csv header"
    done
fi

echo ""
if [ -z "$2" ]; then
    echo -e "Do you want to drop the created tables? (y/n) \c"
    read input
else
    input=$2
fi
if [ $input = "y" ]; then
    for i in "${tables[@]}"
    do
        psql ixmaps -c "drop table "$i";"
    done
fi
