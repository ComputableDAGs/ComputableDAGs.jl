"""
    ComputableDAGs

A module containing tools to represent computations as DAGs.
"""
module ComputableDAGs

using UUIDs

export compute

include("tasks/type.jl")
include("nodes/type.jl")

include("tasks/properties.jl")

end # module ComputableDAGs
