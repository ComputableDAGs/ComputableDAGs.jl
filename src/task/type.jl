"""
    AbstractTask

The shared base type for any task.
"""
abstract type AbstractTask end

"""
    AbstractComputeTask <: AbstractTask

The shared base type for any compute task.
"""
abstract type AbstractComputeTask <: AbstractTask end

"""
    AbstractDataTask <: AbstractTask

The shared base type for any data task.
"""
abstract type AbstractDataTask <: AbstractTask end

"""
    DataTask <: AbstractDataTask

Task representing a specific data transfer.
"""
struct DataTask <: AbstractDataTask
    data::Float64
end
