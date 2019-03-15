struct MyTheme<:InteractBase.WidgetTheme; end

@testset "theme" begin
    @test gettheme() == NativeHTML()
    settheme!(MyTheme())
    @test gettheme() == MyTheme()
    resettheme!()
    @test gettheme() == NativeHTML()
end
