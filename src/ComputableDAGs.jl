"""
    ComputableDAGs

A module containing tools to represent computations as DAGs.
"""
module ComputableDAGs

using UUIDs

export ComputableDAG, CDAG
export @compute_task, @assemble_cdag

include("utility.jl")

include("tasks/type.jl")
include("nodes/type.jl")
include("computable_dag/type.jl")
include("function_call/type.jl")

include("tasks/properties.jl")
include("tasks/macros.jl")

include("nodes/create.jl")
include("nodes/print.jl")
include("nodes/properties.jl")

include("computable_dag/create.jl")
include("computable_dag/macros.jl")
include("computable_dag/properties.jl")

include("function_call/utils.jl")
include("function_call/code_gen.jl")

end # module ComputableDAGs
