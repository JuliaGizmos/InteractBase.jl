using InteractBase, CSSUtil
using InteractBulma

#---

f = filepicker();
display(f)
f["filename"]
f["path"]
observe(f)

#---

f = filepicker(multiple = true, accept = ".csv");
display(f)
f["filename"]
f["path"]
observe(f)
#---

s = autocomplete(["Opt 1", "Option 2", "Opt 3"])
display(s)
#---
s = InteractBase.input(typ="color")
display(s)
#---
s1 = slider(1:20)
sobs = observe(s1)
display(vbox(s1, sobs));
#---
button1 = button("button one {{clicks}}")
num_clicks = observe(button1)
button2 = button("button two {{clicks}}", clicks = num_clicks)
display(hbox(button1, button2, num_clicks));
#---
using WebIO, Blink
settheme!(Bulma())
w = Window()

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
body!(w, ui)
#---

using InteractBase, PlotlyJS, CSSUtil, DataStructures

x = y = 0:0.1:30
p = plot(x, y)

freqs = OrderedDict(zip(["pi/4", "π/2", "3π/4", "π"], [π/4, π/2, 3π/4, π]))

mp = @manipulate for freq1 in freqs, freq2 in slider(0.01:0.1:4π; label="freq2")
    y = @. sin(freq1*x) * sin(freq2*x)
    plot(x, y)
end
display(vbox(mp, p))

#---
# IJulia (example 2)
p.displayed = true
display(ui);
# Mux
using Mux
webio_serve(page("/", req -> ui))
#^^^
#---
# Blink
w = Window()
p.view.w = w # needed until PlotlyJS.jl is better integrated with WebIO.jl
body!(w, ui)
#^^^
#---
# Atom
w = get_page()
p.view.w = w
body!(w, ui)
#^^^
#---
