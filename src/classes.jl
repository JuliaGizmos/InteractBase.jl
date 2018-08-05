mergeclasses(args...) = join(args, ' ')

function getclass(T::WidgetTheme, arg, typ...)
    length(typ) > 0 && last(typ) == "label" && return ""
    if arg == :input
        typ==() && return "input"
        typ[1] in ["checkbox", "radio"] && return "is-checkradio"
        typ[1]=="toggle" && return "switch"
        typ==("range",) && return "slider"
        typ==("range", "fullwidth") && return "slider is-fullwidth"

        if typ[1]=="file"
            typ[2:end]==() && return "file"
            typ[2:end]==("span",) && return "file-cta"
            typ[2:end]==("span", "icon") && return "file-icon"
            typ[2:end]==("span","label") && return "file-label"
            typ[2:end]==("icon",) && return "fas fa-upload"
            typ[2:end]==("label",) && return "file-label"
            typ[2:end]==("name",) && return "file-name"
        end
        return "input"
    elseif arg == :dropdown
        return typ == (true,) ? "select is-multiple" : "select"
    elseif arg == :button
        typ==("primary",) && return "is-primary"
        typ==("active",) && return "is-primary is-selected"
        typ==("fullwidth",) && return "is-fullwidth"
        return "button"
    elseif arg==:tab
        typ==("active",) && return "is-active"
        return "not-active"
    elseif arg == :textarea
        return "textarea"
    elseif arg==:wdglabel
        return "interact"
    elseif arg==:div
        return "field"
    elseif arg==:togglebuttons
        return "field is-grouped has-addons is-oneline is-centered"
    elseif arg==:tabs
        return "tabs"
    elseif arg==:radiobuttons
        return "field"
    elseif arg==:ijulia
        return "interactbulma"
    else
        return ""
    end
end
