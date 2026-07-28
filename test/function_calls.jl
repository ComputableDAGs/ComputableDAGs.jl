using ComputableDAGs

using ComputableDAGs: FunctionCall, access_expr, lower_to_expr

foo() = nothing
bar(x) = x

# use - as non-commutative to check order of arguments
baz(x, y) = x + y, x - y


@testset "Access Expressions" begin
    @testset "FC (nothing function, positive)" begin
        fc = FunctionCall(foo, (), Symbol[], [:x])
        @test access_expr(fc) == :x
        expr = lower_to_expr(fc)
        @test expr == Expr(:(=), :x, Expr(:call, foo))
        @test isnothing(eval(expr))
    end

    @testset "FC (nothing function, method error)" begin
        fc = FunctionCall(foo, (1,), Symbol[], [:x])
        @test access_expr(fc) == :x
        expr = lower_to_expr(fc)
        @test expr == Expr(:(=), :x, Expr(:call, foo, 1))
        @test_throws MethodError eval(expr)
    end

    @testset "FC (identity function, undef var error)" begin
        fc = FunctionCall(bar, (), [:y], [:x])
        @test access_expr(fc) == :x
        expr = lower_to_expr(fc)
        @test expr == Expr(:(=), :x, Expr(:call, bar, :y))
        @test_throws UndefVarError eval(expr)
    end

    @testset "FC (identity function, positive, value argument)" begin
        fc = FunctionCall(bar, (5,), Symbol[], [:x])
        @test access_expr(fc) == :x
        expr = lower_to_expr(fc)
        @test expr == Expr(:(=), :x, Expr(:call, bar, 5))
        eval(expr)
        @test x == 5
    end

    @testset "FC (identity function, positive, parameter)" begin
        fc = FunctionCall(bar, (), [:y], [:x])
        @test access_expr(fc) == :x
        expr = lower_to_expr(fc)
        @test expr == Expr(:(=), :x, Expr(:call, bar, :y))

        # small workaround to not have to assign y globally
        eval(Expr(:block, Expr(:(=), :y, 5), expr))
        @test x == 5
    end

    @testset "FC (multi function, positive, parameters)" begin
        fc = FunctionCall(baz, (), [:y1, :y2], [:x1, :x2])
        @test access_expr(fc) == Expr(:tuple, :x1, :x2)
        expr = lower_to_expr(fc)
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
        @test access_expr(fc) == Expr(:tuple, :x1, :x2)
        expr = lower_to_expr(fc)
        @test expr == Expr(:(=), Expr(:tuple, :x1, :x2), Expr(:call, baz, 5, 6))

        eval(expr)
        @test (x1, x2) == baz(5, 6)
    end

    @testset "FC (multi function, positive, mixed parameters)" begin
        fc = FunctionCall(baz, (5,), [:y], [:x1, :x2])
        @test access_expr(fc) == Expr(:tuple, :x1, :x2)
        expr = lower_to_expr(fc)
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
