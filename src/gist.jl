"""
This file is not complete, and depends upon ExploreSummaryStatistics.jl having been run prior.
This is scraps of code I worked on before merging into the main code file.
"""

function YMDfilter(y, m, d)
    Y = y == "2022"
    M = m == "02"
    D = d == "20"
    return Y && M && D
end
df220220 = filter([:Year, :Month, :Day] => YMDfilter, FIXEDdata)
rawdf220220 = DataFrame(CSV.File("D:/manra/Documents/Data Science/AchieveRenewable/data/csv/SD220220.csv"))
rawdf220220 = filter(:FLOW => >(4.0), rawdf220220)

first(df220220, 20)
first(rawdf220220,20)
last(df220220,20)
last(rawdf220220,20)
describe(rawdf220220)


last(filter([:Year, :Month, :Day] => YMDfilter, FIXEDdata), 20)


#
#   plots
#

using Plots


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

# :"Room Temp" :"Active Setpoint"

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
end

TemperatureAnalysis(FIXEDdata)

"""
We would like to know the difference between Active Setpoint (Column AH) and Room Temp (AG).
Again, this comparison is only important if the equipment is heating or cooling which can be 
confirmed by Mode of Operation (D). This might be good graphed as a differential with 
Active Setpoint set to Zero and the Room Temperature offset by the difference between the two values.
"""

function TempFluxPlot(dfIN::DataFrame)
    gbdata = groupby(dfIN, [:Year, :Month])
    
end
