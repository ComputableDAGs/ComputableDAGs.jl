"""
    GraphComputing

A module containing tools to work on DAGs.
"""
module GraphComputing

using RuntimeGeneratedFunctions
RuntimeGeneratedFunctions.init(@__MODULE__)

# graph types
export DAG
export Node
export Edge
export ComputeTaskNode
export DataTaskNode
export AbstractTask
export AbstractComputeTask
export AbstractDataTask
export DataTask
export PossibleOperations
export GraphProperties

# graph functions
export make_node
export make_edge
export insert_node!
export insert_edge!
export is_entry_node
export is_exit_node
export parents
export children
export compute
export data
export compute_effort
export task
export get_properties
export get_exit_node
export operation_stack_length
export is_valid, is_scheduled

# graph operation related
export Operation
export AppliedOperation
export NodeReduction
export NodeSplit
export push_operation!
export pop_operation!
export can_pop
export reset_graph!
export get_operations

# code generation related
export execute
export get_compute_function, get_cuda_kernel
export gen_tape, execute_tape
export unpack_identity

# estimator
export cost_type, graph_cost, operation_effect
export GlobalMetricEstimator, CDCost

# optimization
export AbstractOptimizer, GreedyOptimizer, RandomWalkOptimizer
export ReductionOptimizer, SplitOptimizer
export optimize_step!, optimize!
export fixpoint_reached, optimize_to_fixpoint!

# machine info
export Machine
export get_machine_info, cpu_st

export ==, in, show, isempty, delete!, length

export bytes_to_human_readable

import Base.length
import Base.show
import Base.==
import Base.+
import Base.-
import Base.in
import Base.copy
import Base.isempty
import Base.delete!
import Base.insert!
import Base.collect

include("devices/interface.jl")
include("task/type.jl")
include("node/type.jl")
include("diff/type.jl")
include("properties/type.jl")
include("operation/type.jl")
include("graph/type.jl")
include("scheduler/type.jl")

include("trie.jl")
include("utils.jl")

include("diff/print.jl")
include("diff/properties.jl")

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
include("devices/cuda/impl.jl")
include("devices/rocm/impl.jl")
#include("devices/oneapi/impl.jl")

include("scheduler/interface.jl")
include("scheduler/greedy.jl")

include("code_gen/type.jl")
include("code_gen/tape_machine.jl")
include("code_gen/function.jl")

end # module GraphComputing
