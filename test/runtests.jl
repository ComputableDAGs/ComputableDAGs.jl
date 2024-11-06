using SafeTestsets

@safetestset "Utility Unit Tests                   " begin
    include("unit_tests_utility.jl")
end

@safetestset "Strassen Matrix Multiplication Tests " begin
    include("strassen_test.jl")
end
