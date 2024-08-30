"""
    compute(t::AbstractTask; data...)

Fallback implementation of the compute function of a compute task, throwing an error.
"""
function compute end

"""
    compute_effort(t::AbstractTask)

Fallback implementation of the compute effort of a task, throwing an error.
"""
function compute_effort end

"""
    data(t::AbstractTask)

Fallback implementation of the data of a task, throwing an error.
"""
function data end

"""
    compute_effort(t::AbstractDataTask)

Return the compute effort of a data task, always zero, regardless of the specific task.
"""
compute_effort(t::AbstractDataTask)::Float64 = 0.0

"""
    data(t::AbstractDataTask)

Return the data of a data task. Given by the task's `.data` field.
"""
data(t::AbstractDataTask)::Float64 = getfield(t, :data)

"""
    copy(t::DataTask)

Copy the data task and return it.
"""
copy(t::DataTask) = DataTask(t.data)

"""
    children(::DataTask)

Return the number of children of a data task (always 1).
"""
children(::DataTask) = 1

"""
    data(t::AbstractComputeTask)

Return the data of a compute task, always zero, regardless of the specific task.
"""
data(t::AbstractComputeTask)::Float64 = 0.0
