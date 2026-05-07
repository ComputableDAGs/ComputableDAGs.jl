"""
    AbstractTask

The shared base type for tasks. Tasks are the basic units of work.
"""
abstract type AbstractTask end

"""
    AbstractComputeTask

The shared base type for compute tasks. A compute task is a simple compute of inputs to outputs.
"""
abstract type AbstractComputeTask <: AbstractTask end

# TBW VectorizedComputeTask <: AbstractComputeTask
