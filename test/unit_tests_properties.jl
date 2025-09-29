using ComputableDAGs

prop = GraphProperties()

@test prop.data == 0.0
@test prop.compute_effort == 0.0
@test prop.compute_intensity == 0.0
@test prop.number_of_nodes == 0.0
@test prop.number_of_edges == 0.0

prop2 = (
    data = 5.0,
    compute_effort = 6.0,
    compute_intensity = 6.0 / 5.0,
    number_of_nodes = 2,
    number_of_edges = 3,
)::GraphProperties

@test prop + prop2 == prop2
@test prop2 - prop == prop2

neg_prop = -prop2
@test neg_prop.data == -5.0
@test neg_prop.compute_effort == -6.0
@test neg_prop.compute_intensity == 6.0 / 5.0
@test neg_prop.number_of_nodes == -2
@test neg_prop.number_of_edges == -3

@test neg_prop + prop2 == GraphProperties()

prop3 = (
    data = 7.0,
    compute_effort = 3.0,
    compute_intensity = 7.0 / 3.0,
    number_of_nodes = -3,
    number_of_edges = 2,
)::GraphProperties

prop_sum = prop2 + prop3

@test prop_sum.data == 12.0
@test prop_sum.compute_effort == 9.0
@test prop_sum.compute_intensity == 9.0 / 12.0
@test prop_sum.number_of_nodes == -1
@test prop_sum.number_of_edges == 5
