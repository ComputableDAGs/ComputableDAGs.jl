"""
    __CURRENT_CDAG__::Ref{ComputableDAG}

The unique current global [`ComputableDAG`](@ref), when assembling it using
the usability macros; this is always an empty object outside of the
[`@assemble_cdag`](@ref) macro.
"""
const __CURRENT_CDAG__::Ref{ComputableDAG} = Ref(ComputableDAG())

"""
    __ASSEMBLE_CDAG_FLAG__

A flag used as a recursion guard in the [`@assemble_cdag`](@ref) macro. Set to
true while inside the macro block.
"""
const __ASSEMBLE_CDAG_FLAG__::Ref{Bool} = Ref(false)

"""
    @assemble_cdag begin ... end

Takes a code block within which the [`@add_call`]#(@ref) and
[`@add_entry`]#(@ref) macros can be used. It returns the fully assembled
[`ComputableDAG`](@ref).

This macro must not be used recursively.

## Example:
```julia
cdag = @assemble_cdag begin
    # create an entry node with a given name
    entry_node = @add_entry "input"
    # create a compute node with the task type and its inputs
    compute1 = @add_call Compute1() entry_node
    # create another compute node with 2 inputs
    compute2 = @add_call Compute2() compute1 entry_node
    # since no more nodes are added, compute2 is automatically the final
    # result of the cdag
end
```
"""
macro assemble_cdag(block)
    return quote
        begin
            # recursion guard
            if __ASSEMBLE_CDAG_FLAG__[]
                throw(ErrorException("cannot use @assemble_cdag recursively"))
            end
            __ASSEMBLE_CDAG_FLAG__[] = true

            try
                __CURRENT_CDAG__[] = ComputableDAG()
                $(esc(block))
            catch e
                # cannot use finally for this because of rethrow
                __ASSEMBLE_CDAG_FLAG__[] = false
                rethrow()
            end

            __ASSEMBLE_CDAG_FLAG__[] = false
            __CURRENT_CDAG__[]
        end
    end
end

"""
    @add_call task varargs

!!! note
    Only valid within a [`@assemble_cdag`](@ref) block.

## Arguments
- `task`: The ComputeTask object to use.
- `varargs...`: Any number of data nodes to use as input. They will be given
    to the task's function in the same order. Each argument can also be an
    iterable (vector, tuple, etc.) of nodes, which are automatically unpacked
    and added individually.
"""
macro add_call(task, varargs...)
    @debug "got $task with $(length(varargs)) arguments"

    # TODO: implement
    return quote
        nothing
    end
end
