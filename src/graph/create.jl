"""
    ComputableDAG()
    CDAG()

Construct and return an empty [`ComputableDAG`](@ref). Can also use the alias CDAG().
"""
function ComputableDAG()
    return ComputableDAG(
        Dict{UUID, Node}()
    )
end
