"""
    copy(t::AbstractDataTask)

Fallback implementation of the copy of an abstract data task, throwing an error.
"""
copy(t::AbstractDataTask) = error("Need to implement copying for your data tasks!")

"""
    copy(t::AbstractComputeTask)

Return a copy of the given compute task.
"""
copy(t::AbstractComputeTask) = typeof(t)()
