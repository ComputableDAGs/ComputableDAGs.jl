using SafeTestsets

include("utils.jl")

# check if we run CPU tests (yes by default)
cpu_tests = _is_test_platform_active(["TEST_CPU"], true)

if cpu_tests
    @safetestset "Utility Unit Tests                   " begin
        include("unit_tests_utility.jl")
    end

    @safetestset "Graph Properties Unit Test           " begin
        include("unit_tests_properties.jl")
    end

    @safetestset "Estimation                           " begin
        include("estimation.jl")
    end

    @safetestset "Strassen Matrix Multiplication Tests " begin
        include("strassen_test.jl")
    end

    @safetestset "Optimization                         " begin
        include("optimization.jl")
    end
else
    @info "Skipping CPU tests"
end

begin
    @time @safetestset "GPU testing" begin
        include("gpu/runtests.jl")
    end
end
