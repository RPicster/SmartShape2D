extends "res://addons/gut/test.gd"


class z_sort:
	var z_index: int = 0

	func _init(z: int):
		z_index = z


func test_z_sort():
	var a = [z_sort.new(3), z_sort.new(5), z_sort.new(0), z_sort.new(-12)]
	a = RMSS2D_Shape_Base.sort_by_z_index(a)
	assert_eq(a[0].z_index, -12)
	assert_eq(a[1].z_index, 0)
	assert_eq(a[2].z_index, 3)
	assert_eq(a[3].z_index, 5)


func test_are_points_clockwise():
	var shape = RMSS2D_Shape_Base.new()
	add_child_autofree(shape)
	var points_clockwise = [Vector2(-10, -10), Vector2(10, -10), Vector2(10, 10), Vector2(-10, 10)]
	var points_c_clockwise = points_clockwise.duplicate()
	points_c_clockwise.invert()

	shape.add_points_to_curve(points_clockwise)
	assert_true(shape.are_points_clockwise())

	shape.clear_points()
	shape.add_points_to_curve(points_c_clockwise)
	assert_false(shape.are_points_clockwise())


func test_curve_duplicate():
	var shape = RMSS2D_Shape_Base.new()
	add_child_autofree(shape)
	shape.add_point_to_curve(Vector2(-10, -20))
	var points = [Vector2(-10, -10), Vector2(10, -10), Vector2(10, 10), Vector2(-10, 10)]
	shape.collision_bake_interval = 35.0
	var curve = shape.get_curve()

	assert_eq(shape.get_point_count(), curve.get_point_count())
	assert_eq(shape.collision_bake_interval, curve.bake_interval)
	shape.collision_bake_interval = 25.0
	assert_ne(shape.collision_bake_interval, curve.bake_interval)

	curve.add_point(points[0])
	assert_ne(shape.get_point_count(), curve.get_point_count())
	shape.set_curve(curve)
	assert_eq(shape.get_point_count(), curve.get_point_count())


func test_tess_point_vertex_relationship():
	var s_m = RMSS2D_Shape_Base.new()
	add_child_autofree(s_m)
	var points = [
		Vector2(0, 0),
		Vector2(50, -50),
		Vector2(100, 0),
		Vector2(100, 100),
		Vector2(-50, 150),
		Vector2(-100, 100)
	]

	s_m.add_points_to_curve(points)

	var verts = s_m.get_vertices()
	var t_verts = s_m.get_tessellated_points()
	assert_eq(points.size(), t_verts.size())

	var control_point_value = Vector2(-16, 0)
	var control_point_vtx_idx = 4

	s_m.set_point_in(control_point_vtx_idx, control_point_value)
	s_m.set_point_out(control_point_vtx_idx, control_point_value * -1)

	verts = s_m.get_vertices()
	t_verts = s_m.get_tessellated_points()
	assert_ne(points.size(), t_verts.size())

	var test_idx = 4
	var test_t_idx = s_m.get_tessellated_idx_from_point(verts, t_verts, test_idx)
	assert_ne(test_idx, test_t_idx)
	assert_eq(verts[test_idx], t_verts[test_t_idx])
	var new_test_idx = s_m.get_vertex_idx_from_tessellated_point(verts, t_verts, test_t_idx)
	assert_eq(test_idx, new_test_idx)

	var results = [
		s_m.get_ratio_from_tessellated_point_to_vertex(verts, t_verts, test_t_idx),
		s_m.get_ratio_from_tessellated_point_to_vertex(verts, t_verts, test_t_idx + 1),
		s_m.get_ratio_from_tessellated_point_to_vertex(verts, t_verts, test_t_idx + 2),
		s_m.get_ratio_from_tessellated_point_to_vertex(verts, t_verts, test_t_idx + 3)
	]
	assert_eq(0.0, results[0])
	var message = "Ratio increasing with distance from prev vector"
	for i in range(1, results.size(), 1):
		assert_true(results[i - 1] < results[i], message)

	results[-1] = s_m.get_ratio_from_tessellated_point_to_vertex(verts, t_verts, test_t_idx - 1)
	assert_true(results[-1] > results[0], message)