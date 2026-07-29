"""
    ComputableDAG()

Construct and return an empty [`ComputableDAG`](@ref).
"""
function ComputableDAG()
    return ComputableDAG(
        Dict{UUID, Node}()
    )
end
