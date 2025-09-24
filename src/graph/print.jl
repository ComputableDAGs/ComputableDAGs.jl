"""
    show_nodes(io::IO, dag::DAG)

Print a graph's nodes. Should only be used for small graphs as it prints every node in a list.
"""
function show_nodes(io::IO, dag::DAG)
    print(io, "[")
    first = true
    for (id, node) in dag.nodes
        if first
            first = false
        else
            print(io, ", ")
        end
        print(io, node)
    end
    return print(io, "]")
end

"""
    show(io::IO, dag::DAG)

Print the given graph to io. If there are too many nodes it will print only a summary of them.
"""
function Base.show(io::IO, dag::DAG)
    apply_all!(dag)
    println(io, "Graph:")
    print(io, "  Nodes: ")

    nodeDict = Dict{Type, Int64}()
    number_of_edges = 0
    for (id, node) in dag.nodes
        if haskey(nodeDict, typeof(task(node)))
            nodeDict[typeof(task(node))] = nodeDict[typeof(task(node))] + 1
        else
            nodeDict[typeof(task(node))] = 1
        end
        number_of_edges += length(node.parents)
    end

    if length(dag.nodes) <= 20
        show_nodes(io, dag)
    else
        print(io, "Total: ", length(dag.nodes), ", ")
        first = true
        i = 0
        for (type, number) in zip(keys(nodeDict), values(nodeDict))
            i += 1
            if first
                first = false
            else
                print(io, ", ")
            end
            if (i % 3 == 0)
                print(io, "\n         ")
            end
            print(io, type, ": ", number)
        end
    end
    println(io)
    println(io, "  Edges: ", number_of_edges)
    properties = get_properties(dag)
    println(io, "  Total Compute Effort: ", properties.compute_effort)
    println(io, "  Total Data Transfer: ", properties.data)
    return println(io, "  Total Compute Intensity: ", properties.compute_intensity)
end
