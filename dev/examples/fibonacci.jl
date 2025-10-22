# ## Fibonacci

# In this example, we want to calculate the n-th Fibonacci number using a DAG representation. The input is a tuple of two numbers, the definition of `fib(0)` and `fib(1)`, to make it not just a constant Fibonacci evaluation.

# ### Model Definition

# To define a model for your problem type, simply define a new struct. No specific type inheritance is necessary. An object of this will later represent a specific problem instance.

using ComputableDAGs

struct Fibonacci
    n::Int
end

# For this example, the n in the model definition is for the `n-th` Fibonacci number we want to calculate.

# ### Task definitions

# For Fibonacci, we only need one type of compute task: An addition of two numbers to yield the next number. Compute tasks can be defined using the [`@compute_task`](@ref) macro. We provide the name, the compute effort, and the function to call.

@compute_task Add 1 (+)

# ### Input definitions

# For this model, we will need two different input nodes, `fib(0)` and `fib(1)`, to base the rest of the DAG on. Input nodes are distinguished by name.

# To extract the correct numbers from the CDAG input, we have to provide an expression that does so by implementing [`ComputableDAGs.input_expr`](@ref), given the entry node's name. We'll use `"fib(0)"` and `"fib(1)"` as names.

function ComputableDAGs.input_expr(::Fibonacci, name::String, input_symbol::Symbol)
    return if (name == "fib(0)")
        :($input_symbol[1])
    elseif (name == "fib(1)")
        :($input_symbol[2])
    else
        assert(false)
    end
end

# For type inference when generating the function later, we also need to define the expected input type for our problem instance. As mentioned above, this is a `Tuple{Int, Int}` in our case.

ComputableDAGs.input_type(::Fibonacci) = Tuple{Int, Int}

# ### Building the DAG

# To be able to compute a DAG we first have to build it. This is done by implementing [`ComputableDAGs.graph`](@ref) for our problem instance and returning a DAG. We can use several macros to make this simple: [`@assemble_dag`](@ref), [`@add_call`](@ref), [`@add_entry`](@ref).

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

# In short, `@assemble_dag begin ... end` creates a scope in which [`@add_entry`](@ref) can add entry nodes and [`@add_call`](@ref) can add compute nodes. The whole expression then returns the DAG created in the scope.
# [`@add_entry`](@ref) takes two arguments: a node name, which is later passed to the [`input_expr`](@ref ComputableDAGs.input_expr) implementation we defined above, and the expected data size of the output. This doesn't have to be in bytes, but it should be proportional across all data sizes in the DAG.
# [`@add_call`](@ref) takes the compute task that the compute node should execute. In our case, this is the `Add` task defined earlier. Note that this has to be an instance of the task object, not just the type name. The second argument is the expected output data size, as with the entry nodes. Finally, a list of all the input nodes to the compute task follows.

# The actual logic follows that of the Fibonacci sequence:
# ```math
# a_i = a_{i-1} + a_{i-2}
# ```

# To achieve this, in each iteration of the for-loop, `n3` is created as a new node representing the addition of `n1` and `n2`. Then, the variables are swapped such that `n1` represents the next $a_{i-2}$ and `n2` is the next $a_{i-1}$.

# ### Trying it out

# This is all we have to do to define the problem. Now we can use ComputableDAGs.jl to generate a callable function from this definition:

fib = Fibonacci(10)
dag = graph(fib)
f10 = compute_function(dag, fib, cpu_st(), @__MODULE__);

# This function is now callable immediately:

using Test
@test f10((0, 1)) == 34
@test f10((5, 10)) == 445

#md # ## Jupyter notebook

#md # You can download this file as a jupyter notebook [here](fibonacci.ipynb).
