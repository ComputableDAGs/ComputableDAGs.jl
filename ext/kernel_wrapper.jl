"""
    KAWrapper{T, UUID}

A wrapper around a KernelAbstractions kernel. Takes the `kernel::T` and a `UUID::Val`.

This is necessary to insert the Val to the KernelAbstractions kernel without needing the user to do it manually.
The Val itself is necessary to be able to define multiple different kernels working on the same input type. It is used in the expression cache as the key, and dispatched on in the `@generated` function.
"""
struct KAWrapper{T, UUID}
    kernel::T
    val::UUID
end

"""
    KAWrapperKernel{T, UUID, Args, KWArgs}

The second level of wrapping, to imitate the way that KernelAbstractions kernels are called: `kernel(<kernel config/backend>)(<runtime arguments>)`.
"""
struct KAWrapperKernel{T, UUID, Args, KWArgs}
    kernel::T
    val::UUID
    args::Args
    kwargs::KWArgs
end

# initial level, args and kwargs are the kernel config, stored in the KAWrapperKernel
@inline function (k::KAWrapper{T, UUID})(args...; kwargs...) where {T, UUID}
    return KAWrapperKernel(k.kernel, k.val, args, kwargs)
end

# second level, wraps the actual call, inserting the kernel config args/kwargs, and calling with the runtime args + the stored val
@inline function (k::KAWrapperKernel{T, UUID, Args})(args...; kwargs...) where {T, UUID, Args}
    k.kernel(k.args...; k.kwargs...)(args..., k.val; kwargs...)
    return nothing
end
