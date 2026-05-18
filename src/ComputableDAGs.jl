"""
    ComputableDAGs

A module containing tools to represent computations as DAGs.
"""
module ComputableDAGs

using UUIDs

export ComputableDAG, CDAG

include("utility.jl")

include("tasks/type.jl")
include("nodes/type.jl")
include("graph/type.jl")

include("tasks/properties.jl")

include("nodes/create.jl")
include("nodes/print.jl")
include("nodes/properties.jl")

include("graph/create.jl")
include("graph/properties.jl")

end # module ComputableDAGs
