"""
    device_manager_setup_code(device_id::UUID, devices_on_machine::AbstractVector{UUID})

Generate and return the code required to create a device manager for the tape,
connecting to the other devices of the IDs given.

See also: [`AbstractDeviceManager`](@ref), [`DEVICE_MANAGER_SYM`](@ref)
"""
function device_manager_setup_code(device_id::UUID, devices_on_machine::AbstractVector{UUID})
    # TODO: once tcp stuff works, pass this through
    devices_off_machine = UUID[]

    return Expr(
        :(=),
        DEVICE_MANAGER_SYM,
        Expr(
            :call,
            ComputableDAGs.create_zmq_manager,
            device_id,
            devices_on_machine,
            devices_off_machine,
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
        ComputableDAGs.close_zmq_manager,
        DEVICE_MANAGER_SYM,
        device_id
    )
end
