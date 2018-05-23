# # Tutorial
#
# ## Installing everything
#
# To install a backend of choice (for example InteractUIkit), simply type
# ```julia
# Pkg.clone("https://github.com/piever/InteractBase.jl")
# Pkg.clone("https://github.com/piever/InteractUIkit.jl")
# Pkg.build("InteractUIkit");
# ```

# in the REPL.
#
# The basic behavior is as follows: Interact provides a series of widgets, each widgets has a primary observable that can be obtained with `observe(widget)` and adding listeners to that observable one can provide behavior. Let's see this in practice.
#
# ## Displaying a widget
using InteractUIkit, WebIO
ui = button()
display(ui)

# Note that `display` works in a Jupyter notebook or in Atom, whereas to open it as a standalone Electron window, one would do:
using Blink
w = Window()
body!(w, ui);
# and to serve it in the browser
using Mux
webio_serve(page("/", req -> ui), rand(8000, 9000)) # serve on a random port
#
# ## Adding behavior
# For now this button doesn't do anything. This can be changed by adding callbacks to its primary observable:
o = observe(ui)
# Each observable holds a value and its value can be inspected with the `[]` syntax:
o[]
# In the case of the button, the observable represents the number of times it has been clicked: click on it and check the value again.
#
# To add some behavior to the widget we can use the `on` construct. `on` takes two arguments, a function and an observable. As soon as the observable is changed, the function is called with the latest value.
on(println, o)
# If you click again on the button you will see it printing the number of times it has been clicked so far.
#
# *Tip*: anonymous function are very useful in this programming paradigm. For example, if you want the button to say "Hello!" when pressed, you should use:
on(n -> println("Hello!"), o)
#
# *Tip n. 2*: using the `[]` syntax you can also set the value of the observable:
o[] = 33
# To learn more about Observables, check out their documentation [here](https://juliagizmos.github.io/Observables.jl/latest/).
# ## What widgets are there?
#
# Once you have grasped this paradigm, you can play with any of the many widgets available:
filepicker() # observable is the path of selected file
textbox("Write here") # observable is the text typed in by the user
autocomplete(["Mary", "Jane", "Jack"]) # as above, but you can autocomplete words
checkbox(label = "Check me!") # observable is a boolean describing whether it's ticked
toggle(label = "I have read and agreed") # same as a checkbox but styled differently
slider(1:100, label = "To what extent?", value = 33) # Observable is the number selected

# As well as the option widgets, that allow to choose among options:

dropdown(["a", "b", "c"]) # Observable is option selected
togglebuttons(["a", "b", "c"]) # Observable is option selected
radiobuttons(["a", "b", "c"]) # Observable is option selected

# The option widgets can also take as input a dictionary (ordered dictionary is preferrable, to avoid items getting scrambled), in which case the label displays the key while the observable stores the value:
using DataStructures
s = dropdown(OrderedDict("a" => "Value 1", "b" => "Value 2"))
display(s)
#-
observe(s)[]
#
# ## A simpler approach for simpler cases
#
# While the approach sketched above works for all sorts of situations, there is a specific marcro to simplify it in some specific case. If you want to update some result (maybe a plot) as a function of some parameters (discrete or continuous) simply write `@manipulate` before the `for` loop. Discrete parameters will be replaced by `togglebuttons` and continuous parameters by `slider`: the result will be updated as soon as you click on a button or move the slider:
#
width, height = 700, 300
colors = ["black", "gray", "silver", "maroon", "red", "olive", "yellow", "green", "lime", "teal", "aqua", "navy", "blue", "purple", "fuchsia"]
color(i) = colors[i%length(colors)+1]
ui = @manipulate for nsamples in 1:200,
        sample_step in slider(0.01:0.01:1.0, value=0.1, label="sample step"),
        phase in slider(0:0.1:2pi, value=0.0, label="phase"),
        radii in 0.1:0.1:60
    cxs_unscaled = [i*sample_step + phase for i in 1:nsamples]
    cys = sin.(cxs_unscaled) .* height/3 .+ height/2
    cxs = cxs_unscaled .* width/4pi
    dom"svg:svg[width=$width, height=$height]"(
        (dom"svg:circle[cx=$(cxs[i]), cy=$(cys[i]), r=$radii, fill=$(color(i))]"()
            for i in 1:nsamples)...
    )
end
# or, if you want a plot with some variables taking discrete values:
using Plots, DataStructures

x = y = 0:0.1:30

freqs = OrderedDict(zip(["pi/4", "π/2", "3π/4", "π"], [π/4, π/2, 3π/4, π]))

mp = @manipulate for freq1 in freqs, freq2 in slider(0.01:0.1:4π; label="freq2")
    y = @. sin(freq1*x) * sin(freq2*x)
    plot(x, y)
end

# ## Layout
#
# To create a full blown web-app, you should learn the layout tools that the CSS framework you are using provides. Both [Bulma](https://bulma.io/) and [UIkit](https://getuikit.com/) have modern layout tools for responsive design (of course, use Bulma if you're working with InteractBulma and UIkit if you're working with InteractUIkit). You can use [WebIO](https://github.com/JuliaGizmos/WebIO.jl) to create from Julia the HTML required to create these layouts.
#
# However, this can be overwhelming at first (especially for users with no prior experience in web design). A simpler solution is [CSSUtil](https://github.com/JuliaGizmos/CSSUtil.jl), a package that provides some tools to create simple layouts.
using CSSUtil
loadbutton = filepicker()
hellobutton = button("Hello!")
goodbyebutton = button("Good bye!")
ui = vbox( # put things one on top of the other
    loadbutton,
    hbox( # put things one next to the other
        pad(1em, hellobutton), # to allow some white space around the widget
        pad(1em, goodbyebutton),
    )
)
display(ui)
