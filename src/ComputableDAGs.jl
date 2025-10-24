"""
    ComputableDAGs

A module containing tools to represent computations as DAGs.
"""
module ComputableDAGs

using RuntimeGeneratedFunctions
RuntimeGeneratedFunctions.init(@__MODULE__)

# graph types
export DAG, Node, Edge, DataTaskNode
export GraphProperties

# graph functions
export insert_node!, insert_edge!
export is_entry_node, is_exit_node
export compute, data, compute_effort
export properties, exit_node

# graph operation related
export reset_graph!
export operations

# code generation related
export compute_function

# estimator
export GlobalMetricEstimator
export compute_intensity

# optimization
export GreedyOptimizer, RandomWalkOptimizer
export ReductionOptimizer, SplitOptimizer
export optimize_step!, optimize!
export fixpoint_reached, optimize_to_fixpoint!

# models
export graph

# machine info
export machine_info, cpu_st

# GPU Extensions
export kernel, CUDAGPU, ROCmGPU, oneAPIGPU

# usability macros
export @assemble_dag, @add_call, @add_entry, @compute_task

include("devices/interface.jl")
include("task/type.jl")
include("node/type.jl")
include("diff/type.jl")
include("properties/type.jl")
include("operation/type.jl")
include("graph/type.jl")
include("scheduler/type.jl")
include("code_gen/type.jl")

include("trie.jl")
include("utils.jl")

include("diff/print.jl")
include("diff/properties.jl")
include("diff/mute.jl")

include("graph/compare.jl")
include("graph/interface.jl")
include("graph/mute.jl")
include("graph/print.jl")
include("graph/properties.jl")
include("graph/validate.jl")

include("node/compare.jl")
include("node/create.jl")
include("node/print.jl")
include("node/properties.jl")
include("node/validate.jl")

include("operation/utility.jl")
include("operation/iterate.jl")
include("operation/apply.jl")
include("operation/clean.jl")
include("operation/find.jl")
include("operation/get.jl")
include("operation/print.jl")
include("operation/validate.jl")

include("properties/create.jl")
include("properties/utility.jl")

include("task/create.jl")
include("task/compare.jl")
include("task/compute.jl")
include("task/properties.jl")

include("estimator/interface.jl")
include("estimator/global_metric.jl")

include("optimization/interface.jl")
include("optimization/greedy.jl")
include("optimization/random_walk.jl")
include("optimization/reduce.jl")
include("optimization/split.jl")

include("models/interface.jl")

include("devices/measure.jl")
include("devices/detect.jl")
include("devices/impl.jl")

include("devices/numa/impl.jl")
include("devices/ext.jl")

include("scheduler/interface.jl")
include("scheduler/greedy.jl")

include("code_gen/utils.jl")
include("code_gen/tape_machine.jl")
include("code_gen/function.jl")

include("usability/globals.jl")
include("usability/macros.jl")
include("usability/init.jl")

end # module ComputableDAGs
