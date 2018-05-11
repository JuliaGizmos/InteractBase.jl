for op in [:choosefile, :autocomplete, :input, :dropdown, :checkbox, :toggle, :textbox, :button, :slider]
    @eval begin
        function $op(args...; kwargs...)
            length(args) > 0 && args[1] isa WidgetTheme && error("")
            $op(last(backend), args...; kwargs...)
        end
    end
end
