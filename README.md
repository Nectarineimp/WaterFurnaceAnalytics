# WaterFurnaceAnalytics
##Analytics applied to Water Furnace xlsx telemetry output.

###Version: v0.1.0

The great thing about WaterFurnace equipment is the amount of raw data they can provide. It's also 
the downfall for people without heavy data science skills. In analyzing several years of telemetry
data I had 1200+ data files in XLSX format with a highly formatted sheet. It also represents
~800 million data points. This is beyond the capability of tools like Excel. Even the number of columns,
87 in the case of this analysis, is hard to navigate with Excel.

This analysis is primarily focused on analyzing temperature over time, power use and cost, and give a basic insight
into system errors. In the future I may delve more into error diagnostics with this code.

The current state of the code requires a lot of tech debt to clean up. This will make it more modular, and
adaptable to other analytics. Currently the processing time is 98% spent on converting the XLSX files to CSV
files. The time to process is reduced by keeping the CSV files so you can
skip the previous conversion step. This makes iteration of testing easier. If you are using the REPL you can
rely upon the data remaining in memory and test new changes in the REPL IF YOU DON'T CORRUPT THE MAIN
DATA OBJECT "FIXEDdata".

The conversion is done with a unix shell script. I use WSL 1.X (should work just as well with WSL 2.X) If you know
of a better way of doing it in windows, create an issue and if you are ambitious, a pull request.

Directories are hardcoded into the code. These need to be in a configuration file. Part of the technical debt.

