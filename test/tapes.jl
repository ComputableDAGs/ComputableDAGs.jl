using ComputableDAGs
using UUIDs
using Random

using ComputableDAGs: Tape, TapeRack, lower, tape_function, to_var_name
using ComputableDAGs: AbstractInstruction, ExprAssignment, FunctionCall,
    SendInstruction, RecvInstruction, CPU, Cluster, Machine, ZMQDeviceManager

ComputableDAGs.init(@__MODULE__)

RNG = Random.Xoshiro(654)

square(x) = x * x
foo(x, y) = y - x
bar(x, y, z) = (x * y, x * z)

TEST_CPU = CPU(1, true)
TEST_CLUSTER = Cluster{ZMQDeviceManager}([Machine([TEST_CPU])])

TESTING_TAPE = Tape(
    [ExprAssignment(Expr(:call, getindex, :input, 1), :x)],
    AbstractInstruction[
        FunctionCall(square, (2,), Symbol[], [:t_1]),          # t_1 = square(2)
        FunctionCall(foo, (), [:t_1, :x], [:t_2]),             # t_2 = foo(t_1, x)
        FunctionCall(bar, (2,), [:t_1, :t_2], [:t_3, :t_4]),   # (t_3, t_4) = bar(2, t_1, t_2)
        FunctionCall(foo, (), [:t_3, :t_4], [:output]),        # output = foo(t_3, t_4)
    ],
    :output,
    TEST_CPU
)

@testset "Construction and Execution" begin
    func = tape_function(TESTING_TAPE, TEST_CLUSTER, @__MODULE__)
    @test -6 == func(5)
end

@noinline function function_barrier(tape, cluster, input)
    func = tape_function(tape, cluster, @__MODULE__)
    return func(input)
end

@testset "Test World Age Problems" begin
    @test -14 == function_barrier(TESTING_TAPE, TEST_CLUSTER, 1)
end

function f1(x)
    return 2 * x
end

function f2(x, y)
    return x + y
end

function f3(x, y, z)
    return x * y + z
end

@testset "Multiple Device Test" begin
    cpu0 = CPU(1, false)
    cpu1 = CPU(1, false)
    cpu2 = CPU(1, true)

    machine = Machine([cpu0, cpu1, cpu2])
    cluster = Cluster{ZMQDeviceManager}([machine])

    data_ids = Dict{Int, UUID}()
    data_syms = Dict{Int, Symbol}()

    for i in 0:8
        data_ids[i] = UUIDs.uuid1()
        data_syms[i] = Symbol(to_var_name(data_ids[i]))
    end

    tape0 = Tape(
        ExprAssignment[],
        AbstractInstruction[
            RecvInstruction(cpu2, true, data_ids[0], Int),
            RecvInstruction(cpu1, true, data_ids[1], Int),
            FunctionCall(f2, (), [data_syms[0], data_syms[1]], [data_syms[2]]),
            SendInstruction(cpu1, true, data_ids[2]),
            FunctionCall(f1, (), [data_syms[2]], [data_syms[5]]),
            SendInstruction(cpu1, true, data_ids[5]),
        ],
        :output,
        cpu0
    )
    tape1 = Tape(
        ExprAssignment[],
        AbstractInstruction[
            RecvInstruction(cpu2, true, data_ids[0], Int),
            FunctionCall(f1, (), [data_syms[0]], [data_syms[1]]),
            SendInstruction(cpu0, true, data_ids[1]),
            SendInstruction(cpu2, true, data_ids[1]),
            FunctionCall(f1, (), [data_syms[1]], [data_syms[3]]),
            RecvInstruction(cpu0, true, data_ids[2], Int),
            FunctionCall(f2, (), [data_syms[2], data_syms[3]], [data_syms[6]]),
            RecvInstruction(cpu0, true, data_ids[5], Int),
            RecvInstruction(cpu2, true, data_ids[7], Int),
            FunctionCall(f3, (), [data_syms[5], data_syms[6], data_syms[7]], [data_syms[8]]),
            SendInstruction(cpu2, true, data_ids[8]),
        ],
        :output, # unused since this is not the entry device
        cpu1
    )
    tape2 = Tape(
        ExprAssignment[
            ExprAssignment(Expr(:call, getindex, :input, 1), :data),
        ],
        AbstractInstruction[
            FunctionCall(f1, (), [:data], [data_syms[0]]),
            SendInstruction(cpu1, true, data_ids[0]),
            SendInstruction(cpu0, true, data_ids[0]),
            RecvInstruction(cpu1, true, data_ids[1], Int),
            FunctionCall(f1, (), [data_syms[1]], [data_syms[4]]),
            FunctionCall(f1, (), [data_syms[4]], [data_syms[7]]),
            SendInstruction(cpu1, true, data_ids[7]),
            RecvInstruction(cpu1, true, data_ids[8], Int),
            FunctionCall(identity, (), [data_syms[8]], [:output]),
        ],
        :output,
        cpu2
    )

    tape0_func = tape_function(tape0, cluster, @__MODULE__)
    tape1_func = tape_function(tape1, cluster, @__MODULE__)
    tape2_func = tape_function(tape2, cluster, @__MODULE__)

    t0_task = Threads.@spawn tape0_func()
    t1_task = Threads.@spawn tape1_func()
    t2_task = Threads.@spawn tape2_func((1,))

    @test isnothing(fetch(t0_task))
    @test isnothing(fetch(t1_task))
    @test fetch(t2_task) == 184
end
