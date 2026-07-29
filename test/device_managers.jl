using ComputableDAGs
using ComputableDAGs: create_zmq_manager, close_zmq_manager, send, get

using Random
using UUIDs

RNG = Xoshiro(69)

@testset "Creation" begin
    id1 = uuid1()
    id2 = uuid1()
    id3 = uuid1()

    @testset "Positive Test, Single Machine" begin
        t1 = Threads.@spawn create_zmq_manager(id1, [id2, id3], UUID[])
        t2 = Threads.@spawn create_zmq_manager(id2, [id1, id3], UUID[])
        t3 = Threads.@spawn create_zmq_manager(id3, [id1, id2], UUID[])

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

        close_zmq_manager(dev1_man)
        close_zmq_manager(dev2_man)
        close_zmq_manager(dev3_man)

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
    id1 = uuid1()
    id2 = uuid1()
    id3 = uuid1()

    @testset "Positive Test, Single Machine" begin
        t1 = Threads.@spawn create_zmq_manager(id1, [id2, id3], UUID[])
        t2 = Threads.@spawn create_zmq_manager(id2, [id1, id3], UUID[])
        t3 = Threads.@spawn create_zmq_manager(id3, [id1, id2], UUID[])

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

        close_zmq_manager(dev1_man)
        close_zmq_manager(dev2_man)
        close_zmq_manager(dev3_man)
    end
end
