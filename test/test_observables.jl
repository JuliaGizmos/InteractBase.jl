@testset "input" begin
    a = InteractBase.input()
    @test widgettype(a) == :input
    @test observe(a)[] == ""
    a = InteractBase.input(typ = "number");
    @test observe(a)[] == 0
    s = Observable{Any}(12)
    a = InteractBase.input(s, typ = "number");
    @test observe(a)[] == s[]
end

@testset "input widgets" begin
    a = filepicker()
    @test widgettype(a) == :filepicker
    @test a["filename"][] == ""
    @test a["path"][] == ""
    a["path"][] = "/home/Jack/documents/test.csv"
    @test a["path"][] == observe(a)[] == "/home/Jack/documents/test.csv"

    a = datepicker(value = Dates.Date(01,01,01))
    b = datepicker(Dates.Date(01,01,01))
    @test observe(a)[] == observe(b)[] == Dates.Date(01,01,01)
    @test widgettype(a) == :datepicker

    a = colorpicker(value = colorant"red")
    b = colorpicker(colorant"red")
    @test observe(a)[] == observe(b)[] == colorant"red"
    @test widgettype(a) == :colorpicker


    a = spinbox(label = "")
    @test widgettype(a) == :spinbox
    @test observe(a)[] == nothing

    a = textbox();
    @test widgettype(a) == :textbox

    @test observe(a)[] == ""
    s = "asd"
    a = textbox(value = s);
    @test observe(a)[] == "asd"

    a = textarea();
    @test widgettype(a) == :textarea

    @test observe(a)[] == ""
    s = "asd"
    a = textarea(value = s);
    @test observe(a)[] == "asd"

    a = autocomplete(["aa", "bb", "cc"], value = "a");
    @test widgettype(a) == :autocomplete

    @test observe(a)[] == "a"

    a = button("Press me!", value = 12)
    @test widgettype(a) == :button
    @test observe(a)[] == 12

    a = toggle(label = "Agreed")
    @test widgettype(a) == :toggle

    @test observe(a)[] == false
    s = Observable(true)
    a = toggle(s, label = "Agreed")
    @test observe(a)[] == true

    a = togglecontent(checkbox("Yes, I am sure"), "Are you sure?")
    @test widgettype(a) == :togglecontent

    @test observe(a)[] == false
    s = Observable(true)
    a = togglecontent(checkbox("Yes, I am sure"), "Are you sure?", value = s)
    @test observe(a)[] == true

    v = slider([0, 12, 22], value = 12)
    @test widgettype(v) == :slider

    @test observe(v)[] == 12
    @test v["internalvalue"][] == 2
    # v["internalvalue"][] = 3
    # @test observe(v)[] == 22
end

@testset "options" begin
    a = dropdown(["a", "b", "c"])
    @test widgettype(a) == :dropdown

    @test observe(a)[] == "a"
    a = dropdown(OrderedDict("a" => 1, "b" => 2, "c" => 3))
    @test observe(a)[] == 1
    a = dropdown(OrderedDict("a" => 1, "b" => 2, "c" => 3), value = 3)
    @test observe(a)[] == 3

    a = togglebuttons(["a", "b", "c"])
    @test widgettype(a) == :togglebuttons

    @test observe(a)[] == "b"
    a = togglebuttons(OrderedDict("a" => 1, "b" => 2, "c"=>3))
    @test observe(a)[] == 2
    a = togglebuttons(OrderedDict("a" => 1, "b" => 2, "c" => 4), value = 4)
    @test observe(a)[] == 4

    a = radiobuttons(["a", "b", "c"])
    @test widgettype(a) == :radiobuttons

    @test observe(a)[] == "a"
    a = radiobuttons(OrderedDict("a" => 1, "b" => 2, "c" => 3))
    @test observe(a)[] == 1
    a = radiobuttons(OrderedDict("a" => 1, "b" => 2, "c" => 3), value = 3)
    @test observe(a)[] == 3

    a = tabulator(OrderedDict("a" => 1.1, "b" => 1.2, "c" => 1.3))
    @test a[:buttons] isa InteractBase.Widget{:togglebuttons}
    @test a[:buttons][:index][] == 1
    @test observe(a, :buttons)[] == 1.1
    observe(a)[] = 2
    sleep(0.1)
    @test a[:buttons][:index][] == 2
    @test observe(a, :buttons)[] == 1.2

    a = tabulator(OrderedDict("a" => 1.1, "b" => 1.2, "c" => 1.3), value = 0)
    @test a[:buttons][:index][] == 0
    @test observe(a, :buttons)[] == nothing
end

@testset "ijulia" begin
    @test !InteractBase.isijulia()
end

@testset "widget" begin
    s = slider(1:100, value = 12)
    w = InteractBase.Widget{:test}(s.children, scope = InteractBase.scope(s), output = Observable(1))
    @test observe(w)[] == 1
    @test widgettype(s) == :slider
    @test widgettype(w) == :test
    @test w["value"][] == 12
    InteractBase.primary_obs!(w, "value")
    @test observe(w)[] == 12

    w = InteractBase.widget(Observable(1))
    @test !InteractBase.hasscope(w)
end

@testset "manipulate" begin
    ui = @manipulate for r = 0:.05:1, g = 0:.05:1, b = 0:.05:1
        RGB(r,g,b)
    end
    @test observe(ui)[] == RGB(0.5, 0.5, 0.5)
    observe(ui, :r)[] = 0.1
    sleep(0.1)
    @test observe(ui)[] == RGB(0.1, 0.5, 0.5)

    ui = @manipulate throttle = 1 for r = 0:.05:1, g = 0:.05:1, b = 0:.05:1
        RGB(r,g,b)
    end
    observe(ui, :r)[] = 0.1
    sleep(0.1)
    observe(ui, :r)[] = 0.3
    sleep(0.1)
    observe(ui, :g)[] = 0.1
    sleep(0.1)
    observe(ui, :g)[] = 0.3
    sleep(0.1)
    observe(ui, :b)[] = 0.1
    sleep(0.1)
    observe(ui, :b)[] = 0.3
    sleep(0.1)
    @test observe(ui)[] != RGB(0.3, 0.3, 0.3)
    sleep(1.5)
    @test observe(ui)[] == RGB(0.3, 0.3, 0.3)
end

@testset "output" begin
    @test isfile(joinpath(dirname(@__FILE__),
        "..", "assets", "npm", "node_modules", "katex", "dist", "katex.min.js"))
    @test isfile(joinpath(dirname(@__FILE__),
        "..", "assets", "npm", "node_modules", "katex", "dist", "katex.min.css"))
    l = Observable("\\sum_{i=1}^{\\infty} e^i")
    a = latex(l)
    @test widgettype(a) == :latex
    @test observe(a)[] == l[]
    l[] == "\\sum_{i=1}^{12} e^i"
    @test observe(a)[] == l[]

    a = alert()
    a("Error!")
    @test a["text"] isa Observable
    @test a["counter"] isa Observable
    @test a["text"][] == "Error!"
    @test a["counter"][] == 1
end
