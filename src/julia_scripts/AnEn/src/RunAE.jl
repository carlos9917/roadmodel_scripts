
include("AnEn.jl")
import Dates

qs = "SELECT ID, TIME, DATETIME,MEAS FROM glatdump"
data_path="/media/cap/7fed51bd-a88e-4971-9656-d617655b6312/data/"

#NOTE: this file contains ONLY observations with bufr id 12200 (road temperature)
obs_db=joinpath(data_path,"glatmodel_obs/sql_dbs/dump_12200_20190909090000_20190930230000.db")

fcst_db=joinpath(data_path,"glatmodel_fcst/sql_dbs/dump_20190909090000_20190930230000.db")

df_obs = AnEn.read_sqlite(obs_db,
                printQuery=true,
                use_custom_query_string=true,
                custom_query_string=qs);

qs_fcst = "SELECT ID, VALID_DATE, DATETIME,ROAD_TEMPERATURE FROM fild7"

df_fcst = AnEn.read_sqlite(fcst_db,
                printQuery=true,table="fild7",
                use_custom_query_string=true,
                custom_query_string=qs_fcst)

df_fcst.ID = div.(df_fcst.ID,1000) #take integer division of all elements

time_obs,temp_obs = AnEn.get_time_and_temp(df_obs)
time_fcst,temp_fcst = AnEn.get_time_and_temp(df_fcst,"ROAD_TEMPERATURE")

# Convert the times to unix times, since it is easier to search for a long
# integer number than a date
utime_fcst = [Dates.datetime2unix(time) for time in time_fcst]
utime_obs  = [Dates.datetime2unix(time) for time in time_obs]
#Get max and min value to set first and last element
max_fcst = maximum(utime_fcst)
min_fcst = minimum(utime_fcst)
max_obs = maximum(utime_obs)
min_obs = minimum(utime_obs)
min_fo = max(min_fcst,min_obs)
max_fo = min(max_fcst,max_obs)
println("Min/max dates in observations: $min_obs,$max_obs ")
println("Min/max dates in forecasts: $min_fcst,$max_fcst ")
println("Min/max dates in both: $min_fo,$max_fo ")
#= Search for the indices in the observation times  
   that match the values of the forecast times

=#
# Cle the array. Doing it old schol in a loop here, not sure how to use 
# multiple conditions in list comprehension in Julia
utime_obs_clean = []
utime_fcst_clean = []

for utime in utime_obs
  if utime >= min_fo && utime <= max_fo
     append!(utime_obs_clean,utime)
  end
end

for utime in utime_fcst
  if utime >= min_fo && utime <= max_fo
     append!(utime_fcst_clean,utime)
  end
end

println("Size of obs array after filter: ",size(utime_obs_clean))
println("Size of fcst array after filter: ",size(utime_fcst_clean))
#idx_match = [indexin(time,utime_obs) for time in utime_obs if time in utime_fcst]
idx_match = [indexin(utime,utime_obs_clean) for utime in utime_obs_clean if utime in utime_fcst_clean]

time_obs_match = [time_obs[i] for i in idx_match]

idx_match = [indexin(utime,utime_fcst_clean) for utime in utime_fcst_clean if utime in utime_obs_clean]
time_fcst_match = [time_fcst[i] for i in idx_match]
temp_fcst_match = []
temp_obs_match = []

for i in idx_match
 append!(temp_fcst_match,temp_fcst[i])
 append!(temp_obs_match,temp_obs[i])
end

#This sort of list comprehension produces a complicated structure which
# then I cannot fucking square!
#temp_fcst_match = [temp_fcst[i] for i in idx_match]
#temp_obs_match = [temp_obs[i] for i in idx_match]

println("Size of obs array with matches in fcst: ",size(time_obs_match))
println("Size of fcst array with matches in obs: ",size(time_fcst_match))
#find_similarity = AnEn.calc_dist(temp_fcst_match,temp_obs_match)
