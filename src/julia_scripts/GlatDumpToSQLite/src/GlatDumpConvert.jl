#=
functions to convert glatdump data to sqlite format
=#
module GlatDumpConvert

greet() = print("Hello World!")

import Base
import SQLite
import DataFrames
import Dates
import CSV 
    #PROBLEM: This dictionary does not keep the order!!!
    const parameters = Base.Dict([("ID", "ID"),
		    ("BUFR", "Bufrcode"),
		    ("SENSOR", "SensorNumber"),
		    ("TIME", "Timestamp"),
		    ("MEAS", "Measurement"),])


    function make_sqlite_from_fild7(cmd_message)
	"""Converts fild7 files to a single SQLite file
	Assumes that the cmd_message comes in the following format:
	("fild7_to_sqlite", "<starttime>", "<endtime>", "<file-prefix>", "<indir>", "<sqlfile>")
        """
	@info "Starting make_sqlite_from_fild7"
	starttime   = convert_string_to_datetime(cmd_message[2])
	endtime     = convert_string_to_datetime(cmd_message[3])
	file_prefix = cmd_message[4]
	indir       = cmd_message[5]
	sqlfile     = cmd_message[6]  
        println("File prefix for search fild7",file_prefix)
	glatdump_files = find_glatdump_files(file_prefix, indir, starttime, endtime)

	fild7_to_SQLite(glatdump_files, sqlfile) #, bufrcode)
	@info "Finished"
    end

    function make_sqlite_from_glatdump(cmd_message)
	"""Converts glatdump files to a single SQLite file
	Assumes that the cmd_message comes in the following format:
	("fild7_to_sqlite", "<starttime>", "<endtime>", "<file-prefix>", "<indir>", "<sqlfile>")
	"""
	@info "Starting make_sqlite_from_glatdump"
	starttime   = convert_string_to_datetime(cmd_message[2])
	endtime     = convert_string_to_datetime(cmd_message[3])
	file_prefix = cmd_message[4]
	indir       = cmd_message[5]
	sqlfile     = cmd_message[6]
    bufrcode    = cmd_message[7]

	glatdump_files = find_glatdump_files(file_prefix, indir, starttime, endtime)

	glatdump_to_SQLite(glatdump_files, sqlfile, bufrcode)
      
	@info "Finished"
    end


	    function convert_string_to_datetime(time)
		df = Dates.DateFormat("y-m-d-H-M-S") #Note: Dates gets confused if I use long format YYYYMMDD...
		return Dates.DateTime(time, df)
	    end


	    function find_glatdump_files(file_prefix::String, indir::String, starttime::Dates.DateTime, endtime::Dates.DateTime)
        
		files = readdir(indir, join=false)
		glatdump_files = [x for x in files if startswith(x, file_prefix)]
		#println("files before search ",glatdump_files)
		glatdump_files_within_range = []
        for f in glatdump_files
            println("Found file: ",f[length(f)-13:length(f)])
		    dl = Dates.DateTime(f[length(f)-13:length(f)],"yyyymmddHHMMSS")
		    
		    if dl >= starttime && dl<endtime
			append!(glatdump_files_within_range, [indir*f])
		    end
		end
		return glatdump_files_within_range
	    end

    function glatdump_to_SQLite(glatdump_files, sqlfile::String, bufrcode::String)
    """
    Most relevant BUFR params: 
    12200 (Road temperature)
    12201 (Air temperature at 2m)
    12202 (Dew Point temperature 2m)
    """
    db = SQLite.DB(sqlfile)
    make_glatdump_table(db)
    #target_column_names = [k for (k,v) in parameters]
    target_column_names = ["ID","BUFR","SENSOR","TIME","MEAS"]
    #println("Columns ",target_column_names)
    checkbufrcode=parse(Int64,bufrcode)
    for f in  glatdump_files
      df = CSV.File(f,header=target_column_names) |> DataFrames.DataFrame
      df=df[ [x in [checkbufrcode] for x in df.BUFR] ,:] #this one works!
      #println(names(df))
      #println(typeof(df.TIME))
      get_all_dates= df.TIME
      get_all_string_dates = [ string(k) for k in get_all_dates]
      #println(get_all_string_dates[1:10])
      #println(typeof(get_all_string_dates))
      #println("get_string1 ",get_all_string_dates[1])
      ###get_ts = Dates.Date.(get_all_string_dates,Dates.DateFormat("yyyymmddHHMM"))
      get_ts = Dates.DateTime.(get_all_string_dates,Dates.DateFormat("yyyymmddHHMM"))
      #println("get_ts[1] ",get_ts[1])
      
      get_dates = [Dates.format(ts,"yyyy-mm-dd HH:MM:SS.SSS") for ts in get_ts]
      #println("date ex ",get_dates)
      #get_utime = Dates.DateTime.datetime2unix.(get_ts)
      #get_utime = Dates.DateTime.datetime2unix.(get_ts)

      #time = Int(Dates.datetime2unix(current_time))

      #conv2int = [ Int(k) for k in get_utime]
      #df[:DATETIME] = get_ts

      df.DATETIME = get_dates
      inject_data(db, df, "glatdump")
    end
   end

    function get_and_put_time(f, df)
        """Inserting the Time into DataFrame"""
        current_time = Dates.DateTime(f[length(f)-11:length(f)],"yyyymmddHHMM")
        current_time = Int(Dates.datetime2unix(current_time))
        df["TIME"] = current_time
        return df
    end



    function inject_data(db, dataTable, tablename::String)
        """Inject data into SQLite Table"""
       SQLite.load!(dataTable, db, tablename)
    end


    function make_glatdump_table(db)
        """Makes the glatdump SQL Table if it does not exist"""

        sqliteCreateTable   = """CREATE TABLE IF NOT EXISTS glatdump
                                    (ID INT DEFAULT NULL,
                                    BUFR INT DEFAULT NULL,
                                    SENSOR INT DEFAULT NULL,
                                    TIME INT DEFAULT NULL,
                                    MEAS REAL DEFAULT NULL,
                                    DATETIME TEXT NULL,
                                    PRIMARY KEY (ID, TIME));"""

        SQLite.execute(db, sqliteCreateTable) 
    end
    
    function make_fild7_table(db)
        """Makes the fild7 SQL Table if it does not exist
        stationnr valid_date cloudcover cloudbase airtemperatur dewpoint
        windspeed road_temperature water_on_road
        ice_on_road precip_intensity wind_direction  precipitation_type

        100000 201909102000 1.00 200 14.96 14.53 5 16.47 0.03 0.00 0.02 268 0

        """

        sqliteCreateTable   = """CREATE TABLE IF NOT EXISTS fild7
                                    (ID INT DEFAULT NULL,
                                    VALID_DATE DEFAULT TEXT NULL,
                                    CLOUDCOVER REAL DEFAULT NULL,
                                    CLOUDBASE INT DEFAULT NULL,
                                    AIRTEMPERATUR REAL DEFAULT NULL,
                                    DEWPOINT REAL DEFAULT NULL,
                                    WINDSPEED REAL DEFAULT NULL,
                                    ROAD_TEMPERATURE REAL DEFAULT NULL,
                                    WATER_ON_ROAD REAL DEFAULT NULL,
                                    ICE_ON_ROAD REAL DEFAULT NULL,
                                    PRECIP_INTENSITY REAL DEFAULT NULL,
                                    WIND_DIRECTION REAL DEFAULT NULL,
                                    PRECIPITATION_TYPE INT DEFAULT NULL,
                                    DATETIME TEXT NULL,
                                    PRIMARY KEY (ID, VALID_DATE));"""

        SQLite.execute(db, sqliteCreateTable) 
    end

    function fild7_to_SQLite(glatdump_files, sqlfile::String) #, bufrcode::String)
        """
        Write the forecast fields to sqlite
        """
        db = SQLite.DB(sqlfile)
        make_fild7_table(db)
        @info "made fild7 table"
        #Note: ID is STATIONNR
        target_column_names = ["ID", "VALID_DATE", "CLOUDCOVER", "CLOUDBASE",
         "AIRTEMPERATUR", "DEWPOINT", 
        "WINDSPEED", "ROAD_TEMPERATURE", "WATER_ON_ROAD" ,"ICE_ON_ROAD",
        "PRECIP_INTENSITY","WIND_DIRECTION" ,"PRECIPITATION_TYPE"]
        #println("files ",glatdump_files)

        #checkbufrcode=parse(Int64,bufrcode)
        for f in  glatdump_files
          #println("Going through file ",f)
          df = CSV.File(f,header=target_column_names) |> DataFrames.DataFrame
          get_all_dates= df.VALID_DATE
          get_all_string_dates = [ string(k) for k in get_all_dates]
          get_ts = Dates.DateTime.(get_all_string_dates,Dates.DateFormat("yyyymmddHHMM"))
                   
          get_dates = [Dates.format(ts,"yyyy-mm-dd HH:MM:SS.SSS") for ts in get_ts]
          df.DATETIME = get_dates
   
          #println("Dataframe to inject")
          #println(names(df))
          inject_data(db, df, "fild7")
        end
       end
    

end # module
