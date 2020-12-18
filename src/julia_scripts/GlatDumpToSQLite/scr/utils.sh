#!/bin/bash

#Some useful functions
function SmallTest()
{
#idate=2019-09-09-15-00-00
#edate=2019-09-30-23-00-00
#requires: dtype=glatdump
    cd $DATADIR
    file1=`ls -1 verdata/$dtype/$dtype* | head -1`
    file2=`ls -1 verdata/$dtype/$dtype* | tail -1`
    if [ $dtype == glatdump ]; then
      date1=`echo $file1 | awk -F"/" '{print $3}' | awk '{print substr($1,9,23)}'`
      date2=`echo $file2 | awk -F"/" '{print $3}' | awk '{print substr($1,9,23)}'`
      database=$DATADIR/dump_${BUFR}_${date1}_${date2}.db
    else
      date1=`echo $file1 | awk -F"/" '{print $3}' | awk '{print substr($1,7,23)}'`
      date2=`echo $file2 | awk -F"/" '{print $3}' | awk '{print substr($1,7,23)}'`
      database=$DATADIR/dump_${date1}_${date2}.db
    fi
    idate=${date1:0:4}-${date1:4:2}-${date1:6:2}-${date1:8:2}-${date1:10:2}-${date1:12:2}
    edate=${date2:0:4}-${date2:4:2}-${date2:6:2}-${date2:8:2}-${date2:10:2}-${date2:12:2}
    echo $idate
    echo $edate
    cd $SCRDIR
    $ju --project=$PWD/.. ./create_dbase.jl ${dtype}_to_sqlite --starttime=$idate --endtime=$edate --sqlite-file=$database --indir=$DATADIR/verdata/$dtype/ --bufrcode=$BUFR --file-prefix=$dtype
}

function GetAllGlatObs()
{

  if [ -z $1 ]; then
    echo Please provide year in format YYYY
    exit
  else
    YYYY=$1
  fi
  
  for year in $YYYY; do
  cd $DATADIR/$year
  tars=`ls -1 *tar`
    for tar in $tars; do
      tar xvf $tar
      cd verdata/glatdump/
      echo Unpacking the files...
      gunzip *.gz
      pid=$!
      wait $pid
      echo Unpacking done. Now running Julia
      cd -
      file1=`ls -1 verdata/glatdump/glat* | head -1`
      file2=`ls -1 verdata/glatdump/glat* | tail -1`
      date1=`echo $file1 | awk -F"/" '{print $3}' | awk '{print substr($1,9,23)}'`
      date2=`echo $file2 | awk -F"/" '{print $3}' | awk '{print substr($1,9,23)}'`
      echo $date1
      echo $date2
      idate=${date1:0:4}-${date1:4:2}-${date1:6:2}-${date1:8:2}-${date1:10:2}-${date1:12:2}
      edate=${date2:0:4}-${date2:4:2}-${date2:6:2}-${date2:8:2}-${date2:10:2}-${date2:12:2}
      echo $idate
      echo $edate
      cd $SCRDIR
      $ju --project=$PWD/.. ./create_dbase.jl glatdump_to_sqlite --starttime=$idate --endtime=$edate --sqlite-file=$DATADIR/sql_dbs/dump_${BUFR}_${date1}_${date2}.db --indir=$DATADIR/$year/verdata/glatdump/ --bufrcode=$BUFR 
     pid=$!
     wait $pid
     cd -
      rm -rf ./verdata
    done
  done
}

#argument: year
function GetAllGlatFcst()
{

if [ -z $1 ]; then
  echo Please provide year in format YYYY
  exit
else
  YYYY=$1
fi

for year in $YYYY; do
cd $DATADIR/$year
tars=`ls -1 *tar`
  for tar in $tars; do
    tar xvf $tar
    cd verdata/$dtype
    echo Unpacking the files...
    gunzip *.gz
    pid=$!
    wait $pid
    # Now clean the files
    cleanfild7files
    pid=$!
    wait $pid
    echo Cleaning and unpacking done. Now running Julia
    cd -
    file1=`ls -1 verdata/$dtype/$dtype* | head -1`
    file2=`ls -1 verdata/$dtype/$dtype* | tail -1`
    date1=`echo $file1 | awk -F"/" '{print $3}' | awk '{print substr($1,7,23)}'`
    date2=`echo $file2 | awk -F"/" '{print $3}' | awk '{print substr($1,7,23)}'`
    database=$DATADIR/dump_${date1}_${date2}.db
    idate=${date1:0:4}-${date1:4:2}-${date1:6:2}-${date1:8:2}-${date1:10:2}-${date1:12:2}
    edate=${date2:0:4}-${date2:4:2}-${date2:6:2}-${date2:8:2}-${date2:10:2}-${date2:12:2}
    echo $idate
    echo $edate
    cd $SCRDIR
    database=$DATADIR/dump_${date1}_${date2}.db
    $ju --project=$PWD/.. ./create_dbase.jl ${dtype}_to_sqlite --starttime=$idate --endtime=$edate --sqlite-file=$database --indir=$DATADIR/$year/verdata/$dtype/ --bufrcode=$BUFR --file-prefix=$dtype
    pid=$!
    wait $pid
    cd -
    rm -rf ./verdata
  done
done
}

#function to replace extra spaces in the fild7 files and replace them with commas
function cleanfild7files()
{
  #replace all the extra spaces by one
  for f in `ls -1 fild*`; do
   awk '{$2=$2};1' $f > $f.tmp
   pid=$!
   wait $pid
   mv $f.tmp $f
  done

  #replace space by a comma
  for f in `ls -1 fild*`; do
   sed -i 's/ /,/g'  $f
  done
}
