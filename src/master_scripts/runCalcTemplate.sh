#!/bin/bash
######################################################
# Template script to run the calcShadows script
# This script is called by runGrassBatchMode.sh
######################################################

#WRKDIR=$HOME/road_project_scripts
#tilesDir=./calc_tiles_hpc/data_202006

#cd $WRKDIR

now=`date '+%Y%m%d_%H%M%S'`
st=REPLACE #CHANGED by runGrassBatchMode.sh
tilesDir=stations_$st
srcdir=$HOME/gis/road_project_scripts
echo "--------------------------------"
echo "REMEMBER TO LOAD GRASS FIRST!!!"
echo "--------------------------------"

echo "Running calcShadows"
#time ./calculateShadows.sh $tilesDir/station_data_utm_${st}.csv $st >& out_${st}_$now
#New script:
if [ ! -s $HOME/miniconda3/envs/py37/bin/python ]; then
echo "No conda python available. Using python3"
py37=/usr/bin/python3
else
echo "Using local conda python installation"
py37=$HOME/miniconda3/envs/py37/bin/python
fi
#this one follows the old conventoion:
#time $py37 ./calculateShadows.py -sl $tilesDir/station_data_utm_${st}.csv_ONE -si $st >& out_${st}_$now
#time $py37 ./calculateShadows.py -sl ./station_data_test.csv -si $st -td $PWD -sd $srcdir >& out_${st}_$now
time $py37 ./calculateShadows.py -sl CSVFILE -si $st -td $PWD -sd $srcdir >& out_${st}_$now
echo "calcShadows done"
cd -
