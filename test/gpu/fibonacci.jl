using KernelAbstractions

function fib_gt(n::Int, n0::Number, n1::Number)
    return if n == 1
        n0
    elseif n == 2
        n1
    else
        fib_gt(n - 1, n0, n1) + fib_gt(n - 2, n0, n1)
    end
end

# define a function barrier to test executability without world age problems
function barrier(fib::Fibonacci, backend::Backend, type::Type, size::Int)
    dag = graph(fib)
    k = kernel(dag, fib, @__MODULE__)

    rand_inputs = [(rand(type), rand(type)) for i in 1:size]

    in = allocate(backend, Tuple{type, type}, size)
    out = allocate(backend, type, size)

    copyto!(in, rand_inputs)

    k(backend, 32)(in, out; ndrange = length(in))

    gt_out = fib_gt.(fib.n, getindex.(rand_inputs, 1), getindex.(rand_inputs, 2))
    return @test count(isapprox.(out, gt_out)) == size
end

for stp in SETUPS
    @testset "$backend $vec_type $el_type" for (backend, vec_type, el_type) in combinations(stp)
        @testset "Fibonacci test N = $N" for N in [3, 10, 20]
            barrier(Fibonacci(N), backend, el_type, 16)
        end
    end
end
