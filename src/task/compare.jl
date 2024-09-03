"""
    ==(t1::AbstractTask, t2::AbstractTask)

Fallback implementation of equality comparison between two abstract tasks. Always returns false. For equal specific types of t1 and t2, a more specific comparison is called instead, doing an actual comparison.
"""
function Base.:(==)(t1::AbstractTask, t2::AbstractTask)
    return false
end

"""
    ==(t1::AbstractComputeTask, t2::AbstractComputeTask)

Equality comparison between two compute tasks.
"""
function Base.:(==)(t1::AbstractComputeTask, t2::AbstractComputeTask)
    return typeof(t1) == typeof(t2)
end

"""
    ==(t1::AbstractDataTask, t2::AbstractDataTask)

Equality comparison between two data tasks.
"""
function Base.:(==)(t1::AbstractDataTask, t2::AbstractDataTask)
    return data(t1) == data(t2)
end
