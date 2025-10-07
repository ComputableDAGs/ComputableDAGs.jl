using SafeTestsets

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
