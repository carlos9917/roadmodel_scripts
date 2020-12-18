#!/bin/bash
scrdir=$HOME/gis/roadmodel_scripts #location of the git repo
wrkdir=$PWD
now=`date '+%Y%m%d_%H%M%S'`
today=`date '+%Y%m%d'`
cwd=$PWD
#for i in 00; do # note: can also do 00..NN and it will add the leading 0
if [ -z "$1" -a -z "$2" ]; then
  csv=./station_data_test.csv
  st=00
  echo Using standard values for csv=$csv anv st=$st
else
  csv=$1
  st=$2
  echo User provided alues for csv=$csv anv st=$st
fi
outdir=$wrkdir/stations_$st
#Copy the scripts here
cp $scrdir/shadowcalc_scripts/search_zipfiles_nounzip.py .
cp $scrdir/shadowcalc_scripts/grab_data_dsm.py .
cp $scrdir/shadowcalc_scripts/calculateShadows.py .
cp $scrdir/shadowcalc_scripts/shadowFunctions.py .
cp $scrdir/shadowcalc_scripts/shadows_conf.ini .

echo Getting zip files
python3 grab_data_dsm.py -ul $wrkdir/$csv -cid $st -out $wrkdir -td $scrdir
cd $outdir
for zip in `ls *.zip`; do
 echo "unzipping $zip"
 unzip $zip
 pid=$!
 wait $pid
 echo "deleting $zip"
 rm -f $zip
 pid=$!
 wait $pid
done
 cd $wrkdir
 echo "Files unzip DONE. Calling Grass. Doing station list $st"
 time /bin/bash ./runGrass.sh $st $csv >& salida_${st}
 pid=$!
 wait $pid
 echo "Station list $st finished."
 echo "Removing tif files for this station list"
 #to clean the data:
 cd $wrkdir/stations_${st}
 echo "Deleting tif files"
 rm -f *.tif *.zip *.md5
 pid=$!
 wait $pid
echo "Finished"

#rename current data directory
cd $cwd
rep=""
csv_ll="${csv/_utm$rep/}"
echo Will use $csv_ll  to update database
python3 ./create_dbase.py $csv_ll ./lh_500_0.4_11.25_00
#make a copy of the database (for debugging)
cp ./shadows_data.db dbase_backup/shadows_data_$today.db
mv ./lh_500_0.4_11.25_00 ./lh_500_0.4_11.25_00_${today}
#echo "NOTE: need to copy over my ssh key before doing this"
echo "Copying data to freyja"
scp -r ./lh_500_0.4_11.25_00_${today} cap@freyja-2.dmi.dk:/data/cap/DSM_DK/Shadow_data/rancher_processed
