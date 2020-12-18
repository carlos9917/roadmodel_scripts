Saving here the master scripts needed to process the data

Order:
Master script: rungrass.sh 
               Calls get_zipfiles.sh: gets zip files
               Uncompress the zip files
               Calls runGrassBathMode.sh: runs Grass, 
               creates runCalcShadows.sh from runCalcTemplate.sh
               runCalcShadows: calls calculateShadows.py, which runs
               the grass utilities to get the shadows
               Cleans up at the end

