libraries(::CSSFramework) = String[]

deps = libraries(NativeHTML())
backend = Ref{CSSFramework}(NativeHTML())

set_libraries(args) = (empty!(deps); append!(deps, args))
set_libraries(args::AbstractString...) = set_libraries(args)

function set_backend(b::CSSFramework, libs::AbstractArray{<:AbstractString} = libraries(b))
    backend[] = b
    set_libraries(libs)
    return
end
