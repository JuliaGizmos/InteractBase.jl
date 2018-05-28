# API reference

## Text input

These are widgets to select text input that's typed in by the user. For numbers use [`spinbox`](@ref) and for strings use [`textbox`](@ref).

```@docs
spinbox
textbox
autocomplete
```

## Type input

These are widgets to select a specific, non-text, type of input. So far, `Date`, `Time`, `Color` and `Bool` are supported.

```@docs
datepicker
timepicker
colorpicker
checkbox
toggle
```

## File input

```@docs
filepicker
```

## Range input

```@docs
slider
```

## Callback input

```@docs
button
```
## HTML5 input

All of the inputs above are implemented wrapping the `input` tag of HTML5 which can be accessed more directly as follows:

```@docs
InteractBase.input
```

## Option widgets

```@docs
dropdown
togglebuttons
radiobuttons
```
