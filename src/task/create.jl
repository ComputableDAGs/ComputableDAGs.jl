"""
    copy(t::AbstractDataTask)

Fallback implementation of the copy of an abstract data task, throwing an error.
"""
Base.copy(t::AbstractDataTask) = error("need to implement copying for your data tasks")

"""
    copy(t::AbstractComputeTask)

Return a copy of the given compute task.
"""
Base.copy(t::AbstractComputeTask) = typeof(t)()
