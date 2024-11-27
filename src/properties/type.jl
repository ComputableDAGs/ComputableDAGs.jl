"""
   GraphProperties

Representation of a [`DAG`](@ref)'s properties.

# Fields:
`.data`: The total data transfer.\\
`.compute_effort`: The total compute effort.\\
`.compute_intensity`: The compute intensity, will always equal `.compute_effort / .data`.\\
`.number_of_nodes`: Number of [`Node`](@ref)s.\\
`.number_of_edges`: Number of [`Edge`](@ref)s.
"""
const GraphProperties = NamedTuple{
    (:data, :compute_effort, :compute_intensity, :number_of_nodes, :number_of_edges),
    Tuple{Float64,Float64,Float64,Int,Int},
}
