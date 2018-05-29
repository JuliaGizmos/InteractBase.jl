for op in [:filepicker, :datepicker, :colorpicker, :timepicker, :spinbox,
           :autocomplete, :input, :dropdown, :checkbox, :toggle,
           :textbox, :button, :slider, :radio,
           :radiobuttons, :togglebuttons, :tabs, :checkboxes, :toggles,
           :wrap, :wdglabel,
           :manipulateinnercontainer, :manipulateoutercontainer]
    @eval begin
        function $op(args...; kwargs...)
            length(args) > 0 && args[1] isa WidgetTheme &&
                error("Function " * string($op) * " was about to overflow: check the signature")
            $op(gettheme(), args...; kwargs...)
        end
    end
end
