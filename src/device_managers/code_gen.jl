"""
    device_manager_setup_code(device_id::UUID, cluster::Cluster)

Generate and return the code required to create a device manager for the given
device for the tape, connecting to the other devices of the [`Cluster`](@ref).

See also: [`AbstractDeviceManager`](@ref), [`DEVICE_MANAGER_SYM`](@ref)
"""
function device_manager_setup_code(
        device_id::UUID,
        cluster::Cluster
    )
    return Expr(
        :(=),
        DEVICE_MANAGER_SYM,
        Expr(
            :call,
            ComputableDAGs.create_device_manager,
            cluster,
            device_id,
        )
    )
end

"""
    device_manager_destroy_code(device_id::UUID)

Generate and return code to destroy a previously created device manager inside
a device function.

See also: [`AbstractDeviceManager`](@ref), [`DEVICE_MANAGER_SYM`](@ref)
"""
function device_manager_destroy_code(device_id::UUID)
    return Expr(
        :call,
        ComputableDAGs.close_device_manager,
        DEVICE_MANAGER_SYM,
        device_id
    )
end
