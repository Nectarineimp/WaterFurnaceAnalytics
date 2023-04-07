#!/usr/bin/bash
fulldatapath="/mnt/d/manra/Documents/Data Science/AchieveRenewable/data/"
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