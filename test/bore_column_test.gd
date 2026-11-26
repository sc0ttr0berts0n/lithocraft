# The Column as the Habitat shows it in the Bore: where a feature of interest
# is drawn against where the simulation says it is and where the Bore Station
# hangs. A Habitat in the tree, stepped by hand; its Column strip is read for
# where it puts the feature, never for its pixels.
extends GdUnitTestSuite

const Habitat := preload("res://view/habitat.gd")
const STEP := 1.0 / 60.0


## A Habitat on the First dive, in the tree, stepped only by the test, with
## the Head a metre above the layout's first feature and under way.
func _habitat_nearing_a_feature() -> Node3D:
	var habitat: Node3D = auto_free((load("res://view/habitat.tscn") as PackedScene).instantiate())
	habitat.scenario = Scenario.first_dive()
	add_child(habitat)
	habitat.set_physics_process(false)
	var sim: DiveSimulation = habitat.simulation()
	sim.start_below(Scenario.first_dive().layout.features()[0][0] - 1.0)
	sim.set_power(0.5)
	return habitat


## The first feature found, as the simulation now reports it, or null.
func _feature(habitat: Node3D) -> ColumnFeature:
	var found: Array[ColumnFeature] = habitat.simulation().found_features()
	return null if found.is_empty() else found[0]


## Where along the Bore (Habitat frame, z) the strip draws the feature's
## middle: the strip's top edge is the Bore's Tail end (+z), its bottom edge
## the Head end, as the Column tube wears it.
func _drawn_z(habitat: Node3D) -> float:
	var strip: ColumnStrip = habitat.column_strip()
	var row := strip.feature_box(_feature(habitat)).get_center().y
	return Habitat.LENGTH / 2.0 - row / strip.size.y * Habitat.LENGTH


func test_a_feature_passes_the_bore_station_when_the_simulation_reports_it_there() -> void:
	var habitat := _habitat_nearing_a_feature()
	var sim: DiveSimulation = habitat.simulation()
	var station_z: float = habitat.bore_station_place().z
	# How far behind the Head the Bore Station hangs, by the Habitat's own
	# account of where it sits along the vessel.
	var station_behind: float = Habitat.behind_head_at(station_z)
	var passed_on_screen := -1
	var passed_in_simulation := -1

	for step in 4000:
		habitat._physics_process(STEP)
		if _feature(habitat) == null:
			continue
		var behind := sim.distance() - _feature(habitat).at
		if passed_in_simulation < 0 and behind >= station_behind:
			passed_in_simulation = step
		if passed_on_screen < 0 and _drawn_z(habitat) >= station_z:
			passed_on_screen = step
		if passed_on_screen >= 0 and passed_in_simulation >= 0:
			break

	# Found at the Head, so it reached the Station some steps after it showed.
	assert_int(passed_in_simulation).is_greater(0)
	assert_int(passed_on_screen).is_equal(passed_in_simulation)


func test_the_column_runs_the_whole_length_of_the_bore_at_the_rooms_own_scale() -> void:
	var habitat := _habitat_nearing_a_feature()
	var strip: ColumnStrip = habitat.column_strip()

	# The strip wrapped round the Column shows as many metres as the Habitat is
	# long, so a metre of Column is a metre of room from cap to cap.
	assert_float(strip.size.y / strip.pixels_per_metre).is_equal_approx(Habitat.LENGTH, 0.01)


func test_a_feature_slides_toward_the_tail_as_far_as_the_vessel_went() -> void:
	var habitat := _habitat_nearing_a_feature()
	var sim: DiveSimulation = habitat.simulation()
	while _feature(habitat) == null:
		habitat._physics_process(STEP)
	var z_before := _drawn_z(habitat)
	var distance_before := sim.distance()

	for step in 120:
		habitat._physics_process(STEP)

	assert_float(sim.distance()).is_greater(distance_before)
	assert_float(_drawn_z(habitat) - z_before).is_equal_approx(sim.distance() - distance_before, 0.001)


func test_a_feature_faces_the_bore_station() -> void:
	var habitat := _habitat_nearing_a_feature()
	while _feature(habitat) == null:
		habitat._physics_process(STEP)
	var strip: ColumnStrip = habitat.column_strip()
	var station: Vector3 = habitat.bore_station_place()

	# The strip's width wraps once round the Column, from the Habitat's +x
	# toward its +y.
	var round_column: float = strip.feature_box(_feature(habitat)).get_center().x / strip.size.x * TAU
	var toward_feature := Vector2.from_angle(round_column)
	var toward_station := Vector2(station.x, station.y).normalized()

	assert_float(toward_feature.dot(toward_station)).is_greater(0.999)
