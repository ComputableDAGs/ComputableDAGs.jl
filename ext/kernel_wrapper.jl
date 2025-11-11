"""
    KAWrapper{T, ID}

A wrapper around a KernelAbstractions kernel. Takes the `kernel::T` and an `ID::Val`.

This is necessary to insert the id to the KernelAbstractions kernel without needing the user to do it manually.
The Val itself is necessary to be able to define multiple different kernels working on the same input type. It is used in the expression cache as the key, and dispatched on in the `@generated` function.
"""
struct KAWrapper{T, ID}
    kernel::T
    id::ID
end

"""
    KAWrapperKernel{T, ID, Args, KWArgs}

The second level of wrapping, to imitate the way that KernelAbstractions kernels are called: `kernel(<kernel config/backend>)(<runtime arguments>)`.
"""
struct KAWrapperKernel{T, ID, Args, KWArgs}
    kernel::T
    id::ID
    args::Args
    kwargs::KWArgs
end

# initial level, args and kwargs are the kernel config, stored in the KAWrapperKernel
@inline function (k::KAWrapper{T, ID})(args...; kwargs...) where {T, ID}
    return KAWrapperKernel(k.kernel, k.id, args, kwargs)
end

# second level, wraps the actual call, inserting the kernel config args/kwargs, and calling with the runtime args + the stored id
@inline function (k::KAWrapperKernel{T, ID, Args})(args...; kwargs...) where {T, ID, Args}
    k.kernel(k.args...; k.kwargs...)(args..., k.id; kwargs...)
    return nothing
end
