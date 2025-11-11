using ComputableDAGs

struct Fibonacci
    n::Int
end

@compute_task Add 1 (+)

function ComputableDAGs.input_expr(::Fibonacci, name::String, input_symbol::Symbol)
    return if (name == "fib(0)")
        :($input_symbol[1])
    elseif (name == "fib(1)")
        :($input_symbol[2])
    else
        assert(false)
    end
end

ComputableDAGs.input_type(::Fibonacci) = Tuple{Int, Int}

function ComputableDAGs.graph(fib::Fibonacci)
    @assert fib.n >= 2
    return @assemble_dag begin
        n1 = @add_entry "fib(0)" 1
        n2 = @add_entry "fib(1)" 1

        for _ in 3:fib.n
            n3 = @add_call Add() 1 n1 n2
            n1 = n2
            n2 = n3
        end
    end
end
