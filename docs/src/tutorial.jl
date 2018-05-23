# # Tutorial
#
# ## Installing everything
#
# To install a backend of choice (for example InteractUIkit), simply type
# ```
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
settheme!(UIkit())
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
