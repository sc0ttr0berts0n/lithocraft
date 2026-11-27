# The Column as the Habitat shows it in the Bore: where a feature of interest
# is drawn against where the simulation says it is and where the Bore Station
# hangs. A Habitat in the tree, stepped by hand; its Column strip is read for
# where it puts the feature, never for its pixels.
extends GdUnitTestSuite

const Habitat := preload("res://view/habitat.gd")
const STEP := 1.0 / 60.0
## Deep enough to turn up into a climb and over again without surfacing.
const DEEP_M := 700.0


## A Habitat on the First dive, in the tree, stepped only by the test, with
## the Head a metre above the layout's first feature and under way.
func _habitat_nearing_a_feature() -> Node3D:
	var habitat := DiveTestKit.staged_habitat(self, Scenario.first_dive())
	var sim: DiveSimulation = habitat.simulation()
	sim.start_below(Scenario.first_dive().layout.features()[0][0] - 1.0)
	sim.set_power(0.5)
	return habitat


## The first feature found (or the one found after `already` others), as the
## simulation now reports it, or null.
func _feature(habitat: Node3D, already := 0) -> ColumnFeature:
	var found: Array[ColumnFeature] = habitat.simulation().found_features()
	return null if found.size() <= already else found[already]


## Where along the Bore (Habitat frame, z) the strip draws the feature's
## middle: the strip's top edge is the Bore's Tail end (+z), its bottom edge
## the Head end, as the Column tube wears it.
func _drawn_z(habitat: Node3D, already := 0) -> float:
	var strip: ColumnStrip = habitat.column_strip()
	var row := strip.feature_box(_feature(habitat, already)).get_center().y
	return Habitat.LENGTH / 2.0 - row / strip.size.y * Habitat.LENGTH


## Steps the Habitat until the next feature found (after `already` others) has
## passed the Bore Station both as the strip draws it and as the simulation
## reports it: the step each happened at, {on_screen, in_simulation}, -1 for
## never.
func _passing_the_bore_station(habitat: Node3D, already := 0) -> Dictionary:
	var sim: DiveSimulation = habitat.simulation()
	var passed := {on_screen = -1, in_simulation = -1}
	for step in 4000:
		habitat._physics_process(STEP)
		if _feature(habitat, already) == null:
			continue
		# Where the Bore Station hangs now, and how far behind the Head that
		# is by the Habitat's own account of where it sits along the vessel.
		var station_z: float = habitat.bore_station_place().z
		var behind := sim.distance() - _feature(habitat, already).at
		if passed.in_simulation < 0 and behind >= Habitat.behind_head_at(station_z):
			passed.in_simulation = step
		if passed.on_screen < 0 and _drawn_z(habitat, already) >= station_z:
			passed.on_screen = step
		if passed.on_screen >= 0 and passed.in_simulation >= 0:
			break
	return passed


func test_a_feature_passes_the_bore_station_when_the_simulation_reports_it_there() -> void:
	var habitat := _habitat_nearing_a_feature()

	var passed := _passing_the_bore_station(habitat)

	# Found at the Head, so it reached the Station some steps after it showed.
	assert_int(passed.in_simulation).is_greater(0)
	assert_int(passed.on_screen).is_equal(passed.in_simulation)


## A Habitat whose dive has turned up into a climb, so the ring of Stations
## has slid to the Tail end, then over and gently down again (too shallow for
## the Head end to be the floor, so the ring stays), a metre above the next
## feature it has not yet cut. Returns how many features it had found by then.
func _nearing_a_feature_with_the_ring_by_the_tail(habitat: Node3D) -> int:
	var sim: DiveSimulation = habitat.simulation()
	var layout := Scenario.first_dive().layout
	sim.start_below(DEEP_M)
	sim.set_power(1.0)
	sim.set_steering_effort(1.0)
	sim.set_autopilot(DiveSimulation.STATION_THERMAL, true)
	sim.set_autopilot(DiveSimulation.STATION_REACTOR, true)
	sim.set_course(sim.course_heading(), -60.0)
	var slid := func(s: DiveSimulation) -> bool: return s.station_ring() >= 1.0
	assert_bool(DiveTestKit.fly_until(sim, slid, 6000.0, 0.25)).is_true()
	sim.set_course(sim.course_heading(), 30.0)
	var descending := func(s: DiveSimulation) -> bool: return s.pitch() > 29.0
	assert_bool(DiveTestKit.fly_until(sim, descending, 6000.0, 0.25)).is_true()
	var found := sim.found_features().size()
	var next: float = layout.features()[found][0]
	var close := func(s: DiveSimulation) -> bool: return s.depth() > next - 80.0
	assert_bool(DiveTestKit.fly_until(sim, close, 6000.0, 0.25)).is_true()
	sim.set_time_rate(1.0)
	var closer := func(s: DiveSimulation) -> bool: return s.depth() > next - 1.0
	assert_bool(DiveTestKit.fly_until(sim, closer, 600.0, 0.1, false)).is_true()
	assert_int(sim.found_features().size()).is_equal(found)
	return found


func test_with_the_ring_by_the_tail_a_feature_still_passes_the_bore_station_when_the_simulation_says() -> void:
	var habitat := DiveTestKit.staged_habitat(self, Scenario.first_dive())
	var already := _nearing_a_feature_with_the_ring_by_the_tail(habitat)

	var passed := _passing_the_bore_station(habitat, already)

	# The Bore Station is up by the Tail end, so the feature has most of the
	# Habitat's length to slide before it passes: it does so on the step the
	# simulation says, there as by the Head end.
	assert_float(habitat.bore_station_place().z).is_equal_approx(Habitat.ring_z(1.0), 0.001)
	assert_int(passed.in_simulation).is_greater(0)
	assert_int(passed.on_screen).is_equal(passed.in_simulation)


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


func test_the_bores_glass_is_clear_over_the_whole_column() -> void:
	# A sight line passing the axis nearer than the Column's radius meets the
	# Column, and the glass covers nothing there: its cover starts at the
	# Column's edge and not inside it, whatever the two radii are.
	var glass := BoreGlass.material(Habitat.COLUMN_RADIUS, Habitat.BORE_RADIUS)
	var clear_within: float = glass.get_shader_parameter(&"clear_within")

	assert_float(clear_within * Habitat.BORE_RADIUS).is_equal_approx(Habitat.COLUMN_RADIUS, 0.0001)
	assert_float(clear_within).is_less(1.0)
	# A wider Column in the same glass is clear further out.
	assert_float(BoreGlass.clear_within(Habitat.COLUMN_RADIUS * 1.05, Habitat.BORE_RADIUS)).is_greater(clear_within)
