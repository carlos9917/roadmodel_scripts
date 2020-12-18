#!/bin/bash

#########################################################
#Run GRASS in batch mode. This is called by run_grass.sh
#########################################################
#### >>>> NOTE:  Do not load python conda at this stage!!!!

#Following example here:
#https://grasswiki.osgeo.org/wiki/GRASS_and_Shell#GRASS_Batch_jobs

#This is the name of the station list being processed:
st=$1

grassDataDir=/home/cap/GIS/grass722/grassdata/mytemploc_dk
grassDataSettings=/home/cap/GIS/grass722/grassdata/RoadStations/
grassBinary=/home/cap/GIS/grass722/bin/grass72
scrDir=/home/cap/GIS/road_project_scripts
export grasst="$grassBinary --text"

# create new temporary location for the job, exit after creation of this location
$grasst -c $grassDataDir -e
cp $grassDataSettings/PERMANENT/PROJ_* $grassDataDir/PERMANENT

#Create script to run grass from template script. It will replace REPLACE in
#the template
awk -v p1=$st '{gsub("REPLACE",p1);print}' $scrDir/runCalcTemplate.sh > $scrDir/runCalcShadows.sh

chmod 755 $scrDir/runCalcShadows.sh
export GRASS_BATCH_JOB="$scrDir/runCalcShadows.sh"
$grasst $HOME/GIS/grass722/grassdata/mytemploc_dk/PERMANENT
unset GRASS_BATCH_JOB

#cleanup
rm -rf /home/cap/GIS/grass722/grassdata/mytemploc_dk

