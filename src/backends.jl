libraries(::CSSFramework) = String[]

deps = libraries(NativeHTML())
backend = Ref{CSSFramework}(NativeHTML())

setlibraries(args) = (empty!(deps); append!(deps, args))
setlibraries(args::AbstractString...) = setlibraries(args)

function setbackend(b::CSSFramework, libs::AbstractArray{<:AbstractString} = libraries(b))
    backend[] = b
    setlibraries(libs)
    return
end
