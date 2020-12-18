module GlatDumpToSQLite

using Base
import Dates
import DataFrames
import SQLite

include("arg_handler.jl")
include("GlatDumpConvert.jl")

import .arg_handler
## import .glatdump_to_sqlite
import GlatDumpToSQLite


function __init__()
   
end

function main(args)
    println("arguments ",args)
    cmd_message = arg_handler.main_args(args)
    println("Command ",cmd_message[1])
    if cmd_message[1]==="glatdump_to_sqlite"
        GlatDumpConvert.make_sqlite_from_glatdump(cmd_message) 
    elseif cmd_message[1]==="fild7_to_sqlite"
        GlatDumpConvert.make_sqlite_from_fild7(cmd_message)
        
    else
        nothing
    end
    #cmd_message[1]==="glatdump_to_sqlite" ? GlatDumpConvert.make_sqlite_from_glatdump(cmd_message) : nothing
    #cmd_message[1]==="fild7_to_sqlite" ? GlatDumpConvert.make_sqlite_from_fild7(cmd_message) : nothing
end


end
