#!/bin/bash
#this script is an attempt to isolate all tr_id + hops where asn changes (handoff points in a route), and note the country of origin

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
# 33554   NeutralData
# 11670   Torix
# 174     Cogent
# 3561    Savvis
# 6453    TATA Communications
# 3356    Level 3
# 6939    Hurricane Electric
# 22822   Limelight



echo "This script will output country_handoffs.csv"

asnArray=(577 812 6327 852 13768 5769 5645 32613 13319 11260 10533 30295 15290 30176 855 23136 33554 11670 174 3561 6453 3356 6939 22822)
bellArray=(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0)
rogersArray=(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0)
shawArray=(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0)
telusArray=(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0)
peer1Array=(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0)
videotronArray=(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0)
teksavvyArray=(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0)
iwebArray=(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0)
stormArray=(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0)
eastlinkArray=(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0)
ottixArray=(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0)
twoicArray=(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0)
allstreamArray=(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0)
priorityArray=(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0)
aliantArray=(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0)
onxArray=(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0)
neutralArray=(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0)
torixArray=(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0)
cogentArray=(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0)
savvisArray=(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0)
tataArray=(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0)
level3Array=(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0)
hurricaneArray=(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0)
limelightArray=(0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0 0)


for ((trId=1; trId<38609; trId++))
    do
    echo Searching traceroute $trId"..."
    psql ixmaps -c "select traceroute_id,hop,asnum into table temp$trId from full_routes_large where traceroute_id=$trId order by hop;"
    lastHop=($(psql ixmaps -Atc "select hop from temp$trId order by hop desc limit 1;"))
    echo Last hop is $lastHop
    for ((hopNum=1; hopNum<$lastHop; hopNum++))
        do
        currentAsn=($(psql ixmaps -Atc "select asnum from temp$trId where hop=$hopNum"))
        nextAsn=($(psql ixmaps -Atc "select asnum from temp$trId where hop=$((hopNum+1))"))
        if (($currentAsn != $nextAsn))
            then
        	#array length is 24
        	for ((i=0; i<24; i++))
        	    do
        		echo i is $i
        		if ((${asnArray[i]} == $currentAsn))
        		  then
        			for ((j=0; j<24; j++))
                        do
        				echo j is $j
        				if ((${asnArray[j]} == $nextAsn))
        				    then
                            currentCountry="$(psql ixmaps -Atc "select mm_country from full_routes_large where traceroute_id=$trId and 
hop=$hopNum;")"

                            if (($currentAsn == 577))
                                then
                                if [ "${bellArray[j]}" == "0" ] && ([ "$currentCountry" == "CA" ] || [ "$currentCountry" == "US" ])
                                    then
                                    bellArray[j]=$currentCountry
                                elif [ "${bellArray[j]}" == "CA" ] && [ "$currentCountry" == "US" ]
                                    then
                                    bellArray[j]="NA"
                                elif [ "${bellArray[j]}" == "US" ] && [ "$currentCountry" == "CA" ]
                                    then
                                    bellArray[j]="NA"
                                fi
                            fi
                            if (($currentAsn == 812))
                                then
                                if [ "${rogersArray[j]}" == "0" ] && ([ "$currentCountry" == "CA" ] || [ "$currentCountry" == "US" ])
                                    then
                                    rogersArray[j]=$currentCountry
                                elif [ "${rogersArray[j]}" == "CA" ] && [ "$currentCountry" == "US" ]
                                    then
                                    rogersArray[j]="NA"
                                elif [ "${rogersArray[j]}" == "US" ] && [ "$currentCountry" == "CA" ]
                                    then
                                    rogersArray[j]="NA"
                                fi
                            fi
                            if (($currentAsn == 6327))
                                then
                                if [ "${shawArray[j]}" == "0" ] && ([ "$currentCountry" == "CA" ] || [ "$currentCountry" == "US" ])
                                    then
                                    shawArray[j]=$currentCountry
                                elif [ "${shawArray[j]}" == "CA" ] && [ "$currentCountry" == "US" ]
                                    then
                                    shawArray[j]="NA"
                                elif [ "${shawArray[j]}" == "US" ] && [ "$currentCountry" == "CA" ]
                                    then
                                    shawArray[j]="NA"
                                fi
                            fi
                            if (($currentAsn == 852))
                                then
                                if [ "${telusArray[j]}" == "0" ] && ([ "$currentCountry" == "CA" ] || [ "$currentCountry" == "US" ])
                                    then
                                    telusArray[j]=$currentCountry
                                elif [ "${telusArray[j]}" == "CA" ] && [ "$currentCountry" == "US" ]
                                    then
                                    telusArray[j]="NA"
                                elif [ "${telusArray[j]}" == "US" ] && [ "$currentCountry" == "CA" ]
                                    then
                                    telusArray[j]="NA"
                                fi
                            fi
                            if (($currentAsn == 13768))
                                then
                                if [ "${peer1Array[j]}" == "0" ] && ([ "$currentCountry" == "CA" ] || [ "$currentCountry" == "US" ])
                                    then
                                    peer1Array[j]=$currentCountry
                                elif [ "${peer1Array[j]}" == "CA" ] && [ "$currentCountry" == "US" ]
                                    then
                                    peer1Array[j]="NA"
                                elif [ "${peer1Array[j]}" == "US" ] && [ "$currentCountry" == "CA" ]
                                    then
                                    peer1Array[j]="NA"
                                fi
                            fi
                            if (($currentAsn == 5769))
                                then
                                if [ "${videotronArray[j]}" == "0" ] && ([ "$currentCountry" == "CA" ] || [ "$currentCountry" == "US" ])
                                    then
                                    videotronArray[j]=$currentCountry
                                elif [ "${videotronArray[j]}" == "CA" ] && [ "$currentCountry" == "US" ]
                                    then
                                    videotronArray[j]="NA"
                                elif [ "${videotronArray[j]}" == "US" ] && [ "$currentCountry" == "CA" ]
                                    then
                                    videotronArray[j]="NA"
                                fi
                            fi
                            if (($currentAsn == 5645))
                                then
                                if [ "${teksavvyArray[j]}" == "0" ] && ([ "$currentCountry" == "CA" ] || [ "$currentCountry" == "US" ])
                                    then
                                    teksavvyArray[j]=$currentCountry
                                elif [ "${teksavvyArray[j]}" == "CA" ] && [ "$currentCountry" == "US" ]
                                    then
                                    teksavvyArray[j]="NA"
                                elif [ "${teksavvyArray[j]}" == "US" ] && [ "$currentCountry" == "CA" ]
                                    then
                                    teksavvyArray[j]="NA"
                                fi
                            fi
                            if (($currentAsn == 32613))
                                then
                                if [ "${iwebArray[j]}" == "0" ] && ([ "$currentCountry" == "CA" ] || [ "$currentCountry" == "US" ])
                                    then
                                    iwebArray[j]=$currentCountry
                                elif [ "${iwebArray[j]}" == "CA" ] && [ "$currentCountry" == "US" ]
                                    then
                                    iwebArray[j]="NA"
                                elif [ "${iwebArray[j]}" == "US" ] && [ "$currentCountry" == "CA" ]
                                    then
                                    iwebArray[j]="NA"
                                fi
                            fi
                            if (($currentAsn == 13319))
                                then
                                if [ "${stormArray[j]}" == "0" ] && ([ "$currentCountry" == "CA" ] || [ "$currentCountry" == "US" ])
                                    then
                                    stormArray[j]=$currentCountry
                                elif [ "${stormArray[j]}" == "CA" ] && [ "$currentCountry" == "US" ]
                                    then
                                    stormArray[j]="NA"
                                elif [ "${stormArray[j]}" == "US" ] && [ "$currentCountry" == "CA" ]
                                    then
                                    stormArray[j]="NA"
                                fi
                            fi
                            if (($currentAsn == 11260))
                                then
                                if [ "${eastlinkArray[j]}" == "0" ] && ([ "$currentCountry" == "CA" ] || [ "$currentCountry" == "US" ])
                                    then
                                    eastlinkArray[j]=$currentCountry
                                elif [ "${eastlinkArray[j]}" == "CA" ] && [ "$currentCountry" == "US" ]
                                    then
                                    eastlinkArray[j]="NA"
                                elif [ "${eastlinkArray[j]}" == "US" ] && [ "$currentCountry" == "CA" ]
                                    then
                                    eastlinkArray[j]="NA"
                                fi
                            fi
                            if (($currentAsn == 10533))
                                then
                                if [ "${ottixArray[j]}" == "0" ] && ([ "$currentCountry" == "CA" ] || [ "$currentCountry" == "US" ])
                                    then
                                    ottixArray[j]=$currentCountry
                                elif [ "${ottixArray[j]}" == "CA" ] && [ "$currentCountry" == "US" ]
                                    then
                                    ottixArray[j]="NA"
                                elif [ "${ottixArray[j]}" == "US" ] && [ "$currentCountry" == "CA" ]
                                    then
                                    ottixArray[j]="NA"
                                fi
                            fi
                            if (($currentAsn == 30295))
                                then
                                if [ "${twoicArray[j]}" == "0" ] && ([ "$currentCountry" == "CA" ] || [ "$currentCountry" == "US" ])
                                    then
                                    twoicArray[j]=$currentCountry
                                elif [ "${twoicArray[j]}" == "CA" ] && [ "$currentCountry" == "US" ]
                                    then
                                    twoicArray[j]="NA"
                                elif [ "${twoicArray[j]}" == "US" ] && [ "$currentCountry" == "CA" ]
                                    then
                                    twoicArray[j]="NA"
                                fi
                            fi
                            if (($currentAsn == 15290))
                                then
                                if [ "${allstreamArray[j]}" == "0" ] && ([ "$currentCountry" == "CA" ] || [ "$currentCountry" == "US" ])
                                    then
                                    allstreamArray[j]=$currentCountry
                                elif [ "${allstreamArray[j]}" == "CA" ] && [ "$currentCountry" == "US" ]
                                    then
                                    allstreamArray[j]="NA"
                                elif [ "${allstreamArray[j]}" == "US" ] && [ "$currentCountry" == "CA" ]
                                    then
                                    allstreamArray[j]="NA"
                                fi
                            fi
                            if (($currentAsn == 30176))
                                then
                                if [ "${priorityArray[j]}" == "0" ] && ([ "$currentCountry" == "CA" ] || [ "$currentCountry" == "US" ])
                                    then
                                    priorityArray[j]=$currentCountry
                                elif [ "${priorityArray[j]}" == "CA" ] && [ "$currentCountry" == "US" ]
                                    then
                                    priorityArray[j]="NA"
                                elif [ "${priorityArray[j]}" == "US" ] && [ "$currentCountry" == "CA" ]
                                    then
                                    priorityArray[j]="NA"
                                fi
                            fi
                            if (($currentAsn == 855))
                                then
                                if [ "${aliantArray[j]}" == "0" ] && ([ "$currentCountry" == "CA" ] || [ "$currentCountry" == "US" ])
                                    then
                                    aliantArray[j]=$currentCountry
                                elif [ "${aliantArray[j]}" == "CA" ] && [ "$currentCountry" == "US" ]
                                    then
                                    aliantArray[j]="NA"
                                elif [ "${aliantArray[j]}" == "US" ] && [ "$currentCountry" == "CA" ]
                                    then
                                    aliantArray[j]="NA"
                                fi
                            fi
                            if (($currentAsn == 23136))
                                then
                                if [ "${onxArray[j]}" == "0" ] && ([ "$currentCountry" == "CA" ] || [ "$currentCountry" == "US" ])
                                    then
                                    onxArray[j]=$currentCountry
                                elif [ "${onxArray[j]}" == "CA" ] && [ "$currentCountry" == "US" ]
                                    then
                                    onxArray[j]="NA"
                                elif [ "${onxArray[j]}" == "US" ] && [ "$currentCountry" == "CA" ]
                                    then
                                    onxArray[j]="NA"
                                fi
                            fi
                            if (($currentAsn == 33554))
                                then
                                if [ "${neutralArray[j]}" == "0" ] && ([ "$currentCountry" == "CA" ] || [ "$currentCountry" == "US" ])
                                    then
                                    neutralArray[j]=$currentCountry
                                elif [ "${neutralArray[j]}" == "CA" ] && [ "$currentCountry" == "US" ]
                                    then
                                    neutralArray[j]="NA"
                                elif [ "${neutralArray[j]}" == "US" ] && [ "$currentCountry" == "CA" ]
                                    then
                                    neutralArray[j]="NA"
                                fi
                            fi
                            if (($currentAsn == 11670))
                                then
                                if [ "${torixArray[j]}" == "0" ] && ([ "$currentCountry" == "CA" ] || [ "$currentCountry" == "US" ])
                                    then
                                    torixArray[j]=$currentCountry
                                elif [ "${torixArray[j]}" == "CA" ] && [ "$currentCountry" == "US" ]
                                    then
                                    torixArray[j]="NA"
                                elif [ "${torixArray[j]}" == "US" ] && [ "$currentCountry" == "CA" ]
                                    then
                                    torixArray[j]="NA"
                                fi
                            fi
                            if (($currentAsn == 174))
                                then
                                if [ "${cogentArray[j]}" == "0" ] && ([ "$currentCountry" == "CA" ] || [ "$currentCountry" == "US" ])
                                    then
                                    cogentArray[j]=$currentCountry
                                elif [ "${cogentArray[j]}" == "CA" ] && [ "$currentCountry" == "US" ]
                                    then
                                    cogentArray[j]="NA"
                                elif [ "${cogentArray[j]}" == "US" ] && [ "$currentCountry" == "CA" ]
                                    then
                                    cogentArray[j]="NA"
                                fi
                            fi
                            if (($currentAsn == 3561))
                                then
                                if [ "${savvisArray[j]}" == "0" ] && ([ "$currentCountry" == "CA" ] || [ "$currentCountry" == "US" ])
                                    then
                                    savvisArray[j]=$currentCountry
                                elif [ "${savvisArray[j]}" == "CA" ] && [ "$currentCountry" == "US" ]
                                    then
                                    savvisArray[j]="NA"
                                elif [ "${savvisArray[j]}" == "US" ] && [ "$currentCountry" == "CA" ]
                                    then
                                    savvisArray[j]="NA"
                                fi
                            fi
                            if (($currentAsn == 6453))
                                then
                                if [ "${tataArray[j]}" == "0" ] && ([ "$currentCountry" == "CA" ] || [ "$currentCountry" == "US" ])
                                    then
                                    tataArray[j]=$currentCountry
                                elif [ "${tataArray[j]}" == "CA" ] && [ "$currentCountry" == "US" ]
                                    then
                                    tataArray[j]="NA"
                                elif [ "${tataArray[j]}" == "US" ] && [ "$currentCountry" == "CA" ]
                                    then
                                    tataArray[j]="NA"
                                fi
                            fi
                            if (($currentAsn == 3356))
                                then
                                if [ "${level3Array[j]}" == "0" ] && ([ "$currentCountry" == "CA" ] || [ "$currentCountry" == "US" ])
                                    then
                                    level3Array[j]=$currentCountry
                                elif [ "${level3Array[j]}" == "CA" ] && [ "$currentCountry" == "US" ]
                                    then
                                    level3Array[j]="NA"
                                elif [ "${level3Array[j]}" == "US" ] && [ "$currentCountry" == "CA" ]
                                    then
                                    level3Array[j]="NA"
                                fi
                            fi
                            if (($currentAsn == 6939))
                                then
                                if [ "${hurricaneArray[j]}" == "0" ] && ([ "$currentCountry" == "CA" ] || [ "$currentCountry" == "US" ])
                                    then
                                    hurricaneArray[j]=$currentCountry
                                elif [ "${hurricaneArray[j]}" == "CA" ] && [ "$currentCountry" == "US" ]
                                    then
                                    hurricaneArray[j]="NA"
                                elif [ "${hurricaneArray[j]}" == "US" ] && [ "$currentCountry" == "CA" ]
                                    then
                                    hurricaneArray[j]="NA"
                                fi
                            fi
                            if (($currentAsn == 22822))
                                then
                                if [ "${limelightArray[j]}" == "0" ] && ([ "$currentCountry" == "CA" ] || [ "$currentCountry" == "US" ])
                                    then
                                    limelightArray[j]=$currentCountry
                                elif [ "${limelightArray[j]}" == "CA" ] && [ "$currentCountry" == "US" ]
                                    then
                                    limelightArray[j]="NA"
                                elif [ "${limelightArray[j]}" == "US" ] && [ "$currentCountry" == "CA" ]
                                    then
                                    limelightArray[j]="NA"
                                fi
                            fi
		        		fi
		        	done
        		fi
        	done
        fi
    done
    psql ixmaps -c "drop table temp$trId"
done

echo "Bell:" ${bellArray[@]} >> country_handoffs.csv
echo "Rogers:" ${rogersArray[@]} >> country_handoffs.csv
echo "Shaw:" ${shawArray[@]} >> country_handoffs.csv
echo "Telus:" ${telusArray[@]} >> country_handoffs.csv
echo "Peer1:" ${peer1Array[@]} >> country_handoffs.csv
echo "Videotron:" ${videotronArray[@]} >> country_handoffs.csv
echo "TekSavvy:" ${teksavvyArray[@]} >> country_handoffs.csv
echo "IWEB:" ${iwebArray[@]} >> country_handoffs.csv
echo "Storm Internet Services:" ${stormArray[@]} >> country_handoffs.csv
echo "Eastlink:" ${eastlinkArray[@]} >> country_handoffs.csv
echo "Ottix:" ${ottixArray[@]} >> country_handoffs.csv
echo "2ICSYSTEMSINC:" ${twoicArray[@]} >> country_handoffs.csv
echo "Allstream:" ${allstreamArray[@]} >> country_handoffs.csv
echo "Priority Colo:" ${priorityArray[@]} >> country_handoffs.csv
echo "Alint:" ${aliantArray[@]} >> country_handoffs.csv
echo "ONX:" ${onxArray[@]} >> country_handoffs.csv
echo "NeutralData:" ${neutralArray[@]} >> country_handoffs.csv
echo "Torix:" ${torixArray[@]} >> country_handoffs.csv
echo "Cogent:" ${cogentArray[@]} >> country_handoffs.csv
echo "Savvis:" ${savvisArray[@]} >> country_handoffs.csv
echo "TATA Communications:" ${tataArray[@]} >> country_handoffs.csv
echo "Level 3:" ${level3Array[@]} >> country_handoffs.csv
echo "Hurricane Electric:" ${hurricaneArray[@]} >> country_handoffs.csv
echo "Limelight:" ${limelightArray[@]} >> country_handoffs.csv


