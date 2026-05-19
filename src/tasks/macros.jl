"""
    @compute_task task [function]

Defines a [`compute task`](@ref AbstractComputeTask) type to be later used in
[`nodes`](@ref Node) for a [`ComputableDAG`](@ref), for example using
[`@add_call`]#(@ref). Necessary arguments are the task name and its expected
compute effort. Optionally, a function can be provided, making up the task's
[`compute`](@ref) function. For example, to add a task type that simply adds
two child nodes together:
```julia
@compute_task Add (+)
```
In some cases, the function to call might be more complex or need more
specific information about the task type, like its type parametrization. For
this reason, it is also possible to define the compute function for a compute
task manually instead:
```julia
@compute_task ComplexTask{T1, T2}
ComputableDAGs.compute(::ComplexTask{Int, Float32}, v1, v2) = ...
ComputableDAGs.compute(::ComplexTask{String, Float32}, v1, v2) = ...
```
"""
macro compute_task(comp_task, compute_function)
    local name::Symbol
    if (comp_task isa Symbol)
        name = comp_task
    elseif (comp_task isa Expr && comp_task.head == :curly)
        name = comp_task.args[1]
    else
        error("failed parsing compute task $comp_task")
    end
    return quote
        struct $(comp_task) <: ComputableDAGs.AbstractComputeTask end
        ComputableDAGs.compute(::$(esc(name)), varargs...) = ($(esc(compute_function)))(varargs...)
        $(esc(name))
    end
end
macro compute_task(comp_task)
    local name::Symbol
    if (comp_task isa Symbol)
        name = comp_task
    elseif (comp_task isa Expr && comp_task.head == :curly)
        name = comp_task.args[1]
    else
        error("failed parsing compute task $comp_task")
    end
    return quote
        struct $(comp_task) <: ComputableDAGs.AbstractComputeTask end
        $(esc(name))
    end
end
