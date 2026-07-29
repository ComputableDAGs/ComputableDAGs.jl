function _bind_tcp_on_free_port(socket::Socket)
    port = MANAGEMENT_PORT + 1
    cont = true
    while cont
        try
            bind(socket, "tcp://0.0.0.0:" * string(port))
            cont = false
        catch e
            if e isa StateError
                port += 1
            else
                rethrow(e)
            end
        end
    end

    return port
end

"""
    create_zmq_manager(
        this::UUID,
        devices_on_machine::AbstractVector{UUID},
        devices_off_machine::AbstractVector{UUID}
    )

Create a [`ZMQDeviceManager`](@ref) from the given device IDs.

See also: [`close_zmq_manager`](@ref)
"""
function create_zmq_manager(this::UUID, devices_on_machine::AbstractVector{UUID}, devices_off_machine::AbstractVector{UUID})
    ctx = ZMQ.context()

    # TODO: set up socket on management port with some sort of publish/subscribe protocol for every device to publish
    # its own address/port and collect every other device's address/port
    if !isempty(devices_off_machine)
        @warn "There are off-machine devices which is not currently implemented"
    end

    # Set up own TCP socket per off-machine device
    #=
    for dev in devices_off_machine
        tcp_sockets[dev] = Socket(ctx, PAIR)
        port = _bind_tcp_on_free_port(tcp_sockets[dev])
        @debug "Set up TCP socket on port $port"
    end
    =#

    # Set up own IPC socket per on-machine device
    ipc_sockets = Dict{UUID, Socket}()
    for dev in devices_on_machine
        ipc_sockets[dev] = Socket(ctx, PAIR)

        # smaller id creates the socket, bigger id connects
        if this < dev
            bind(ipc_sockets[dev], "ipc:///tmp/cdags_" * string(this) * "_" * string(dev) * ".socket")
        else
            # TODO: make this a non-busy wait somehow
            while !issocket("/tmp/cdags_" * string(dev) * "_" * string(this) * ".socket")
                yield()
            end
            @debug "$this connected to $dev"
            connect(ipc_sockets[dev], "ipc:///tmp/cdags_" * string(dev) * "_" * string(this) * ".socket")
        end
    end

    @debug "Device Manager created"
    # TODO: add off-machine devices here

    return ZMQDeviceManager(
        Dict{UUID, Socket}(),     #tcp_sockets,
        ipc_sockets,
    )
end

"""
    close_zmq_manager(manager::ZMQDeviceManager)

Closes the own sockets of the given manager.

See also: [`create_zmq_manager`](@ref)
"""
function close_zmq_manager(manager::ZMQDeviceManager)
    # RAII would be cool :(
    for (dev, s) in manager.ipc_sockets
        close(s)
    end
    for (dev, s) in manager.tcp_sockets
        close(s)
    end

    @debug "Device Manager closed"
    return nothing
end
