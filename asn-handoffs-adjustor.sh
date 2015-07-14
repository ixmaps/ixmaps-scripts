#!/bin/bash
# this script is an attempt to isolate all tr_id + hops where asn changes (handoff points in a route)
# note that there is an easier way to do this , now that we have a tr_last_hops table that can be used to denote last hop

# distance calculations need to be added manually to the csv after the script is done

echo "This script will output asn_handoffs_dcan_adjustments.csv"
echo "tr_id_from | hop_from | ip_addr_from | hostname_from | asn_from | mm_lat_from | mm_lng_from | lat_from | lng_from | mm_city_from | mm_region_from | mm_country_from | mm_postal_from | gl_override_from | short_name_from | name_from | dest_from | dest_ip_from | sub_time_from | submitter_from | zip_code_from | hop_lh_from | ip_addr_lh_from | latency_from | tr_id_to | hop_to | ip_addr_to | hostname_to | asn_to | mm_lat_to | mm_lng_to | lat_to | lng_to | mm_city_to | mm_region_to | mm_country_to | mm_postal_to | gl_override_to | short_name_to | name_to | dest_to | dest_ip_to | sub_time_to | submitter_to | zip_code_to | hop_lh_to | ip_addr_lh_to | latency_to" >> asn_handoffs_dcan_adjustments.csv


psql -d ixmaps -tc "select distinct traceroute_id from dcan_nouoft_nodup" ixmaps |
while read -a DCANDATA ; do
    #echo "${DCANDATA[0]} is the set of trs in the table selected above"
    for trId in "${DCANDATA[0]}"
    do
        # use me for resuming
        if ((($trId > 18677)) && (($trId < 18734)))
        then
            echo Searching traceroute $trId"..."
            psql ixmaps -c "select traceroute_id,hop,asnum into table temp$trId from dcan_nouoft_nodup where traceroute_id=$trId order by hop;"
            lastHop=($(psql ixmaps -Atc "select hop from temp$trId order by hop desc limit 1;"))            # this is pretty damned clever, but should probably be replaced with hop_lh
            for ((hopNum=1; hopNum<$lastHop; hopNum++))
            do
                declare -i incrCounter=1                                                                    # this is used to track how many hops forward we want to look (to deal with ASN == -1)
                currentAsn=($(psql ixmaps -Atc "select asnum from temp$trId where hop=$hopNum"))
                nextAsn=($(psql ixmaps -Atc "select asnum from temp$trId where hop=$((hopNum+incrCounter))"))             # pretty sloppy - at the end of the route will return some kind of... something? null maybe?
                if (( nextAsn == -1 ))
                then
                    echo Found a -1, so we are going to increment the counter
                    ((incrCounter++))
                    nextAsn=($(psql ixmaps -Atc "select asnum from temp$trId where hop=$((hopNum+incrCounter))"))
                    # if (hop+2)'s ASN is -1
                    # we could do this recursively, but this is probably already such an edge case that I am not going to worry about any further
                    if (( nextAsn == -1 ))
                    then
                        echo Found a -1, so we are going to increment the counter again
                        ((incrCounter++))
                        nextAsn=($(psql ixmaps -Atc "select asnum from temp$trId where hop=$((hopNum+incrCounter))"))
                    fi
                fi

                if ((($currentAsn != $nextAsn)) && (($currentAsn != -1)))
                then
                    firstHopMinLatency=999
                    secondHopMinLatency=999
                    echo Found an ASN handoff at: $trId $hopNum
                    firstHopString="$(psql ixmaps -Atc "select * from dcan_nouoft_nodup where traceroute_id=$trId and hop=$hopNum order by traceroute_id,hop;")"
                    #firstHopString="$(psql ixmaps -Atc "select traceroute_id,hop,ip_addr,asnum,mm_city from dcan_nouoft_nodup where traceroute_id=$trId and hop=$hopNum order by traceroute_id,hop;")"
                    for ((attempt=1; attempt<5; attempt++))
                    do
                        latency=($(psql ixmaps -Atc "select rtt_ms from tr_item where traceroute_id=$trId and hop=$hopNum and attempt=$attempt;"))
                        if (($latency<firstHopMinLatency))
                        then
                            firstHopMinLatency=$latency
                        fi
                    done

                    echo And its friend at: $trId $((hopNum+incrCounter))
                    secondHopString="$(psql ixmaps -Atc "select * from dcan_nouoft_nodup where traceroute_id=$trId and hop=$((hopNum+incrCounter)) order by traceroute_id,hop;")"
                    #secondHopString="$(psql ixmaps -Atc "select traceroute_id,hop,ip_addr,asnum,mm_city from dcan_nouoft_nodup where traceroute_id=$trId and hop=$((hopNum+incrCounter)) order by traceroute_id,hop;")"
                    for ((attempt=1; attempt<5; attempt++))
                    do
                        latency=($(psql ixmaps -Atc "select rtt_ms from tr_item where traceroute_id=$trId and hop=$hopNum and attempt=$attempt;"))
                        if (($latency<secondHopMinLatency))
                        then
                            secondHopMinLatency=$latency
                        fi
                    done

                    echo $firstHopString"|"$firstHopMinLatency"|"$secondHopString"|"$secondHopMinLatency
                    echo $firstHopString"|"$firstHopMinLatency"|"$secondHopString"|"$secondHopMinLatency >> asn_handoffs_dcan_adjustments.csv
                fi
            done
            psql ixmaps -c "drop table temp$trId"
        fi
    done
done


# for ((trId=1; trId<70492; trId++))              # would be loads better to get an array of all tr_ids in the target table first, instead of 90% of these being misses - yeah, takes ~24 hrs to finish one table
# do
#     echo Searching traceroute $trId"..."
#     psql ixmaps -c "select traceroute_id,hop,asnum into table temp$trId from dcan_nouoft_nodup where traceroute_id=$trId order by hop;"
#     lastHop=($(psql ixmaps -Atc "select hop from temp$trId order by hop desc limit 1;"))            # this is pretty damned clever, but should probably be replaced with hop_lh
#     for ((hopNum=1; hopNum<$lastHop; hopNum++))
#     do
#         declare -i incrCounter=1                                                                    # this is used to track how many hops forward we want to look (to deal with ASN == -1)
#         currentAsn=($(psql ixmaps -Atc "select asnum from temp$trId where hop=$hopNum"))
#         nextAsn=($(psql ixmaps -Atc "select asnum from temp$trId where hop=$((hopNum+incrCounter))"))             # pretty sloppy - at the end of the route will return some kind of... something? null maybe?
#         if (( nextAsn == -1 ))
#         then
#             echo Found a -1, so we are going to increment the counter
#             ((incrCounter++))
#             nextAsn=($(psql ixmaps -Atc "select asnum from temp$trId where hop=$((hopNum+incrCounter))"))
#             # if (hop+2)'s ASN is -1
#             # we could do this recursively, but this is probably already such an edge case that I am not going to worry about any further
#             if (( nextAsn == -1 ))
#             then
#                 echo Found a -1, so we are going to increment the counter again
#                 ((incrCounter++))
#                 nextAsn=($(psql ixmaps -Atc "select asnum from temp$trId where hop=$((hopNum+incrCounter))"))
#             fi
#         fi

#         if ((($currentAsn != $nextAsn)) && (($currentAsn != -1)))
#         then
#     		firstHopMinLatency=999
#     		secondHopMinLatency=999
#             echo Found an ASN handoff at: $trId $hopNum
#             firstHopString="$(psql ixmaps -Atc "select * from dcan_nouoft_nodup where traceroute_id=$trId and hop=$hopNum order by traceroute_id,hop;")"
#             #firstHopString="$(psql ixmaps -Atc "select traceroute_id,hop,ip_addr,asnum,mm_city from dcan_nouoft_nodup where traceroute_id=$trId and hop=$hopNum order by traceroute_id,hop;")"
# 			for ((attempt=1; attempt<5; attempt++))
# 			do
# 				latency=($(psql ixmaps -Atc "select rtt_ms from tr_item where traceroute_id=$trId and hop=$hopNum and attempt=$attempt;"))
# 				if (($latency<firstHopMinLatency))
# 				then
# 					firstHopMinLatency=$latency
# 				fi
# 			done

#             echo And its friend at: $trId $((hopNum+incrCounter))
#             secondHopString="$(psql ixmaps -Atc "select * from dcan_nouoft_nodup where traceroute_id=$trId and hop=$((hopNum+incrCounter)) order by traceroute_id,hop;")"
#             #secondHopString="$(psql ixmaps -Atc "select traceroute_id,hop,ip_addr,asnum,mm_city from dcan_nouoft_nodup where traceroute_id=$trId and hop=$((hopNum+incrCounter)) order by traceroute_id,hop;")"
# 			for ((attempt=1; attempt<5; attempt++))
# 			do
# 				latency=($(psql ixmaps -Atc "select rtt_ms from tr_item where traceroute_id=$trId and hop=$hopNum and attempt=$attempt;"))
# 				if (($latency<secondHopMinLatency))
# 				then
# 					secondHopMinLatency=$latency
# 				fi
# 			done

#             echo $firstHopString"|"$firstHopMinLatency"|"$secondHopString"|"$secondHopMinLatency
#             echo $firstHopString"|"$firstHopMinLatency"|"$secondHopString"|"$secondHopMinLatency >> asn_handoffs_dcan_nouoft_nodup.csv
#         fi
#     done
#     psql ixmaps -c "drop table temp$trId"

# done
