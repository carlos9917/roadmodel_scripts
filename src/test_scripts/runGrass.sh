#!/bin/bash

#########################################################
#Run GRASS in batch mode. This is called by run_grass.sh
#########################################################
#### >>>> NOTE:  Do not load python conda at this stage!!!!

#Following example here:
#https://grasswiki.osgeo.org/wiki/GRASS_and_Shell#GRASS_Batch_jobs

#This is the id and filename of the station list being processed:
st=$1
csvfile=$2
wrkdir=$PWD
grassDataDir=$HOME/gis/grassdata/mytemploc_dk
grassDataSettings=$HOME/gis/grassdata/RoadStations/
grassBinary=/usr/local/bin/grass79
scrDir=$HOME/gis/roadmodel_scripts/shadowcalc_scripts
export grasst="$grassBinary --text"

# create new temporary location for the job, exit after creation of this location
$grasst -c $grassDataDir -e
#$grasst -c $grassDataDir
#mkdir $grassDataDir/PERMANENT
#cp $grassDataSettings/PERMANENT/PROJ_* $grassDataDir/PERMANENT
#cp $grassDataSettings/PERMANENT/WIND $grassDataDir/PERMANENT
cp $grassDataSettings/PERMANENT/* $grassDataDir/PERMANENT/

#Create script to run grass from template script. It will replace REPLACE in
#the template
awk -v p1=$st -v p2=$csvfile '{gsub("REPLACE",p1);gsub("CSVFILE",p2);print}'  $scrDir/runCalcTemplate.sh > $wrkdir/runCalcShadows.sh

chmod 755 $wrkdir/runCalcShadows.sh
export GRASS_BATCH_JOB="$wrkdir/runCalcShadows.sh"
$grasst $HOME/gis/grassdata/mytemploc_dk/PERMANENT
unset GRASS_BATCH_JOB

#cleanup
rm -rf $HOME/gis/grassdata/mytemploc_dk/
