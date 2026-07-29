"""
    NULL_UUID

A constant value for a UUID that is considered "null", or invalid. Used in place of `Optional` UUIDs where invalid UUIDs can appear.

See also [`isnull`](@ref).
"""
const NULL_UUID = UUID(0)

"""
    MANAGEMENT_PORT

A fixed port used for initial exchange of each device's socket info.
"""
MANAGEMENT_PORT = 15678

"""
    isnull(id::UUID)

Check whether a given UUID is "null", or invalid.

See also [`NULL_UUID`](@ref).
"""
function isnull(id::UUID)
    return id == NULL_UUID
end
