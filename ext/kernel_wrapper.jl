struct KAWrapper{T, UUID}
    kernel::T
    val::UUID
end

struct KAWrapperKernel{T, UUID, Args, KWArgs}
    kernel::T
    val::UUID
    args::Args
    kwargs::KWArgs
end

@inline function (k::KAWrapper{T, UUID})(args...; kwargs...) where {T, UUID}
    return KAWrapperKernel(k.kernel, k.val, args, kwargs)
end

@inline function (k::KAWrapperKernel{T, UUID, Args})(args...; kwargs...) where {T, UUID, Args}
    k.kernel(k.args...; k.kwargs...)(args..., k.val; kwargs...)
    return nothing
end
