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
