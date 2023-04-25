# Explore Summary Statistics

# Packages
using DataFrames, CSV, Statistics, PrettyTables, Printf, Plots, Dates, AverageShiftedHistograms

# Global Variables
OutputFile = open("output/AR_Report.txt", "w")

"""
    returndata()

        This function builds the 847,000,000 data point model as a DataFrame.
        It requires CSV files from the WaterFurnace software. There are several
        forms of CSV files provided by WF but this function is agnostic to
        which ones are being used. The main difference is the column names. 
        Column names will have to be updated in the reports to match the downloaded
        data's names.
"""
function returndata()
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

#
# Reports
#
#

"""
    Fault Codes
        Returns the unique fault codes found in the data.
"""
function faultcodes(dfIF)
    gbdfN = groupby(dfIF, "Fault Code")
    faultK = keys(gbdfN)
    return faultK
end

"""
    ReportFaultCodes()
        A very basic report on the fault codes.
"""
function ReportFaultCodes(dfIF)
    println("Detected Fault Codes")
    for fc in faultcodes(dfIF)
        println(fc)
    end
    println()
end

"""
    report(DataFile)
        This is the master report function. It runs all of the reports. It can be called
        as is for a screen display of the reports, or called in a wrapper function that 
        redirects the output to a file.
"""
function report(dfIF)
    # Power Reports
    ReportPowerDemand(dfIF)
    ReportFaultCodes(dfIF)
    GeneralSummary(dfIF)
    # Fault Reports
    ReportFaultDistributionbymonthyear(dfIF)
    # Entering Water Reports
    global FIXEDdata = filter(:FLOW => x -> x > 4.0, FIXEDdata) # water must be flowing to have its temp sampled.
    EnteringWaterReport(dfIF)
    ReportEWTBreakdownbyYM(dfIF)
    ReportEWTsummary(dfIF)
    TemperatureANAlysis(dfIF)
    CreatePlot(dfIF)
    # focus months for EWT study
    FineEWT(FIXEDdata, 2018, 10)
    FineEWT(FIXEDdata, 2018, 11)
    FineEWT(FIXEDdata, 2018, 12)
    FineEWT(FIXEDdata, 2019, 1)
end

"""
    ReporttoFile(Dataframe)
        A wrapper function to redirect output to a file instead of STDIO.
"""
function ReporttoFile(dfIF::DataFrame)
    open("output/AR_Report.txt", "w") do out
        redirect_stdout(out) do 
            report(dfIF)
            close(out)
        end
    end
end


# REPORTS

# Helper Functions
"""
    missFilter(vector)
        A helper function for custom 
"""
function missFilter(x)
    return x != "missing"
end

"""
    myround(Float64)
        Useful for 3 decimial place rounding of decimal numbers.
"""
function myround(x::Float64) round(x, digits=3) end

"""
    difference(Float64, Float64)
        Used to simplify difference calculation in functional blocks.
"""
function difference(A::Float64, B::Float64)
    return A-B
end

"""
    difference(Tuple)
        Used to simplify difference calculation in functional blocks.
"""
function difference(A::Tuple)
    return A[1]-A[2]
end

"""
    difference(SubArray)
        Used to simplify difference calculation in functional blocks.
"""
function difference(A::SubArray)
    return A[1]-A[2]
end

# Fault Code Reports
"""
    GeneralSummary(DataFrame)
        A basic analysis to see what error codes exist in the data.
"""
function GeneralSummary(dfIF::DataFrame)
    gbdf = groupby(dfIF[!,1:5], [:"Fault Code", :"Mode"])
    pretty_table(combine(gbdf, :EWT => mean, nrow), [:"Fault Code", :nrow],
       header = ["Fault Code", "Mode", "EWT Mean Temp", "Number of Events"],
       header_crayon = crayon"yellow bold")
    println()
end

"""
    ModeCheck(DataFrame)
        List unique Mode codes. Mainly used to check to see if Lockdown mode was ever active.
"""
function ModeCheck(dfIF::DataFrame)
    println(unique(dfif[:, :Mode]))
end

# EWT Reports

"""
    EnteringWaterReport
        This report gives fundamental summary statistics, used to validate the data against
        assumptions of water temperature entering the system.
"""
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

"""
    ReportFaultDistributionbymonthyear(DataFrame)
        Report used to examine the faults and duration of the faults on a daily basis.
"""
function ReportFaultDistributionbymonthyear(dfIF::DataFrame)
    FInput = filter(:"Fault Code" => x -> missFilter(x), dropmissing(dfIF))
    gb = groupby(FInput, [:"Year", :"Month", :"Day", "Fault Code"])
    cgb = combine(gb, nrow => :Duration)
    cgb[:, :Duration] .= cgb[:, :Duration] * 10
    pretty_table(cgb, header = ["Year", "Month", "Day", "Fault Code", "Duration in seconds"], header_crayon = crayon"yellow bold", crop = :none)
    CSV.write("output/FaultDistribution.csv", cgb)
end

"""
    ReportEWTsummary(DataFrame)
        Report of overall statistical data on Entering Water Temperature.
"""
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

"""
    ReportEWTBreakdownbyYM(DataFrame)
        Monthly EWT statistical data
"""
function ReportEWTBreakdownbyYM(dfIN::DataFrame)
    gbdata = dfIN
    gbdata = groupby(gbdata, [:Year, :Month])
    gbdata = combine(gbdata, :EWT => mean, :EWT => median, :EWT => std, :EWT => var, :EWT => maximum, :EWT => minimum, :EWT => length)
    println("YEAR/MONTH comparison of Entering Water Temperature")
    println(gbdata)
    println()
    CSV.write("output/EWTBreakdownbyYearMonth.csv", gbdata)
end

"""
    ReportPowerDemand(DataFrame)
        Converts Watts into Kilowatts per hour and reports my month and year.
"""
function ReportPowerDemand(dfIN::DataFrame)
    # report on Aux Current Fan Power, Comp Power, Aux Power, Pump Power, Total Power
    gbdf = groupby(dfIN, [:Year, :Month])
    gbdf = combine(gbdf, :"Day" => (x -> maximum(x)) => :"Total_Days"
        ,:"Total Power" => (x -> sum(x)/(1000*6*60)) => :"KW/h Total Power for month"
        ,:"Aux Current" => (x -> sum(x)/(1000*6*60)) => :"KW/h Aux Current for month"
        ,:"Fan Power" => (x -> sum(x)/(1000*6*60)) => :"KW/h Fan Power for month"
        ,:"Comp Power" => (x -> sum(x)/(1000*6*60)) => :"KW/h Comp Power for month"
        ,:"Aux Power" => (x -> sum(x)/(1000*6*60)) => :"KW/h Aux Power for month"
        ,:"Pump Power" => (x -> sum(x)/(1000*6*60)) => :"KW/h Pump Power for month"
    )
    ### header = ["Year", "Month", "Total_Days", "Kw/h Power for month", "Cost in US Dollars  $0.22 per KW/h"]
    pretty_table(gbdf, header_crayon = crayon"yellow bold", crop = :none, header = (["Year", "Month", "Total Days", "Total Power", "Aux Current",  "Fan Power", "Comp Power", "Aux Power", "Pump Power"]))
    CSV.write("output/PowerDemand.csv", gbdf)
end

"""
    TemperatureANAlysis(DataFrame)
        Used to analyze the difference between Room Temperature and the Set Point of
        desired temperature. Reports by Year, and Month aggregates.
"""
function TemperatureANAlysis(gbdata::DataFrame)
    gbdata[:, :TempDiff] = myround.(gbdata[:, :"Room Temp"] - gbdata[:, :"Active Setpoint"])
    gbdata = groupby(gbdata, [:Year, :Month])
    gbdata = combine(gbdata, :"Room Temp" => mean => :RTMean,
        :"Active Setpoint" => mean => :ASMean,
        :"TempDiff" => mean => :Temperature_Difference)
    pretty_table(gbdata,
        header = ["Year", "Month", "Room Temp mean", "Active Setpoint Mean", "Temperature Difference Mean"],
        header_crayon = crayon"yellow bold")
    CSV.write("output/TemperatureANAlysis.csv", gbdata)
end

#
#   Plots
#

"""
    MakeSeries(DataFrame)
        Takes a dataframe of WaterFurNAce telemetry, filterd on Flow > 4.0.
"""
function MakeSeries(data::DataFrame)
    gbdata = data
    gbdata = groupby(gbdata, [:Year, :Month])
    gbdata = combine(gbdata, :EWT => mean)
    returnDF = DataFrame(SeriesName=String[], SeriesData=Array[])
    for Year in unique(gbdata[:, :Year])
        xydata = (filter(:Year => Y -> Y==(Year), gbdata))[:, [:Month, :EWT_mean]]
        println(" Year " * Year)
        seriesdata = fill(missing, 12)
        seriesdata = convert(Array{Union{Float64, Missing}}, seriesdata)
        for xy in  eachrow(xydata)
            seriesdata[parse(Int, xy[1])] = xy[2]
        end
        push!(returnDF, (Year, seriesdata))
    end
    return returnDF
end


"""
    CreatePlot(DataFrame)
        Plots the data generated in MakeSeries().
"""
function CreatePlot(dfData::DataFrame)
    dfIN = dfData
    dfData = filter(:FLOW => x -> x > 4.0, dfData)
    PLT = plot()
    plot!(title = "Entering Water Temp Mean by month", xlabel = "Month", ylabel = "Temp")
    plot!(xlims = (1,12), xticks = 0:1:12)
    dfSeries = MakeSeries(dfData)
    labels = reshape(dfSeries[:, :SeriesName], 1, :)
    plot!(label = labels, dfSeries[:, :SeriesData])
    println("Plotting...\n")
    plot!()
    savefig("output/EWTMbM.png")
end

"""
    CalcTimeGroup(Time, Int64)
        Helper function, takes the time stamp, and an interval in minutes, and creates an index
"""
function CalcTimeGroup(T::Time, I::Int64)
    I = I * 60 #convert Interval Minutes to seconds
    ElapsedSeconds = div(Dates.value(T), 1_000_000_000)
    Return(div(ElapsedSeconds, I)+1)
end

"""
    CalcTimeGroup(Time, Int64)
        Helper function, takes several time stamps, and an interval in minutes, and creates a vector of indexes
"""
function CalcTimeGroup(T::Vector{Time}, I::Int64)
    returnvalue = Vector()
    I = I * 60 #convert Interval Minutes to seconds
    for t in T
        ElapsedSeconds = div(Dates.value(t), 1_000_000_000)
        push!(returnvalue, div(ElapsedSeconds, I)+1)
    end
    return returnvalue
end

"""
    FineEWT(DataFrame, Int64, Int64, Int64)
"""
function FineEWT(dfIN::DataFrame, Year::Int64, Month::Int64,  IntervalMins::Int64=15)
    gbdata = dfIN
    dfIN = filter(:FLOW => x -> x > 4.0, dfIN)
    gbdata = filter(:Year => Y -> parse(Int, Y) == Year, gbdata)
    gbdata = filter(:Month => M -> parse(Int, M) == Month, gbdata)
    
    o = ash(gbdata[:, :EWT])
    PLT = plot(o)
    plot!(PLT, title = "Entering Water Temperature to Frequency: " * string(Month) * "/" * string(Year))
    plot!(PLT, ylabel! = "Frequency", xlabel! = "Temperature (F)")
    savefig(PLT, "output/ASH" * string(Year) * string(Month) * ".png")

    maximumseries = medianseries = minimumseries = Vector()
    gbdata = groupby(gbdata, :Day)
    maximumseries = Vector()
    medianseries = Vector()
    minimumseries = Vector()
    PLT2 = plot(title = "Temperature Variations " * string(Month) * "/" * string(Year))
    plot!(PLT2, xlabel = "Day of Month", ylabel = "Temperature")
    for g in gbdata push!(medianseries, median(g[:, :EWT])) end
    for g in gbdata push!(maximumseries, maximum(g[:, :EWT])) end
    for g in gbdata push!(minimumseries, minimum(g[:, :EWT])) end
    plot!(PLT2, 1:length(maximumseries), [maximumseries medianseries minimumseries], label=["Maximum" "Median" "Minimum"], linewidth=3)
    savefig(PLT2, "output/tempbyday" * string(Year) * string(Month) * ".png")
end

#
# Global and top level declarations
# Run this code last
#

# FIXEDdata is the entire 847,000,000 data point model used by every calculation.
# This model takes about 35-40 minutes to build.
global FIXEDdata = returndata()

# run reports. Uncomment report for on screen reports. Uncomment ReporttoFile for
# a dump of data to files.
# report(FIXEDdata)
ReporttoFile(FIXEDdata)

# No code beyond this point