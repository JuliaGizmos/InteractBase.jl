for op in [:filepicker, :autocomplete, :input, :dropdown, :checkbox, :toggle,
           :textbox, :button, :slider, :radiobuttons, :togglebuttons, :tabs, :wrap,
           :manipulateinnercontainer, :manipulateoutercontainer]
    @eval begin
        function $op(args...; kwargs...)
            length(args) > 0 && args[1] isa WidgetTheme && error("")
            $op(gettheme(), args...; kwargs...)
        end
    end
end
