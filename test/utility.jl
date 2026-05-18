using ComputableDAGs
using UUIDs

using ComputableDAGs: NULL_UUID, isnull

@testset "UUIDs" begin
    @test NULL_UUID == UUID(0)
    @test isnull(NULL_UUID)
    @test !isnull(UUIDs.uuid1())
end
