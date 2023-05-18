using InteractBase
using Test

@testset "Dialog" begin
    @test InteractBase.opendialog() isa Widget
    @test InteractBase.savedialog() isa Widget
end
