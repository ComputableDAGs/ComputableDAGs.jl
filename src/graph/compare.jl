"""
    in(node::Node, dag::DAG)

Check whether the node is part of the graph.
"""
Base.in(node::Node, dag::DAG) = haskey(dag.nodes, node.id)

"""
    in(edge::Edge, dag::DAG)

Check whether the edge is part of the graph.
"""
function Base.in(edge::Edge, dag::DAG)
    n1 = edge.edge[1]
    n2 = edge.edge[2]
    if !(n1 in dag) || !(n2 in dag)
        return false
    end

    return n1 in getindex.(children(dag, n2), 1)
end
