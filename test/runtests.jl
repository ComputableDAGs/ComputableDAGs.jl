using SafeTestsets

include("gpu/utility.jl")

# check if we run CPU tests (yes by default)
cpu_tests = _is_test_platform_active(["TEST_CPU"], true)

if cpu_tests
    @safetestset "Utility" begin
        include("utility.jl")
    end

    @safetestset "Tasks" begin
        include("tasks.jl")
    end

    @safetestset "Nodes" begin
        include("nodes.jl")
    end

    @safetestset "ComputableDAG" begin
        include("computable_dags.jl")
    end

    @safetestset "Function Calls" begin
        include("instructions.jl")
    end

    @safetestset "Device Managers" begin
        include("device_managers.jl")
    end

    @safetestset "Machines" begin
        include("machines.jl")
    end

    @safetestset "Tapes" begin
        include("tapes.jl")
    end
else
    @info "Skipping CPU tests"
end

begin
    @time @safetestset "GPU testing" begin
        include("gpu/runtests.jl")
    end
end
