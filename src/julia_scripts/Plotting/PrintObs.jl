
import Pkg
Pkg.add("Plots")
import Base
import DataFrames
import SQLite
import Plots
import Dates
using Printf

data_path="/media/cap/7fed51bd-a88e-4971-9656-d617655b6312/data/"

function read_sqlite(file; parameter::String="*", table::String="glatdump", 
        starttime::Int=0, endtime::Int=9999999999, id::Any=-1, printQuery::Bool=false,
                use_custom_query_string::Bool=false, custom_query_string::String="")
    """Function to get data from glatdump sqlite file
    To get all data, parse parameter as *
    If use_custom_query_string is true, everything is ignored,
    except custom query string
    """
    db = SQLite.DB(file)
     if use_custom_query_string 
        query_string = custom_query_string
     else
        query_string = "SELECT " * parameter * " FROM " * table * " WHERE TIME between " *
                       string(starttime) * " AND " * string(endtime) 
        if id != -1

            if id isa Tuple
                query_string *= " AND ID between " * string(id[1]) * " AND " * string(id[2])
            else
                query_string *= " AND ID="*string(id)
            end

        end
     end    
     if printQuery
        println(query_string)
    end
        
    df = SQLite.DBInterface.execute(db, query_string) |> DataFrames.DataFrame
      
    return df
end    

qs = "SELECT ID, TIME, DATETIME,MEAS FROM glatdump" #contains only one station

#NOTE: this file contains ONLY observations with bufr id 12200 (road temperature)

obs_db=joinpath(data_path,"glatmodel_obs/sql_dbs/dump_12200_20190909090000_20190930230000.db")

fcst_db=joinpath(data_path,"glatmodel_fcst/sql_dbs/dump_20190909090000_20190930230000.db")

df_obs = read_sqlite(obs_db, 
                printQuery=true,
                use_custom_query_string=true,
                custom_query_string=qs);

qs_fcst = "SELECT ID, VALID_DATE, DATETIME,ROAD_TEMPERATURE FROM fild7"

df_fcst = read_sqlite(fcst_db, 
                printQuery=true,table="fild7",
                use_custom_query_string=true,
                custom_query_string=qs_fcst)

df_fcst.ID = div.(df_fcst.ID,1000) #take integer division of all elements

function get_time_and_temp(df,col::String="MEAS")
    # Divide DataFrame into many SubDataFrames organised by DATETIME
    #ds = DataFrames.groupby(df, :DATETIME)
    ds = DataFrames.groupby(df, :DATETIME)
    #print("Groupping ",ds)

    timeslots = length(ds)
    time = zeros(Dates.DateTime, timeslots)
    temperature = zeros(Float64, timeslots)

    for k in 1:timeslots
      time[k] = Dates.DateTime(ds[k]["DATETIME"][1],"yyyy-mm-dd HH:MM:SS.SSS")
      temperature[k] = ds[k][col][1]
    end
    return time, temperature
end

#get_time_and_temp(df_GLAT)

time_obs,temp_obs = get_time_and_temp(df_obs)
time_fcst,temp_fcst = get_time_and_temp(df_fcst,"ROAD_TEMPERATURE")
#println(time_obs)
plt1=Plots.plot!(time_obs, temp_obs, label="Obs",show=true)
Plots.plot!(time_fcst, temp_fcst, label="Fcst",show=true)
Plots.plot!(size=(1000,800))
Plots.savefig(plt1,"file.png")

