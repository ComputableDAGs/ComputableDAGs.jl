"""
   GraphProperties()

Create an empty [`GraphProperties`](@ref) object.
"""
function GraphProperties()
    return (
        data=0.0, computeEffort=0.0, computeIntensity=0.0, noNodes=0, noEdges=0
    )::GraphProperties
end

@inline function _props(
    node::DataTaskNode{TaskType}
)::Tuple{Float64,Float64,Int64} where {TaskType<:AbstractDataTask}
    return (data(task(node)) * length(parents(node)), 0.0, length(parents(node)))
end
@inline function _props(
    node::ComputeTaskNode{TaskType}
)::Tuple{Float64,Float64,Int64} where {TaskType<:AbstractComputeTask}
    return (0.0, compute_effort(task(node)), length(parents(node)))
end

"""
   GraphProperties(graph::DAG)

Calculate the graph's properties and return the constructed [`GraphProperties`](@ref) object.
"""
function GraphProperties(graph::DAG)
    # make sure the graph is fully generated
    apply_all!(graph)

    d = 0.0
    ce = 0.0
    ed = 0
    for node in graph.nodes
        props = _props(node)
        d += props[1]
        ce += props[2]
        ed += props[3]
    end

    return (
        data=d,
        computeEffort=ce,
        computeIntensity=(d == 0) ? 0.0 : ce / d,
        noNodes=length(graph.nodes),
        noEdges=ed,
    )::GraphProperties
end

"""
   GraphProperties(diff::Diff)

Create the graph properties difference from a given [`Diff`](@ref).
The graph's properties after applying the [`Diff`](@ref) will be `get_properties(graph) + GraphProperties(diff)`.
For reverting a diff, it's `get_properties(graph) - GraphProperties(diff)`.
"""
function GraphProperties(diff::Diff)
    ce =
        reduce(+, compute_effort(task(n)) for n in diff.addedNodes; init=0.0) -
        reduce(+, compute_effort(task(n)) for n in diff.removedNodes; init=0.0)

    d =
        reduce(+, data(task(n)) for n in diff.addedNodes; init=0.0) -
        reduce(+, data(task(n)) for n in diff.removedNodes; init=0.0)

    return (
        data=d,
        computeEffort=ce,
        computeIntensity=(d == 0) ? 0.0 : ce / d,
        noNodes=length(diff.addedNodes) - length(diff.removedNodes),
        noEdges=length(diff.addedEdges) - length(diff.removedEdges),
    )::GraphProperties
end
