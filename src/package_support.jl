using Requires

@require PlotlyJS begin
    PlotlyJS.js_default[] = :embed
    println("InteractBase: PlotlyJS enabled")
end
