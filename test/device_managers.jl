using ComputableDAGs
using ComputableDAGs: create_device_manager, close_device_manager, send, get,
    ZMQDeviceManager, CPU, Machine, Cluster

using Random
using UUIDs

RNG = Xoshiro(69)

@testset "$DEV_MANAGER_BACKEND" for DEV_MANAGER_BACKEND in [ZMQDeviceManager]
    cpu1 = CPU(1, true)
    cpu2 = CPU(1, false)
    cpu3 = CPU(4, false)

    id1 = cpu1.id
    id2 = cpu2.id
    id3 = cpu3.id

    machine = Machine([cpu1, cpu2, cpu3])
    cluster = Cluster{DEV_MANAGER_BACKEND}([machine])

    @testset "Creation" begin
        @testset "Positive Test, Single Machine" begin
            t1 = Threads.@spawn create_device_manager(cluster, id1)
            t2 = Threads.@spawn create_device_manager(cluster, id2)
            t3 = Threads.@spawn create_device_manager(cluster, id3)

            dev1_man = fetch(t1)
            dev2_man = fetch(t2)
            dev3_man = fetch(t3)

            for (dev, sock) in dev1_man.ipc_sockets
                @test isopen(sock)
            end
            for (dev, sock) in dev2_man.ipc_sockets
                @test isopen(sock)
            end
            for (dev, sock) in dev3_man.ipc_sockets
                @test isopen(sock)
            end

            @test haskey(dev1_man.ipc_sockets, id2)
            @test haskey(dev1_man.ipc_sockets, id3)
            @test haskey(dev2_man.ipc_sockets, id1)
            @test haskey(dev2_man.ipc_sockets, id3)
            @test haskey(dev3_man.ipc_sockets, id1)
            @test haskey(dev3_man.ipc_sockets, id2)

            close_device_manager(dev1_man, id1)
            close_device_manager(dev2_man, id2)
            close_device_manager(dev3_man, id3)

            for (dev, sock) in dev1_man.ipc_sockets
                @test !isopen(sock)
            end
            for (dev, sock) in dev2_man.ipc_sockets
                @test !isopen(sock)
            end
            for (dev, sock) in dev3_man.ipc_sockets
                @test !isopen(sock)
            end

            # TODO: add tcp socket tests once they exist
        end

        @testset "Negative" begin
            # TODO
        end
    end

    @testset "Simple on-machine send/recv" begin
        @testset "Positive Test, Single Machine" begin
            t1 = Threads.@spawn create_device_manager(cluster, id1)
            t2 = Threads.@spawn create_device_manager(cluster, id2)
            t3 = Threads.@spawn create_device_manager(cluster, id3)

            dev1_man = fetch(t1)
            dev2_man = fetch(t2)
            dev3_man = fetch(t3)

            value = (1, 2, 3)
            value_id = uuid1()

            # send from dev 1 to dev 2
            send(dev1_man, Val(true), id2, value, value_id)
            value_recvd = get(dev2_man, Val(true), id1, value_id, typeof(value))

            @test value == value_recvd

            @testset "Check order preservation" begin
                value2 = (3, 2, 1, 0)
                value3 = rand(RNG, 20)
                value_id2 = uuid1()
                value_id3 = uuid1()

                send(dev2_man, Val(true), id1, value2, value_id2)
                send(dev3_man, Val(true), id1, value3, value_id3)
                @test value2 == get(dev1_man, Val(true), id2, value_id2, typeof(value2))
                @test value3 == get(dev1_man, Val(true), id3, value_id3, typeof(value3))
            end

            close_device_manager(dev1_man, id1)
            close_device_manager(dev2_man, id2)
            close_device_manager(dev3_man, id3)
        end
    end
end
