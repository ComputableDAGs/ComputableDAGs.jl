"""
   GraphProperties

Representation of a [`DAG`](@ref)'s properties.

# Fields:
`.data`: The total data transfer.\\
`.computeEffort`: The total compute effort.\\
`.computeIntensity`: The compute intensity, will always equal `.computeEffort / .data`.\\
`.noNodes`: Number of [`Node`](@ref)s.\\
`.noEdges`: Number of [`Edge`](@ref)s.
"""
const GraphProperties = NamedTuple{
    (:data, :computeEffort, :computeIntensity, :noNodes, :noEdges),
    Tuple{Float64,Float64,Float64,Int,Int},
}
