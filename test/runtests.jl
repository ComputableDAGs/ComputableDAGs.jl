using SafeTestsets

include("utils.jl")

# check if we run CPU tests (yes by default)
cpu_tests = _is_test_platform_active(["TEST_CPU"], true)

if cpu_tests

    @safetestset "Utility Unit Tests                   " begin
        include("example_test.jl")
    end

else
    @info "Skipping CPU tests"
end

begin
    @time @safetestset "GPU testing" begin
        include("gpu/runtests.jl")
    end
end
