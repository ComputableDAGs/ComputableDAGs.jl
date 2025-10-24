"""
   GraphProperties()

Create an empty [`GraphProperties`](@ref) object.
"""
function GraphProperties()
    return (
        data = 0.0,
        compute_effort = 0.0,
        compute_intensity = 0.0,
        number_of_nodes = 0,
        number_of_edges = 0,
    )::GraphProperties
end

@inline function _props(
        node::DataTaskNode{TaskType}
    )::Tuple{Float64, Float64, Int64} where {TaskType <: AbstractDataTask}
    return (data(task(node)) * length(node.parents), 0.0, length(node.parents))
end
@inline function _props(
        node::ComputeTaskNode{TaskType}
    )::Tuple{Float64, Float64, Int64} where {TaskType <: AbstractComputeTask}
    return (0.0, compute_effort(task(node)), length(node.parents))
end

"""
   GraphProperties(dag::DAG)

Calculate the graph's properties and return the constructed [`GraphProperties`](@ref) object.
"""
function GraphProperties(dag::DAG)
    # make sure the graph is fully generated
    apply_all!(dag)

    d = 0.0
    ce = 0.0
    ed = 0
    for (id, node) in dag.nodes
        props = _props(node)
        d += props[1]
        ce += props[2]
        ed += props[3]
    end

    return (
        data = d,
        compute_effort = ce,
        compute_intensity = (d == 0) ? 0.0 : ce / d,
        number_of_nodes = length(dag.nodes),
        number_of_edges = ed,
    )::GraphProperties
end

"""
   GraphProperties(diff::Diff)

Create the graph properties difference from a given [`Diff`](@ref).
The graph's properties after applying the [`Diff`](@ref) will be `properties(graph) + GraphProperties(diff)`.
For reverting a diff, it's `properties(graph) - GraphProperties(diff)`.
"""
function GraphProperties(diff::Diff)
    ce =
        reduce(+, compute_effort(task(n)) for n in diff.added_nodes; init = 0.0) -
        reduce(+, compute_effort(task(n)) for n in diff.removed_nodes; init = 0.0)

    d =
        reduce(+, data(task(n)) for n in diff.added_nodes; init = 0.0) -
        reduce(+, data(task(n)) for n in diff.removed_nodes; init = 0.0)

    return (
        data = d,
        compute_effort = ce,
        compute_intensity = (d == 0) ? 0.0 : ce / d,
        number_of_nodes = length(diff.added_nodes) - length(diff.removed_nodes),
        number_of_edges = length(diff.added_edges) - length(diff.removed_edges),
    )::GraphProperties
end
