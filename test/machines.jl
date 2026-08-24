using UUIDs
using Random
using ComputableDAGs
using ComputableDAGs: Machine, Cluster, device_manager_type, local_devices, network_devices
using ComputableDAGs: ZMQDeviceManager, CPU

RNG = Random.Xoshiro(987)

@testset "Cluster" begin
    cpu1 = CPU(16, true)
    cpu2 = CPU(8, false)
    m1 = Machine([cpu1])
    m2 = Machine([cpu2])
    c = Cluster{ZMQDeviceManager}([m1, m2])
end
