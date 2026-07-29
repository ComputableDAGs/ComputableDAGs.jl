"""
    ComputableDAGs

A module containing tools to represent computations as DAGs.
"""
module ComputableDAGs

using UUIDs

export ComputableDAG, CDAG
export @compute_task, @assemble_cdag

include("utility.jl")

include("tasks/types.jl")
include("nodes/types.jl")
include("computable_dags/types.jl")
include("devices/types.jl")
include("instructions/types.jl")

include("tasks/properties.jl")
include("tasks/macros.jl")

include("nodes/create.jl")
include("nodes/print.jl")
include("nodes/properties.jl")

include("computable_dags/create.jl")
include("computable_dags/macros.jl")
include("computable_dags/properties.jl")

include("instructions/utils.jl")
include("instructions/code_gen.jl")

end # module ComputableDAGs
