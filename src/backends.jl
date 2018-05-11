libraries(::WidgetTheme) = String[]

deps = libraries(NativeHTML())
backend = Ref{WidgetTheme}(NativeHTML())

setlibraries(args) = (empty!(deps); append!(deps, args))
setlibraries(args::AbstractString...) = setlibraries(args)

function settheme!(b::WidgetTheme, libs::AbstractArray{<:AbstractString} = libraries(b))
    backend[] = b
    setlibraries(libs)
    return
end
