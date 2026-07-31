"""
    is_entry(dev::AbstractDevice)

Return whether this device is the entry device.
"""
is_entry(::AbstractDevice) = false
is_entry(dev::CPU) = dev.entry_dev
