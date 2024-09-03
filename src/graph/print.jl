"""
    show_nodes(io::IO, graph::DAG)

Print a graph's nodes. Should only be used for small graphs as it prints every node in a list.
"""
function show_nodes(io::IO, graph::DAG)
    print(io, "[")
    first = true
    for n in graph.nodes
        if first
            first = false
        else
            print(io, ", ")
        end
        print(io, n)
    end
    return print(io, "]")
end

"""
    show(io::IO, graph::DAG)

Print the given graph to io. If there are too many nodes it will print only a summary of them.
"""
function Base.show(io::IO, graph::DAG)
    apply_all!(graph)
    println(io, "Graph:")
    print(io, "  Nodes: ")

    nodeDict = Dict{Type,Int64}()
    noEdges = 0
    for node in graph.nodes
        if haskey(nodeDict, typeof(task(node)))
            nodeDict[typeof(task(node))] = nodeDict[typeof(task(node))] + 1
        else
            nodeDict[typeof(task(node))] = 1
        end
        noEdges += length(parents(node))
    end

    if length(graph.nodes) <= 20
        show_nodes(io, graph)
    else
        print(io, "Total: ", length(graph.nodes), ", ")
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
    println(io, "  Edges: ", noEdges)
    properties = get_properties(graph)
    println(io, "  Total Compute Effort: ", properties.computeEffort)
    println(io, "  Total Data Transfer: ", properties.data)
    return println(io, "  Total Compute Intensity: ", properties.computeIntensity)
end
