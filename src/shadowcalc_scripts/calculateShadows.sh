#!/bin/bash

#TO FIX:
#BUGS: Name cut depends on the name of the directory !!!
# ie road_project_scripts_STUFF wont work

#THIS version reads the files and tiles arrays from 
#pre-processed files

#export PATH="/data/cap/miniconda2/bin:$PATH"
#source activate py37
#set -x

stretchlist=${1-stretchlist_utm.csv}
stretchnum=$2 #the number of the stretch list
tilesDir=/home/cap/GIS/road_project_scripts/calc_tiles_hpc

#maxdistance=10000    # scanning distance in meters
maxdistance=500    # scanning distance in meters
resolution=0.4    # processing resolution in meters
horizonstep=11.25        # width of scanning sector in degrees
#tileside=10 # use 1 for including only 9 tiles
tileside=1 # use 1 for including only 9 tiles
mindist=1 #minimum distance around tiles
mintiles=6 # the minimum number of tiles that need to be present (8 around + 1 center)
csv_set=${stretchnum} #CHANGE
Decomp_dir=$tilesDir/stations_${stretchnum}/ # CHANGE !!!!
tilesdir=$Decomp_dir

out_dir=lh_${maxdistance}_${resolution}_${horizonstep}_${csv_set}
#DHM_dir="/media/cap/7E95ED15444BBB52/Backup_Work/DMI/DATA_RoadProject/"

now=`date '+%Y%m%d_%H%M%S'`
echo "time at start $now"

wrk_dir="/tmp/horanlge-$$"

mkdir $wrk_dir || exit 1

#directory for processing points and store results:
[ -d $out_dir ] || mkdir $out_dir

WD=`pwd`

echo "-------------------------------------------------------"
echo "Workind directory where script is running from: $WD"
echo "temporary work directory to define tile sizes: $wrk_dir"
echo "directory for processing points and store results: $out_dir"
echo "-------------------------------------------------------"
# 
# preparation
#
# classifiy the points in DHM-tiles wrt coordinates.
# In the original version this considered 10 km tiles,
# but in the current I have 1 km tiles.
echo "-------------------------------------------------------"
echo "Data preparation step"
echo "-------------------------------------------------------"
i=-1

#Calculate number of lines in the file:
#imax=`wc -l $stretchlist | cut -f 1 -d ' '`
echo "Splitting the list of stations into different tiles"
for stretch in `cat $stretchlist`; do
  echo "stretch to process: $stretch"

  i=`expr $i + 1`
  stretch_east=`echo $stretch | cut -d '|' -f 1`
  stretch_north=`echo $stretch | cut -d '|' -f 2`
  stretch_tile="`echo ${stretch_north} | awk '{print (int($1 / 1000) * 10)/10}'`_`echo ${stretch_east} | awk '{print (int($1 / 1000) * 10)/10}'`"
  echo "$stretch" >> ${wrk_dir}/tile_$stretch_tile || exit 1

done
echo "----------------------------"
echo "pre-processing points done"
echo "----------------------------"


#
# processing
# Dont need to do this anymore, since I get the files I need when I need them
#cd ${DHM_dir} || exit 1
echo "setting map resolution to $resolution"
# set resolution
g.region res=$resolution -p

#NOTE: Decomp_dir is needed by the python3 process below.
#This directory will contain the tif files
#If not using the python script, DO NOT DELETE IT

echo "Now the process of going over each tile starts"
i=-1

#for tilelist_file in `ls -1 ${wrk_dir}/tile_*`; do
for tilelist_file in `ls -1rt ${wrk_dir}/tile_*`; do #THIS CAN CONTAIN SEVERAL STRETCHES
  echo "tilelist_file: $tilelist_file"
  DHM_tile=`basename $tilelist_file`
  #locate DHM_title at center of any of the tilesneeded_* files:
  getfilename=$(basename $tilelist_file)
  check_tile_file=`echo $getfilename | cut -f 2-3 -d _`
  echo "check_tile_file: $check_tile_file"
  #NOTE: do not use $1 below or it will be confused with command line option
  #tileneeded=`awk '{print FILENAME " " $5}' $tilesdir/tilesneeded_* | grep $check_tile_file | cut -f1 -d " " | head -n 1` #prints name of file where I can find tile $this_tile

  #this prints the names of the files where I find check_tile_file CHANGE BELOW!!!
  tilesneeded=`grep "${check_tile_file}" calc_tiles_hpc/stations_${stretchnum}/tilesneeded_* | awk -F ":" '{print $1}'`
  echo "CHECK file for tile: $tilesneeded"
  #tileneeded_all=`awk '{print FILENAME " " $5}' $tilesdir/tilesneeded_* | grep $check_tile_file | cut -f1 -d " " `
  for tile in ${tilesneeded[@]}; do
	  echo "Going through tile: $tile"
  #TODO: What happens if tileneeded not found???
   if [ -z "$tilesneeded" ]; then
	   echo "WARNING: tile needed not found!"
	   break
   else
	   echo "tiles needed found in $tilesneeded"
   fi	   
  #echo "awk '{print FILENAME " " "$"5}' $tilesdir/tilesneeded_* | grep $this_tile | awk '{print "$"1}'"
  #tileslist_file=$tilesdir/$tileneeded
  #tileslist_file=$tileneeded
  echo "check tile $tile"
  echo $PWD
  tiles=($(cat ${tile}))  #($(cat ${tileneeded}))
  #fname=`basename $tileneeded`
  fname=`basename $tile`
  checkfile=$tilesdir/files${fname:5:30}
  #echo "checkfile $checkfile"
  files_check=($(cat ${checkfile}))
  files=()
   for t in ${files_check[@]}; do
   files+=($Decomp_dir/$t)
   done
  #files=($files_check)
  echo "files: ${files[@]}"
  echo "tiles: ${tiles[@]}"

  ########done #tile loop

  number_of_tiles=${#tiles[@]}
  echo "num tiles $number_of_tiles"
  if [ $number_of_tiles -ge $mintiles ];
  then

  i=0
  #NEEDS AS INPUT VARIABLES: files and tiles
  while [ $i -lt $number_of_tiles ]; do
  #while [ $i -le $number_of_tiles ]; do
  #  echo "check ${tiles[$i]}"
    #check_test=`grep -c ${tiles[$i]}`
  #  #echo " check2 $check_test"
    if [ `g.list ras | grep -c ${tiles[$i]}` -eq 0 ]; then
      echo "   importing ${files[$i]} -> ${tiles[$i]}"
      r.in.gdal in=${files[$i]} out=${tiles[$i]} -o memory=150
    fi
    i=`expr $i + 1`
  done


  # establish the working domain
  #NEEDS AS INPUT VARIABLES: tiles
  #The input is a list of patches like: 6199_703,6199_704,6199_705,6200_703,6200_704,6200_705,6201_703,6201_704,6201_705
  echo "Establish the working domain"
  region=`echo ${tiles[*]} | sed "s/ /,/g"`
  echo "region to patch = $region"
  echo "Calling region before patching the raster files "
  echo "g.region rast=$region res=$resolution -ap --verbose"
  g.region rast=$region res=$resolution -ap --verbose
  echo "ran region command"
  echo "r.patch input=$region output=work_domain --overwrite --verbose"
  r.patch input=$region output=work_domain --overwrite --verbose
  echo "ran patch command"
  echo "Finished establishing working domain"


  # do the calculations
  number_of_points=`wc -l $tilelist_file | cut -f 1 -d ' '`
  echo "   number of points: $number_of_points"
  for stretch in `cat ${wrk_dir}/$DHM_tile`; do
  #for stretch in `cat $stretchlist`; do
    echo "stretch $stretch"
    stretch_east=`echo $stretch | cut -d '|' -f 1`
    stretch_north=`echo $stretch | cut -d '|' -f 2`
    county=`echo $stretch | cut -d '|' -f 3`
    roadnr=`echo $stretch | cut -d '|' -f 4`
    roadsection=`echo $stretch | cut -d '|' -f 5`
    #echo "stretch_east $stretch_east"
    #echo "stretch_north $stretch_north"
    #echo "roadnr $roadnr"
    #echo "roadsection $roadsection"
    #echo "     $county $roadnr $roadsection"
    coordinates_horizon=${stretch_east},${stretch_north}
    echo "coords to process $coordinates_horizon"
    #echo "r.horizon -d elevation=work_domain direction=360 step=$horizonstep maxdistance=$maxdistance coordinates=$coordinates_horizon" # > $WD/$out_dir/lh_${county}_${roadnr}_${roadsection}.txt "
    r.horizon -d elevation=work_domain step=$horizonstep maxdistance=$maxdistance coordinates=$coordinates_horizon  > $WD/$out_dir/lh_${county}_${roadnr}_${roadsection}.txt 
    #echo "debug: LOCATION_NAME $LOCATION_NAME"

  done

  # clean up
  unset tiles
  g.remove -f type=raster name=work_domain --verbose # >/dev/null
  #echo "Removing md5 files in $Decomp_dir"
  #rm -f $Decomp_dir/*md5
else
  echo "Not enough tiles in ${tileslist_file}: ${files[@]} ! (tiles number: $number_of_tiles)"
  echo "Advancing to next tile"
fi  

echo "-------------------------"
echo "tile $tilelist_file finished"
echo "-------------------------"

done #tile loop

done #loop for tilelist_file

#############################################################
#Turning this off 20200604
#copy the data to freyja
#echo "transferring the data to freyja"
#echo "command: scp -r $WD/$out_dir freyja-2.dmi.dk:/data/cap/DSM_DK/FinalResults_Sept2019"
#scp -r $WD/$out_dir freyja-2.dmi.dk:/data/cap/DSM_DK/FinalResults_Sept2019
#############################################################

now=`date '+%Y%m%d_%H%M%S'`
echo "time at end $now"
echo "Deleting temp directory $wrk_dir"
rm -r $wrk_dir
