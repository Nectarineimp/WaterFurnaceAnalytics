"""
alt-data.jl
"""


using DataFrames, CSV, Statistics, PrettyTables, Printf, Plots, Dates, AverageShiftedHistograms
function alt_loadframe()
    directory = "data/csv/"
    fileNAmes = readdir(directory)
    nfiles = length(fileNAmes)
    retDF = DataFrame()
    i = 0
    for f in fileNAmes
        
        # parse out year, month, day
        year = "20" * f[3:4]
        month = f[5:6]
        day = f[7:8]
        dfN = DataFrame(CSV.File(directory * f))
        
        #update data frame with Year Month and Day
        dfNsize = size(dfN)[1]
        vYear = Vector{String}(undef,dfNsize)
        vYear .= year
        vMonth = Vector{String}(undef, dfNsize)
        vMonth .= month
        vDay = Vector(undef, dfNsize)
        vDay .= day

        dfN.:Year = vYear
        dfN.:Month = vMonth
        dfN.:Day = vDay
        
        retDF = vcat(retDF,dfN)
        i += 1
        if mod(i, 100) == 0
            println(string(i) * " of " * string(nfiles))
        end
    end
    #retDF = filter(:FLOW => x -> x > 4.0, retDF)
    return(retDF)
end

function ReportPowerDemand(dfIN::DataFrame)
    # report on Aux Current Fan Power, Comp Power, Aux Power, Pump Power, Total Power
    gbdf = dfIN
    gbdf = groupby(gbdf, [:Year, :Month])
    gbdf = combine(gbdf, :"Day" => (x -> maximum(x)) => :"Total_Days"
        ,:"Total Power [W]" => (x -> sum(skipmissing(x))/(1000*6*60)) => :"KW/h Total Power for month"
        ,:"Comp Power [W]" => (x -> sum(skipmissing(x))/(1000*6*60)) => :"KW/h Comp Power for month"
        ,:"Aux Power [W]" => (x -> sum(skipmissing(x))/(1000*6*60)) => :"KW/h Aux Power for month"
        ,:"Pump Power [W]" => (x -> sum(skipmissing(x))/(1000*6*60)) => :"KW/h Pump Power for month"
    )
    ### header = ["Year", "Month", "Total_Days", "Kw/h Power for month", "Cost in US Dollars  $0.22 per KW/h"]
    pretty_table(gbdf, header_crayon = crayon"yellow bold", crop = :none, header = (["Year", "Month", "Total Days", "Total Power",  "Comp Power", "Aux Power", "Pump Power"]))
    CSV.write("output/Alt_PowerDemand.csv", gbdf)
end

dfIN = alt_loadframe()
ReportPowerDemand(dfIN)