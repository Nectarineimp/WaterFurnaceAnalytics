#!/usr/bin/bash

##
## Converts WaterFurnace cloud data, delivered as XLSX files, into
## Comma Separated Value (CSV) files. This BASH script can be run
## on Linux systems, or WLS on windows. 
##
fulldatapath="/mnt/d/Libraries/Documents/GitHub/WaterFurnaceAnalytics/data/"
for f in "$fulldatapath"*.xlsx;
do  echo $f;
    bn=$(basename "$f" ".xlsx");
    echo $bn;
    echo xlsx2csv -d 'tab' --lineterminator='\r\n' "$f" "$fulldatapath"csv/$bn.csv
    $(xlsx2csv -d 'tab' --lineterminator='\r\n' "$f" "$fulldatapathcsv"csv/$bn.csv)
    if [ 0 -lt $? ];
    then
        exit $?
    fi
    # remove part of the header to leave column names
    $(sed -i '1d' "$fulldatapath"csv/$bn.csv)
done