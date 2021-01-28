module AnEn

greet() = print("Hello World!")


import Base
import SQLite
import DataFrames
import Dates
import CSV
import Statistics


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
 

    function get_time_and_temp(df,col::String="MEAS")
        """
        Divide DataFrame into many SubDataFrames organised by DATETIME
        Change col if it is the forecast
        """ 
        ds = DataFrames.groupby(df, :DATETIME)
        timeslots = length(ds)
        time = zeros(Dates.DateTime, timeslots)
        temperature = zeros(Float64, timeslots)
    
        for k in 1:timeslots
          time[k] = Dates.DateTime(ds[k]["DATETIME"][1],"yyyy-mm-dd HH:MM:SS.SSS")
          temperature[k] = ds[k][col][1]
        end
        return time, temperature
    end

     
    function calc_dist(fcst,obs,matching_times)#,Wv::Float64=1.0)
     """
      Calculate Euclidean distance for one variable

      stdev is the standard deviation of the time series
      of past forecasts of this variable and at the location
      I am studying
   
      Wi is a vector with the weight for the predictor variable
      Currently setting to 1.0
      
      twin is the time window over which to calculate the analogs
      at each given time in the past 24h. Choosing 30 min here
     """
     #for i in size(temp_fcst_match,1):-1:2 
     #println("----- i ",i) 
     #for j in i-1:i+1
     #println("j ",j)
     #end 
     #end


     stdev = Statistics.std(fcst)
     len_past = 24
     Wv = 1.0 
     distances = []
     idx = []
     for i in size(fcst,1)-1:-1:2
        println("Going through $matching_times[i] and $i")
        Forecast = fcst[i]
        diff = 0.
        for j in i-1:i+1 

         #Go through all the forecast times in the past 24 hours
         println("Calculating analogs for time: $matching_times[j] and $j")
         Analog =  fcst[j]
         diff = (Forecast - Analog)^2 + diff
        end
        d = Wv*sqrt(diff)/stdev
        append!(distances,d)
        end
     #order by indices
     indices = sortperm(distances)
     analogs=[]
     #fo2 = (fcst - obs).^2
     for i in indices
        append!(analogs,obs[i])
     end 
     #double dist2(NumericVector x, NumericVector y)
     #d = Wv*sqrt( sum( (fcst - obs).^2) )/stdev
     return distances,analogs
    end

    function read_all_obs(data_path)
       """
       Note: this can produce high data frames
       """

       files = readdir(data_path, join=false)
       bufr_code="12201"
       print("files ",files)
        glatdump_files = [x for x in files if startswith(x, string("dump","_",bufr_code))]
        df_list = []
        for f in glatdump_files
          println("Reading ",f)
          qs = "SELECT ID, TIME, DATETIME,MEAS FROM glatdump"
          dbase = joinpath(data_path,f)
          df = read_sqlite(dbase,
                printQuery=true,
                use_custom_query_string=true,
                custom_query_string=qs)
           println(names(df))
           println(first(df))
           println("paso 1")
           append!(df_list,[df])
           #innerjoin(df_obs, df, on = :ID)
        end
        df_obs = reduce(vcat, df_list)
        return df_obs
    end

    function read_all_fcst(data_path)
       files = readdir(data_path, join=false)
        glatdump_files = [x for x in files if startswith(x, "dump")]
        qs = "SELECT ID, TIME, DATETIME,MEAS FROM glatdump"
        df_list = []
    end

    function loop_obs(data_path)
      """
      This function loops through all necessary sql files
      and only loads the necessary months.

      """
    end

end # module


