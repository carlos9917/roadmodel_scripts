#!/bin/bash
ju=/media/cap/7fed51bd-a88e-4971-9656-d617655b6312/data/sources/julia/julia-1.5.2/bin/julia
SCRDIR=$PWD
BUFR=12201 #BUFR code for the station (12200 is road temperature, 12201 is air temperature)

source ./utils.sh
#First test
#julia --project=$PWD/.. ./create_dbase.jl --help


#Small test observations:
#dtype=glatdump
#DATADIR=/media/cap/7fed51bd-a88e-4971-9656-d617655b6312/data/glatmodel_obs/small_sample
#SmallTest

#All files observations:
dtype=glatdump
DATADIR=/media/cap/7fed51bd-a88e-4971-9656-d617655b6312/data/glatmodel_obs
GetAllGlatObs 2020

#Small test forecast
#DATADIR=/media/cap/7fed51bd-a88e-4971-9656-d617655b6312/data/glatmodel_fcst/small_sample
#dtype=fild7
#SmallTest

#All files forecast:
#DATADIR=/media/cap/7fed51bd-a88e-4971-9656-d617655b6312/data/glatmodel_fcst
#dtype=fild7
#GetAllGlatFcst 2020
