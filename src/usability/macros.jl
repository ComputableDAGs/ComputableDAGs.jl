"""
    @assemble_dag begin ... end

Takes a code block within which the [`@add_call`](@ref) and [`@add_entry`](@ref) macros can be used. It returns the fully assembled DAG.

This macro can not be used recursively.

## Example:
```julia
dag = @assemble_dag begin
    entry_node = @add_entry "input" 64 # name and data size
    compute1 = @add_call Compute1() 32 entry_node # task, output data size, and inputs
    compute2 = @add_call Compute2() 16 compute1 entry_node # task, output data size, and inputs of the second compute node
    # since no more nodes are added, compute2 is automatically the final result of the dag
end
```
"""
macro assemble_dag(block)
    return quote
        begin
            # TODO add recursion guard
            try
                __CURRENT_DAG__[] = DAG()
                $(esc(block))
            catch e
                @error e
            end

            __CURRENT_DAG__[]
        end
    end
end

"""
    @add_call task data varargs

!!! note
    Only valid within a [`@assemble_dag`](@ref) block.

Takes an `AbstractComputeTask` and arguments in the form of [`ComputeTaskNode`](@ref)s, creating a node in the dag currently being assembled (see [`@assemble_dag`](@ref)). The resulting node is returned to be used in subsequent [`@add_call`](@ref)s.

## Arguments
- `task`: The actual ComputeTask object to use.
- `data`: The data size of the result.
- `varargs...`: Any number of data nodes to use as input. They will be given to the task's function in the same order. Each argument can also be an iterable (vector, tuple, etc.) of nodes, which are automatically unpacked and added individually.
"""
macro add_call(task, data, varargs...)
    # assume that varargs are data task nodes, return a new data task node
    @debug "got $task with $(length(varargs)) arguments"

    exprs = Expr[]
    push!(exprs, :(c = 0))
    # edges from inputs
    for arg in varargs
        if (arg isa Expr) # assume this is a vector, tuple, or other iterable thing
            push!(
                exprs, quote
                    for arg in $(esc(arg))
                        c += 1
                        insert_edge!.(__CURRENT_DAG__[], arg, compute_node, c)
                    end
                end
            )
        else
            push!(exprs, :(c += 1))
            push!(exprs, :(insert_edge!(__CURRENT_DAG__[], $(esc(arg)), compute_node, c)))
        end
    end

    expr = Expr(
        :block,
        quote
            compute_node = insert_node!(__CURRENT_DAG__[], $(esc(:($task))))
        end,
        exprs...,
        quote
            data_node = insert_node!(__CURRENT_DAG__[], DataTask($(esc(data)))) # TODO: probably unnecessary to give the data tasks their data size, they should figure that out themselves
            insert_edge!(__CURRENT_DAG__[], compute_node, data_node)
            data_node
        end
    )

    return expr
end

"""
    @add_entry name data

!!! note
    Only valid within a [`@assemble_dag`](@ref) block.

Add an entry node to the DAG currently being assembled, with the given name and expected resulting data size.
An [`input_expr`](@ref) must be defined for the given name.
"""
macro add_entry(name, data)
    @debug "adding entry node with name $name and data $data"
    return quote
        insert_node!(__CURRENT_DAG__[], DataTask($(esc(data))), $(esc(name)))
    end
end

"""
    @compute_task task effort [function]

Defines a compute task to be later added in compute nodes to a DAG, for example using [`@add_call`](@ref).
Necessary arguments are the task name and its expected compute effort. Optionally, a function can be provided, making up the task's
[`compute`](@ref) function. For example, to add a task type that simply adds two child nodes together:
```julia
@compute_task Add 1 (+)
```
In some cases, the function to call might be more complex or need more specific information about the task type, like its type parametrization.
For this reason, it is also possible to define the compute function for a compute task manually instead:
```julia
@compute_task ComplexTask{T1, T2} 50
ComputableDAGs.compute(::ComplexTask{Int, Float32}, v1, v2) = ...
ComputableDAGs.compute(::ComplexTask{String, Float32}, v1, v2) = ...
```
"""
macro compute_task(comp_task, compute_effort, compute_function)
    local name::Symbol
    if (comp_task isa Symbol)
        name = comp_task
    elseif (comp_task isa Expr && comp_task.head == :curly)
        name = comp_task.args[1]
    else
        error("failed parsing compute task $comp_task")
    end
    return quote
        struct $(comp_task) <: AbstractComputeTask end
        ComputableDAGs.compute_effort(::$(esc(name))) = $(esc(compute_effort))
        ComputableDAGs.compute(::$(esc(name)), varargs...) = ($(esc(compute_function)))(varargs...)
        $(esc(name))
    end
end
macro compute_task(comp_task, compute_effort)
    local name::Symbol
    if (comp_task isa Symbol)
        name = comp_task
    elseif (comp_task isa Expr && comp_task.head == :curly)
        name = comp_task.args[1]
    else
        error("failed parsing compute task $comp_task")
    end
    return quote
        struct $(comp_task) <: AbstractComputeTask end
        ComputableDAGs.compute_effort(::$(esc(name))) = $(esc(compute_effort))
        $(esc(name))
    end
end
