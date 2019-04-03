struct MyTheme<:InteractBase.WidgetTheme; end
InteractBase.registertheme!(:mytheme, MyTheme())

@testset "theme" begin
    @test gettheme() == NativeHTML()
    settheme!(MyTheme())
    @test gettheme() == MyTheme()
    resettheme!()
    @test gettheme() == NativeHTML()
    settheme!("mytheme")
    @test gettheme() == MyTheme()
    settheme!(:nativehtml)
    @test gettheme() == NativeHTML()
    @test availablethemes() == [:mytheme, :nativehtml]
    @test_throws ErrorException settheme!("not a theme")
end
