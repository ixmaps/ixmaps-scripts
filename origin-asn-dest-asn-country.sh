#!/bin/bash
# this script is an attempt to look at origin/destination ASN pairs, and see if they are more likely to boomerang or not

# 577     Bell
# 812     Rogers
# 6327    Shaw
# 852     Telus
# 13768   Peer 1
# 5769    Videotron
# 5645    TekSavvy
# 32613   IWEB
# 13319   Storm Internet Services
# 11260   Eastlink
# 10533   Ottix
# 30295   2ICSYSTEMSINC
# 15290   Allstream
# 30176   Priority Colo
# 855     Aliant
# 23136   ONX
# 11670   Torix
# 174     Cogent
# 1403    Electronic Box
# 8075    Microsoft

#"Bell" "Rogers" "Shaw" "Telus" "Peer 1" "Videotron" "TekSavvy" "IWEB" "Storm Internet Services" "Eastlink" "Ottix" "2ICSYSTEMSINC" "Allstream" "Priority Colo" "Aliant" "ONX" "Torix" "Cogent" "Electronic Box" "Microsoft"

#577 812 6327 852 13768 5769 5645 32613 13319 11260 10533 30295 15290 30176 855 23136 11670 174 1403 8075


echo "Running..."
echo ""

ispArray=("Bell" "Rogers" "Shaw" "Telus" "Peer 1" "Videotron" "TekSavvy" "IWEB" "Storm Internet Services" "Eastlink" "Ottix" "2ICSYSTEMSINC" "Allstream" "Priority Colo" "Aliant" "ONX" "Torix" "Cogent" "Electronic Box" "Microsoft")
asnArray=(577 812 6327 852 13768 5769 5645 32613 13319 11260 10533 30295 15290 30176 855 23136 11670 174 1403 8075)

echo "" > asn_to_asn_country_counts.csv

for ((i=0; i<20; i++))
  echo "Starting " ${ispArray[i]}
  echo ""
  do
  for ((j=0; j<20; j++))
    do
    psql ixmaps -c "select traceroute_id into origin_boomerang from boomerang_routes where hop = 1 and asnum = ${asnArray[i]};"
    psql ixmaps -c "select traceroute_id into origin_non_boomerang from non_boomerang_routes where hop = 1 and asnum = ${asnArray[i]};"
    psql ixmaps -c "select * into dest_boomerang from boomerang_routes where hop_lh = hop and asnum = ${asnArray[j]};"
    psql ixmaps -c "select * into dest_non_boomerang from non_boomerang_routes where hop_lh = hop and asnum = ${asnArray[j]};"

    boomerangCount=($(psql ixmaps -Atc "select count(o.traceroute_id) from origin_boomerang as o join dest_boomerang as d on o.traceroute_id = d.traceroute_id;"))
    nonBoomerangCount=($(psql ixmaps -Atc "select count(o.traceroute_id) from origin_non_boomerang as o join dest_non_boomerang as d on o.traceroute_id = d.traceroute_id;"))

    echo ${ispArray[i]} "to" ${ispArray[j]} "boomerang count:" $boomerangCount >> asn_to_asn_country_counts.csv
    echo ${ispArray[i]} "to" ${ispArray[j]} "non-boomerang count:" $nonBoomerangCount >> asn_to_asn_country_counts.csv

    psql ixmaps -c "drop table origin_boomerang, origin_non_boomerang, dest_boomerang, dest_non_boomerang;"
  done
  echo ${ispArray[i]} "completed"
  echo ""
  echo ""
done

echo ""
echo "Done"