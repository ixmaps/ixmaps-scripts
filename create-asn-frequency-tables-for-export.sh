#!/bin/bash

# this script generates a set of tables that are required for analysis of carrier frequency

# example ASN frequency in route (CrFreqTR)
# select count(distinct traceroute_id) from dcan_nouoft_nodup where asnum = 6461;

# example ASN frequency in hop (CrFreqIP)
# select count(*) from dcan_nouoft_nodup where asnum = 6461;

declare -a carriers=(
    'AboveNet'
    'Acanac'
    'ACN Canada'
    'AT&T'
    'Bell'
    'Bell Aliant'
    'Bragg Communications'
    'Bruce Telecom'
    'Cogeco'
    'Cogent'
    'Comcast'
    'Comwave'
    'Distributel'
    'Eastlink'
    'Execulink'
    'Fido'
    'Fongo'
    'Hurricane Electric'
    'Koodo Mobile'
    'Level 3'
    'Limelight'
    'Mobilicity'
    'MTS allstream'
    'Northwestel'
    'Novus'
    'Peer 1'
    'Primus Canada'
    'Rogers'
    'Sasktel'
    'Savvis'
    'Shaw'
    'Sprint'
    'Storm Internet Service'
    'Tata'
    'Teksavvy'
    'Telebec'
    'TeliaNet/Telia Sonera'
    'Telus'
    'Verizon'
    'Videotron'
    'VIF Internet'
    'Virgin Mobile'
    'Wind Mobile '
    'Xplornet'
)

declare -a whereConditions=(
    'asnum = 6461 or asnum = 17025'
    'asnum = 33139'
    'asnum = 17899'
    'asnum = 7018 or asnum = 5730 or asnum = 4466'
    'asnum = 577 or asnum = 6549 or asnum = 11489'
    'asnum = 855'
    'asnum = 0'
    'asnum = 11727'
    'asnum = 11290'
    'asnum = 174 or asnum = 2149'
    'asnum = 7922 or asnum = 33491 or asnum = 33659'
    'asnum = 15128'
    'asnum = 11814 or asnum = 14595'
    'asnum = 11260'
    'asnum = 0'
    'asnum = 8282'
    'asnum = 0'
    'asnum = 6939'
    'asnum = 0'
    'asnum = 3356 or asnum = 3549 or asnum = 30686'
    'asnum = 22822 or asnum = 45396 or asnum = 38622'
    'asnum = 36676'
    'asnum = 7122'
    'asnum = 22573 or asnum = 6058'
    'asnum = 40029'
    'asnum = 13768'
    'asnum = 9443 or asnum = 6407'
    'asnum = 812 or asnum = 3602'
    'asnum = 803'
    'asnum = 3561 or asnum = 6347 or asnum = 4298'
    'asnum = 6327'
    'asnum = 1239 or asnum = 1803 or asnum = 3644'
    'asnum = 13319'
    'asnum = 6453 or asnum = 6421'
    'asnum = 5645 or asnum = 20375'
    'asnum = 35911'
    'asnum = 1299'
    'asnum = 852 or asnum = 7861 or asnum = 54719'
    'asnum = 701 or asnum = 702 or asnum = 703'
    'asnum = 5769'
    'asnum = 0'
    'asnum = 30261'
    'asnum = 20365 or asnum = 36273'
    'asnum = 22995'
)

echo ""
echo "Generating CrFreq..."
# DCan-noUoT-noDup   /   DCan-Bo-noUoT-noDups    /    DCan-noBo-noUoT-noDup
# TR / IP
echo "ASNs, DCan-noUoT-noDup-TR, DCan-noUoT-noDup-IP, DCan-Bo-noUoT-noDups-TR, DCan-Bo-noUoT-noDups-IP, DCan-noBo-noUoT-noDup-TR, DCan-noBo-noUoT-noDup-IP" >> dcan_crfreq.csv
declare -i i=0
for w in "${whereConditions[@]}"
do
    echo "ASN: "$w
    dcan_nouoft_nodup_tr_count=$(psql -d ixmaps -Atc "select count(distinct traceroute_id) from dcan_nouoft_nodup where $w;")
    dcan_nouoft_nodup_ip_count=$(psql -d ixmaps -Atc "select count(*) from dcan_nouoft_nodup where $w;")
    dcan_bo_nouoft_nodup_tr_count=$(psql -d ixmaps -Atc "select count(distinct traceroute_id) from dcan_bo_nouoft_nodup where $w;")
    dcan_bo_nouoft_nodup_ip_count=$(psql -d ixmaps -Atc "select count(*) from dcan_bo_nouoft_nodup where $w;")
    dcan_nobo_nouoft_nodup_tr_count=$(psql -d ixmaps -Atc "select count(distinct traceroute_id) from dcan_nobo_nouoft_nodup where $w;")
    dcan_nobo_nouoft_nodup_ip_count=$(psql -d ixmaps -Atc "select count(*) from dcan_nobo_nouoft_nodup where $w;")
    echo ${carriers[i]}", "$w", "$dcan_nouoft_nodup_tr_count", "$dcan_nouoft_nodup_ip_count", "$dcan_bo_nouoft_nodup_tr_count", "$dcan_bo_nouoft_nodup_ip_count", "$dcan_nobo_nouoft_nodup_tr_count", "$dcan_nobo_nouoft_nodup_ip_count >> dcan_crfreq_$TODAY.csv
    ((i++))
done
