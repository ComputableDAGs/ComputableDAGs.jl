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
    add_call

Takes an `AbstractComputeTask` and arguments in the form of [`ComputeTaskNode`](@ref)s, creating a node in the dag currently being assembled (see [`assemble_dag`](@ref)). The resulting node is returned to be used in subsequent [`add_call`](@ref)s.

## Arguments
- `task`: The actual ComputeTask object to use.
- `data`: The data size of the result.
- `varargs...`: Any number of data nodes to use as input. They will be given to the task's function in the same order.
"""
macro add_call(task, data, varargs...)
    # assume that varargs are data task nodes, return a new data task node
    @debug "got $task with $(length(varargs)) arguments"

    exprs = Expr[]
    c = 0
    # edges from inputs
    for arg in varargs
        c += 1
        push!(
            exprs, quote
                insert_edge!(__CURRENT_DAG__[], $(esc(arg)), compute_node, $c)
            end

        )
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
    add_entry
"""
macro add_entry(name, data)
    @debug "adding entry node with name $name and data $data"
    return quote
        insert_node!(__CURRENT_DAG__[], DataTask($(esc(data))), $(esc(name)))
    end
end

macro compute_task(comp_task, compute_effort, children, compute_function)
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
        ComputableDAGs.children(::$(esc(name))) = $(esc(children))
        ComputableDAGs.compute(::$(esc(name)), varargs...) = $(esc(compute_function))(varargs...)
        $(esc(name))
    end
end

macro compute_task(comp_task, compute_effort, children)
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
        ComputableDAGs.children(::$(esc(name))) = $(esc(children))
        $(esc(name))
    end
end
