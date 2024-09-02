"""
    in(node::Node, graph::DAG)

Check whether the node is part of the graph.
"""
in(node::Node, graph::DAG) = node in graph.nodes

"""
    in(edge::Edge, graph::DAG)

Check whether the edge is part of the graph.
"""
function in(edge::Edge, graph::DAG)
    n1 = edge.edge[1]
    n2 = edge.edge[2]
    if !(n1 in graph) || !(n2 in graph)
        return false
    end

    return n1 in getindex.(children(n2), 1)
end
