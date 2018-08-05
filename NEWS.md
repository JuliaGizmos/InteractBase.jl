# News

## Version 0.7

### Breaking

- Output widgets with options (`tabulator`, `accordion` and `mask`) can be set with `key` or `index` and have as value the `index` of the elemenet(s) that are displayed
- Option widgets now try to preserve value as much as possible when reset.

### Bugfixes

- Fixed `checkboxes`
- Fixed `filepicker` initialization

## Version 0.6

### Breaking

- Deprecated `showvalue` in favor of `readout` to see the output of a slider.
- Removed obsolete `Vue` methods (`props2kwargs` and `kwargs2vueprops`)

### Features

- Added `notifications` widget to display a set of notifications that can be closed.
- Added `highlight` widget to display Julia syntax highlighted code
- Added `alert` and `confirm` widget to display javascript alerts and confirmation dialogues.
- `label` now appears above a `dropdown` and not below it
- Implemented `placeholder` for `dropdown`: a "zeroth" disabled option that appears when value does not match anything
- Added experimental `rangeslider`, a slider with multiple handles, and `rangepicker`
- Added experimental `accordion` and `tooltip!`, to wrap the [accordion](https://wikiki.github.io/components/accordion/) and [tooltip](https://wikiki.github.io/elements/tooltip/) Bulma extension

## Version 0.5

### Breaking

- Deprecated `tabulator(keys, vals)` in favor of `tabulator(OrderedDict(zip(keys, vals)))`
- In `togglebuttons(options, value = x)` `x` should now be one of the values of `options`, rather than one index from `1` to `length(options)`, consistently with all other option widgets
- `style` can no longer be passed as a string but should be passed as a dictionary, i.e. `style=Dict("text-align" => "center", "width" => "100px")`
- `class` can no longer be used, instead one should use the DOM property `className`, i.e. `textbox(className="is-danger")`
- The `outer` keyword no longer exists, to modify a `WebIO.Scope` `s` simply change its DOM, i.e. `s.dom = ...`

### Features

- Observables of widgets can be used in conjunction with `observe`, meaning, if `wdg = Observable(dropdown(["a", "b", "c"]))`, then `observe(wdg)` is an observable that holds the selected value of the dropdown. This is useful when creating a widget from some observable using `map`, for example `options = Observable(["a", "b", "c"]); wdg = map(dropdown, options)`
- Option widgets now store their options as observable, it can be accessed with `observe(wdg, "options")` and modified with `observe(wdg, "options")[] = ["d", "e", "f"]`


### Bugfixes

- Option widgets now accept `OrderedDict` with strings as keys and any Julia value as values
- For any widget, changing the Julia observable also updates the visual widget (the javascript value), even for cases where the Julia type has no javascript equivalent
