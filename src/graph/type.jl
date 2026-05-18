"""
    ComputableDAG
    CDAG

The representation of the graph as a set of [`Node`](@ref)s, connected by hyperedges representing data dependencies, and connected by normal edges to represent scheduling order.

See also: [`nodes`](@ref).
"""
struct ComputableDAG
    # TODO: could this be made type stable by adding a layer looking at distinct node types?
    nodes::Dict{UUID, Node}

    # TODO: add operation stack, diff, etc. back in
end

CDAG = ComputableDAG
