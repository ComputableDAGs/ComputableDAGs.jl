"""
    Node(task::AbstractComputeTask)

Create a node with a new UUID and the given task. It is not part of any CDAG and is therefore initialized with empty dependencies, dependents, antecedents, and precedents.
"""
function Node(task::Task) where {Task <: AbstractComputeTask}
    return Node{Task}(
        UUIDs.uuid1(),      # new UUID
        task,               # the task
        Tuple{UUID, Int}[], # dependencies
        UUID[],             # dependents
        UUID(0),            # antecedent
        UUID(0),            # precedent
        0.0,                # t_level
        0.0                 # b_level
    )
end
