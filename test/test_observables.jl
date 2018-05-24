@testset "input" begin
    a = InteractBase.input();
    @test observe(a)[] == ""
    a = InteractBase.input(typ = "number");
    @test observe(a)[] == 0
    s = Observable{Any}(12)
    a = InteractBase.input(s, typ = "number");
    @test observe(a)[] == s[]
end

@testset "input widgets" begin
    a = filepicker()
    @test a["filename"][] == ""
    @test a["path"][] == ""
    a["path"][] = "/home/Jack/documents/test.csv"
    @test a["path"][] == observe(a)[] == "/home/Jack/documents/test.csv"

    a = textbox();
    @test observe(a)[] == ""
    s = "asd"
    a = textbox(value = s);
    @test observe(a)[] == "asd"

    a = autocomplete(["aa", "bb", "cc"], value = "a");
    @test observe(a)[] == "a"

    a = button("Press me!", clicks = 12)
    @test observe(a)[] == 12

    a = toggle(label = "Agreed")
    @test observe(a)[] == false
    s = Observable(true)
    a = toggle(s, label = "Agreed")
    @test observe(a)[] == true
end

@testset "ijulia" begin
    @test !InteractBase.isijulia()
end
