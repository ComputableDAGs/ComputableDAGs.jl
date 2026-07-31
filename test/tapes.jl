using ComputableDAGs

using ComputableDAGs: Tape, TapeRack, lower, tape_function
using ComputableDAGs: AbstractInstruction, ExprAssignment, FunctionCall, CPU

ComputableDAGs.init(@__MODULE__)

square(x) = x * x
foo(x, y) = y - x
bar(x, y, z) = (x * y, x * z)

TESTING_TAPE = Tape(
    [ExprAssignment(Expr(:call, getindex, :input, 1), :x)],
    AbstractInstruction[
        FunctionCall(square, (2,), Symbol[], [:t_1]),          # t_1 = square(2)
        FunctionCall(foo, (), [:t_1, :x], [:t_2]),             # t_2 = foo(t_1, x)
        FunctionCall(bar, (2,), [:t_1, :t_2], [:t_3, :t_4]),   # (t_3, t_4) = bar(2, t_1, t_2)
        FunctionCall(foo, (), [:t_3, :t_4], [:output]),        # output = foo(t_3, t_4)
    ],
    :output,
    CPU(1, true)
)

@testset "Construction and Execution" begin
    func = tape_function(TESTING_TAPE, @__MODULE__)
    @test -6 == func(5)
end

@noinline function function_barrier(tape, input)
    func = tape_function(TESTING_TAPE, @__MODULE__)
    return func(input)
end

@testset "Test World Age Problems" begin
    @test -14 == function_barrier(TESTING_TAPE, 1)
end
