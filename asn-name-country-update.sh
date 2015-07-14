#!/bin/bash

#This script is designed to update the as_users table to include short, more human-readable names and country of ownership for the ISPs in the 
IXmaps database

echo "Updating as_users table (will overwrite past entries... but don't panic, it's not a bad thing)"

#psql ixmaps -c "update as_users SET short_name='Cogent',country_code='US' where num=174;"

echo "Enter the name of the file containing the carriers and asnums"
read ips

index=0

while read line ; do
        textArray[$index]="$line"
        index=$(($index+1))
done < $ips

echo ${#textArray[@]}

for (( x=0; x<${#textArray[@]}-1; x=x+3 ))
do
    name=${textArray[x]}
    code=${textArray[x+1]}
    asnum=${textArray[x+2]}
    echo $name
    echo $code
    echo $asnum
    psql ixmaps -c "update as_users set short_name=$name,country_code=$code where num=$asnum;"
done

echo "Array is: ${textArray[*]}"
echo "Total entries in the file: ${index}"
