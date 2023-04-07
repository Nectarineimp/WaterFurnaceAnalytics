# Explore Summary Statistics

# Packages
using DataFrames, CSV, Statistics, PrettyTables, Printf, Plots

# Global Variables
OutputFile = open("output/AR_Report.txt", "w")

"""
main loop

"""
function mainloop()
    # report(FIXEDdata)
end

"""
Fault Codes
Returns the unique fault codes found in the data.
"""
function faultcodes(dfIF)
    gbdfN = groupby(dfIF, "Fault Code")
    faultK = keys(gbdfN)
    return faultK
end

function ReportFaultCodes(dfIF)
    println("Detected Fault Codes")
    for fc in faultcodes(dfIF)
        println(fc)
    end
    println()
end

function returndata()
    directory = "data/csv/"
    filenames = readdir(directory)
    nfiles = length(filenames)
    retDF = DataFrame()
    i = 0
    for f in filenames
        
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
    retDF = filter(:FLOW => x -> x > 4.0, retDF)
    return(retDF)
end

#
# Reports
#
#

function report(dfIF)
    ReportFaultCodes(dfIF)
    GeneralSummary(dfIF)
    EnteringWaterReport(dfIF)
    ReportFaultDistributionbymonthyear(dfIF)
    ReportEWTBreakdownbyYM(dfIF)
    ReportEWTsummary(dfIF)
    ReportPowerDemand(dfIF)
    TemperatureAnalysis(dfIF)
end

function ReporttoFile(dfIF::DataFrame)
    open("output/AR_Report.txt", "w") do out
        redirect_stdout(out) do 
            report(dfIF)
        end
        close(out)
    end
end


# REPORTS

function missFilter(x)
    return x != "missing"
end

function GeneralSummary(dfIF::DataFrame)
    gbdf = groupby(dfIF[!,1:5], [:"Fault Code", :"Mode"])
    pretty_table(sort(combine(gbdf, :EWT => mean, nrow), [:"Fault Code", :nrow]),
       header = ["Fault Code", "Mode", "EWT Mean Temp", "Number of Events"],
       header_crayon = crayon"yellow bold")
    println()
end

function EnteringWaterReport(dfIN::DataFrame)
    dfEWT = dfIN
    println("Entering Water Temperature Reports")
    println("Quantiles:\n0.25\t0.50\t0.75\t0.85\t0.95")
    for n in quantile(dfEWT.EWT, [0.25, 0.50, 0.75, 0.85, 0.95])
        print(string(n) * "\t")
    end
    print("\n")
    println("EWT High        Low     Median   Mean")
    print(string(maximum(dfEWT.EWT)) * "\t\t" * string(minimum(dfEWT.EWT)) * "\t" * string(median(dfEWT.EWT)) * "\t " * string(mean(dfEWT.EWT)) * "\t\n")
    println()
end

function ReportFaultDistributionbymonthyear(dfIF::DataFrame)
    FInput = filter(:"Fault Code" => x -> missFilter(x), dropmissing(dfIF))
    gb = groupby(FInput, [:"Year", :"Month", :"Day", "Fault Code"])
    cgb = combine(gb, nrow => :Duration)
    cgb[:, :Duration] .= cgb[:, :Duration] * 10
    pretty_table(cgb, header = ["Year", "Month", "Day", "Fault Code", "Duration in seconds"], header_crayon = crayon"yellow bold", crop = :none)
    CSV.write("output/FaultDistribution.csv", cgb)
end

function ReportEWTsummary(dfIN::DataFrame)
    FInFData = dfIN
    println("EWT Summary")
    @printf "\tMean Temperature:     %.2f\n" mean(FInFData[:,:EWT])
    println("\tMedian Temperature:   "*string(median(FInFData[:,:EWT])))
    println("\tStdDEv Temperature:   "*string(std(FInFData[:,:EWT])))
    println("\tVariance Temperature: "*string(var(FInFData[:,:EWT])))
    println("\tMax Temperature: "*string(maximum(FInFData[:,:EWT])))
    println("\tMinimum Temperature: "*string(minimum(FInFData[:,:EWT])))
end

function ReportEWTBreakdownbyYM(dfIN::DataFrame)
    gbdata = dfIN
    gbdata = groupby(gbdata, [:Year, :Month])
    gbdata = combine(gbdata, :EWT => mean, :EWT => median, :EWT => std, :EWT => var, :EWT => maximum, :EWT => minimum, :EWT => length)
    println("YEAR/MONTH comparison of Entering Water Temperature")
    println(gbdata)
    println()
    CSV.write("output/EWTBreakdownbyYearMonth.csv", gbdata)
end

function ReportPowerDemand(dfIN::DataFrame)
    gbdf = groupby(dfIN, [:Year, :Month])
    gbdf = combine(gbdf, :"Day" => (x -> maximum(x)) => :"Total_Days",
                        :"Total Power" => (x -> sum(x)/(1000*6*60)) => :"KW/h Power for month")
    gbdf = combine(gbdf, :"Year", :"Month", :"Total_Days", :"KW/h Power for month", :"KW/h Power for month" => (x -> x * 0.2200) => :"Cost in US Dollars")
    ### header = ["Year", "Month", "Total_Days", "Kw/h Power for month", "Cost in US Dollars  $0.22 per KW/h"]
    pretty_table(gbdf, header_crayon = crayon"yellow bold", crop = :none, header = (["Year", "Month", "Total_Days", "Kw/h Power for month", "Cost in US Dollars"],["","","","","@ \$0.22 / KW/h"]))
    CSV.write("output/PowerDemand.csv", gbdf)
end

"""
room temp vs room setpoint
"""

function myround(x::Float64) round(x, digits=3) end
function difference(A::Float64, B::Float64)
    return A-B
end
function difference(A::Tuple)
    return A[1]-A[2]
end
function difference(A::SubArray)
    return A[1]-A[2]
end
# combine(gbdata, :"Room Temp" => mean => :RTMean, :"Active Setpoint" => mean => :ASMean)

function TemperatureAnalysis(gbdata::DataFrame)
    gbdata[:, :TempDiff] = myround.(gbdata[:, :"Room Temp"] - gbdata[:, :"Active Setpoint"])
    gbdata = groupby(gbdata, [:Year, :Month])
    gbdata = combine(gbdata, :"Room Temp" => mean => :RTMean,
        :"Active Setpoint" => mean => :ASMean,
        :"TempDiff" => mean => :Temperature_Difference)
    pretty_table(gbdata,
        header = ["Year", "Month", "Room Temp mean", "Active Setpoint Mean", "Temperature Difference Mean"],
        header_crayon = crayon"yellow bold")
    CSV.write("output/TemperatureAnalysis.csv", gbdata)
end

#
#   Plots
#

"""
    MakeSeries(data)
    Takes a dataframe of WaterFurnace telemetry, filterd on Flow > 4.0.
"""
function MakeSeries(data::DataFrame)
    gbdata = data
    gbdata = groupby(gbdata, [:Year, :Month])
    gbdata = combine(gbdata, :EWT => mean)
    returnDF = DataFrame(SeriesName=String[], SeriesData=Array[])
    for Year in unique(gbdata[:, :Year])
        xydata = (filter(:Year => Y -> Y==(Year), gbdata))[:, [:Month, :EWT_mean]]
        println(" Year " * Year)
        seriesdata = zeros(12)
        for xy in  eachrow(xydata)
            seriesdata[parse(Int, xy[1])] = xy[2]
            println("Year: " * Year * " Month: " * xy[1] * " Value: " * string(xy[2]))
        end
        push!(returnDF, (Year, seriesdata))
    end
    return returnDF
end


"""
    CreatePlot(dfData::DataFrame)

Plots the data generated in MakeSeries().
"""
function CreatePlot(dfData::DataFrame)
    PLT = plot()
    plot!(title = "Entering Water Temp Mean by month", xlabel = "Month", ylabel = "Temp")
    plot!(xlims = (1,12), xticks = 0:1:12)
    dfSeriesData = MakeSeries(dfData)
    labels = reshape(dfSeriesDataT[:, :SeriesName], 1, :)
    plot!(label = labels, dfSeriesData[:, :SeriesData])
    plot!()
    savefig("output/EWTMbM.png")
end

#
# Global and top level declarations
# Run this code last
#

const global FIXEDdata = returndata()
report(FIXEDdata)
ReporttoFile(FIXEDdata)

# No code beyond this point