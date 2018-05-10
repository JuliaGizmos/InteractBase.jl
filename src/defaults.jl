for op in [:choosefile, :autocomplete, :input, :dropdown, :checkbox, :textbox, :button, :slider]
    @eval begin
        function $op(args...; kwargs...)
            length(args) > 0 && args[1] isa CSSFramework && error("")
            $op(backend[], args...; kwargs...)
        end
    end
end
