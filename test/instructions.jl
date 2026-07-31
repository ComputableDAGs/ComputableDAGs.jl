using ComputableDAGs
using UUIDs

using ComputableDAGs: FunctionCall, ExprAssignment, SendInstruction, RecvInstruction, CPU
using ComputableDAGs: access_expr, lower_to_expr, to_var_name
using ComputableDAGs: DEVICE_MANAGER_SYM

foo() = nothing
bar(x) = x

# use - as non-commutative operation to check order of arguments
baz(x, y) = x + y, x - y

CPU_T = CPU(1, true)

@testset "Instructions" begin
    @testset "Function Calls" begin
        @testset "FC (nothing function, positive)" begin
            fc = FunctionCall(foo, (), Symbol[], [:x])
            @test access_expr(fc.return_symbols) == :x
            expr = lower_to_expr(fc, CPU_T)
            @test expr == Expr(:(=), :x, Expr(:call, foo))
            @test isnothing(eval(expr))
        end

        @testset "FC (nothing function, method error)" begin
            fc = FunctionCall(foo, (1,), Symbol[], [:x])
            @test access_expr(fc.return_symbols) == :x
            expr = lower_to_expr(fc, CPU_T)
            @test expr == Expr(:(=), :x, Expr(:call, foo, 1))
            @test_throws MethodError eval(expr)
        end

        @testset "FC (identity function, undef var error)" begin
            fc = FunctionCall(bar, (), [:y], [:x])
            @test access_expr(fc.return_symbols) == :x
            expr = lower_to_expr(fc, CPU_T)
            @test expr == Expr(:(=), :x, Expr(:call, bar, :y))
            @test_throws UndefVarError eval(expr)
        end

        @testset "FC (identity function, positive, value argument)" begin
            fc = FunctionCall(bar, (5,), Symbol[], [:x])
            @test access_expr(fc.return_symbols) == :x
            expr = lower_to_expr(fc, CPU_T)
            @test expr == Expr(:(=), :x, Expr(:call, bar, 5))
            eval(expr)
            @test x == 5
        end

        @testset "FC (identity function, positive, parameter)" begin
            fc = FunctionCall(bar, (), [:y], [:x])
            @test access_expr(fc.return_symbols) == :x
            expr = lower_to_expr(fc, CPU_T)
            @test expr == Expr(:(=), :x, Expr(:call, bar, :y))

            # small workaround to not have to assign y globally
            eval(Expr(:block, Expr(:(=), :y, 5), expr))
            @test x == 5
        end

        @testset "FC (multi function, positive, parameters)" begin
            fc = FunctionCall(baz, (), [:y1, :y2], [:x1, :x2])
            @test access_expr(fc.return_symbols) == Expr(:tuple, :x1, :x2)
            expr = lower_to_expr(fc, CPU_T)
            @test expr == Expr(:(=), Expr(:tuple, :x1, :x2), Expr(:call, baz, :y1, :y2))

            eval(
                Expr(
                    :block,
                    Expr(:(=), :y1, 5),
                    Expr(:(=), :y2, 6),
                    expr
                )
            )
            @test (x1, x2) == baz(5, 6)
        end

        @testset "FC (multi function, positive, value parameters)" begin
            fc = FunctionCall(baz, (5, 6), Symbol[], [:x1, :x2])
            @test access_expr(fc.return_symbols) == Expr(:tuple, :x1, :x2)
            expr = lower_to_expr(fc, CPU_T)
            @test expr == Expr(:(=), Expr(:tuple, :x1, :x2), Expr(:call, baz, 5, 6))

            eval(expr)
            @test (x1, x2) == baz(5, 6)
        end

        @testset "FC (multi function, positive, mixed parameters)" begin
            fc = FunctionCall(baz, (5,), [:y], [:x1, :x2])
            @test access_expr(fc.return_symbols) == Expr(:tuple, :x1, :x2)
            expr = lower_to_expr(fc, CPU_T)
            @test expr == Expr(:(=), Expr(:tuple, :x1, :x2), Expr(:call, baz, 5, :y))

            eval(
                Expr(
                    :block,
                    Expr(:(=), :y, 6),
                    expr
                )
            )
            @test (x1, x2) == baz(5, 6)
        end
    end

    @testset "Expr Assignment" begin
        @testset "EA (basic assignment)" begin
            # necessary to pack the symbol in a block
            # because a smybol is not an expression
            ea = ExprAssignment(Expr(:block, :y), :x)
            expr = lower_to_expr(ea, CPU_T)
            @test expr == Expr(:(=), :x, Expr(:block, :y))

            eval(
                Expr(
                    :block,
                    Expr(:(=), :y, 1),
                    expr
                )
            )

            @test x == 1
        end

        @testset "EA (tuple extraction)" for v in 1:3
            ea = ExprAssignment(Expr(:call, getindex, :y, v), :x)
            expr = lower_to_expr(ea, CPU_T)
            @test expr == Expr(:(=), :x, Expr(:call, getindex, :y, v))

            eval(
                Expr(
                    :block,
                    Expr(:(=), :y, Expr(:tuple, 1, 2, 3)),
                    expr
                )
            )

            @test x == v
        end
    end

    @testset "Send/Recv Instructions" begin
        cpu1 = CPU(1, true)
        cpu2 = CPU(1, false)

        id1 = UUIDs.uuid1()
        id2 = UUIDs.uuid1()

        si1 = SendInstruction(cpu2, true, id1)
        si2 = SendInstruction(cpu1, true, id2)

        # cannot directly compare expressions for equality
        @test string(lower_to_expr(si1, cpu1)) ==
            string(:($(ComputableDAGs.send)($DEVICE_MANAGER_SYM, Val{true}(), $(cpu2.id), $(Symbol(to_var_name(id1))), $id1)))
        @test string(lower_to_expr(si2, cpu2)) ==
            string(:($(ComputableDAGs.send)($DEVICE_MANAGER_SYM, Val{true}(), $(cpu1.id), $(Symbol(to_var_name(id2))), $id2)))

        ri1 = RecvInstruction(cpu2, true, id1, Int)
        ri2 = RecvInstruction(cpu1, true, id2, Float64)

        @test string(lower_to_expr(ri1, cpu1)) ==
            string(:($(Symbol(to_var_name(id1))) = $(ComputableDAGs.get)($DEVICE_MANAGER_SYM, Val{true}(), $(cpu2.id), $id1, $(Int))))
        @test string(lower_to_expr(ri2, cpu2)) ==
            string(:($(Symbol(to_var_name(id2))) = $(ComputableDAGs.get)($DEVICE_MANAGER_SYM, Val{true}(), $(cpu1.id), $id2, $(Float64))))
    end
end
