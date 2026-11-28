# Navigation's scan display: the three candidate views of one scan, tested by
# where each puts a place in the world (ScanDisplay's static functions) and
# by where a real pulse's returns land. A place on the screen is (x to the
# right, y down the screen), so "up the screen" is the lesser y.
# Assert relationships, never tuned constants (ADR 0001).
extends GdUnitTestSuite

const BEARINGS: Array[float] = [0.0, 60.0, 90.0, 200.0, 315.0]
const PITCHES: Array[float] = [90.0, 60.0, 30.0, 0.0, -45.0]


## The way the Head points at this compass heading and pitch (+90 straight
## down), as the simulation's frame has it: 0 along -Z, 90 along +X.
func _heading(bearing: float, pitch: float) -> Vector3:
	var b := deg_to_rad(bearing)
	var p := deg_to_rad(pitch)
	return Vector3(sin(b) * cos(p), -sin(p), -cos(b) * cos(p))


## The vessel's right at this compass heading: level, square to its track.
func _right(bearing: float) -> Vector3:
	var b := deg_to_rad(bearing)
	return Vector3(cos(b), 0.0, sin(b))


## Sends a pulse, lets it return and gives back the points it added.
func _pulse(sim: DiveSimulation) -> Array[ScanPoint]:
	var before := sim.pulses_sent()
	sim.pulse()
	sim.advance(0.1)
	return sim.points().filter(func(p: ScanPoint) -> bool: return p.pulse >= before)


## Test values only: a soft rock and a hard, tight one by turns, a Boundary
## every 200 m, so a pulse always has something to return from wherever the
## vessel has got to.
func _banded() -> MediumLayout:
	var layers := []
	for i in 20:
		layers.append([i * 200.0, DiveTestKit.rock(1.0) if i % 2 == 0 else DiveTestKit.basalt(4.0, 1.0, 0.02)])
	return MediumLayout.layered(layers)


## A dive straight down, under way; the Reactor and Thermal mind themselves.
func _diving() -> DiveSimulation:
	var sim := DiveSimulation.new(_banded())
	sim.set_autopilot(DiveSimulation.STATION_THERMAL, true)
	sim.set_autopilot(DiveSimulation.STATION_REACTOR, true)
	sim.set_power(1.0)
	DiveTestKit.run(sim, 60.0)
	sim.take_events()
	return sim


## The same dive part way through a turn from straight down toward level,
## heading east.
func _mid_turn() -> DiveSimulation:
	var sim := _diving()
	sim.set_steering_effort(1.0)
	sim.set_course(90.0, 0.0)
	for i in 600:
		if sim.pitch() < 60.0:
			break
		sim.advance(1.0)
		sim.take_events()
	assert_float(sim.pitch()).is_between(1.0, 60.0)
	assert_bool(sim.plasma_lost()).is_false()
	return sim


func _mean(places: Array[Vector2]) -> Vector2:
	var sum := Vector2.ZERO
	for place in places:
		sum += place
	return sum / maxf(places.size(), 1.0)


# --- The forward scope ------------------------------------------------------

func test_on_the_forward_scope_what_lies_ahead_is_up_the_screen_whatever_the_heading() -> void:
	for bearing in BEARINGS:
		for pitch in PITCHES:
			var ahead := _heading(bearing, pitch)
			var near := ScanDisplay.scope_place(ahead * 100.0, ahead, bearing)
			var far := ScanDisplay.scope_place(ahead * 200.0, ahead, bearing)
			var behind := ScanDisplay.scope_place(ahead * -100.0, ahead, bearing)

			assert_float(near.x).is_equal_approx(0.0, 0.001)
			assert_float(near.y).is_less(0.0)
			assert_float(far.y).is_less(near.y)
			assert_float(behind.y).is_greater(0.0)


func test_the_forward_scope_keeps_distance_ahead_as_range() -> void:
	var ahead := _heading(60.0, 40.0)

	var place := ScanDisplay.scope_place(ahead * 150.0, ahead, 60.0)

	assert_float(place.length()).is_equal_approx(150.0, 0.001)


func test_on_the_forward_scope_a_level_boundary_is_one_line_at_any_pitch() -> void:
	# Places on one level surface under the vessel, spread to its left and
	# right: each lands where the one in the vessel's own vertical plane does.
	for pitch in PITCHES:
		var ahead := _heading(90.0, pitch)
		var under := Vector3(40.0, -120.0, 0.0)
		var middle := ScanDisplay.scope_place(under, ahead, 90.0)
		for aside: float in [-80.0, 35.0, 150.0]:
			var place := ScanDisplay.scope_place(under + _right(90.0) * aside, ahead, 90.0)
			assert_float(place.distance_to(middle)).is_equal_approx(0.0, 0.001)


func test_on_the_forward_scope_down_swings_from_ahead_to_one_side_as_the_vessel_levels() -> void:
	var diving := ScanDisplay.scope_place(Vector3.DOWN * 100.0, _heading(0.0, 90.0), 0.0)
	var slanting := ScanDisplay.scope_place(Vector3.DOWN * 100.0, _heading(0.0, 45.0), 0.0)
	var level := ScanDisplay.scope_place(Vector3.DOWN * 100.0, _heading(0.0, 0.0), 0.0)

	assert_float(diving.y).is_less(slanting.y)
	assert_float(slanting.y).is_less(level.y)
	assert_float(level.y).is_equal_approx(0.0, 0.001)
	# To the left all the way, since in a dive onward along the compass
	# heading is to the right, as the moving map has it.
	assert_float(slanting.x).is_less(0.0)
	assert_float(level.x).is_less(slanting.x)
	assert_float(ScanDisplay.scope_place(_heading(0.0, 0.0) * 100.0, _heading(0.0, 90.0), 0.0).x).is_greater(0.0)


func test_on_the_forward_scope_a_dive_s_returns_lie_ahead_of_the_vessel() -> void:
	for sim: DiveSimulation in [_diving(), _mid_turn()]:
		var returns := _pulse(sim)
		var places: Array[Vector2] = []
		for point in returns:
			places.append(ScanDisplay.scope_place(point.position - sim.head_position(),
					sim.heading(), sim.heading_degrees()))

		assert_int(returns.size()).is_greater(0)
		assert_float(_mean(places).y).is_less(0.0)
		assert_int(places.filter(func(p: Vector2) -> bool: return p.y < 0.0).size()) \
				.is_greater(places.size() * 3 / 4)


# --- The plan and section pair ----------------------------------------------

func test_in_the_section_deeper_is_lower_and_ahead_is_to_the_right() -> void:
	for bearing in BEARINGS:
		var onward := _heading(bearing, 0.0)
		var here := ScanDisplay.section_place(Vector3.ZERO, bearing)
		var deeper := ScanDisplay.section_place(Vector3.DOWN * 50.0, bearing)
		var ahead := ScanDisplay.section_place(onward * 50.0, bearing)
		var aside := ScanDisplay.section_place(_right(bearing) * 50.0, bearing)

		assert_float(deeper.y).is_greater(here.y)
		assert_float(deeper.x).is_equal_approx(here.x, 0.001)
		assert_float(ahead.x).is_greater(here.x)
		assert_float(ahead.y).is_equal_approx(here.y, 0.001)
		assert_float(aside.distance_to(here)).is_equal_approx(0.0, 0.001)


func test_in_the_plan_ahead_is_to_the_right_as_in_the_section_and_depth_moves_nothing() -> void:
	for bearing in BEARINGS:
		var onward := _heading(bearing, 0.0)
		var here := ScanDisplay.plan_place(Vector3.ZERO, bearing)
		var ahead := ScanDisplay.plan_place(onward * 50.0, bearing)
		var to_the_right := ScanDisplay.plan_place(_right(bearing) * 50.0, bearing)
		var deeper := ScanDisplay.plan_place(Vector3.DOWN * 50.0, bearing)

		assert_float(ahead.x).is_equal_approx(ScanDisplay.section_place(onward * 50.0, bearing).x, 0.001)
		assert_float(ahead.x).is_greater(here.x)
		# Seen from above with ahead to the right, the vessel's right is down
		# the screen.
		assert_float(to_the_right.y).is_greater(here.y)
		assert_float(to_the_right.x).is_equal_approx(here.x, 0.001)
		assert_float(deeper.distance_to(here)).is_equal_approx(0.0, 0.001)


func test_in_the_section_a_dive_s_returns_lie_below_and_mid_turn_ahead_as_well() -> void:
	var diving := _diving()
	var below: Array[Vector2] = []
	for point in _pulse(diving):
		below.append(ScanDisplay.section_place(point.position - diving.head_position(),
				diving.heading_degrees()))
	var turning := _mid_turn()
	var onward: Array[Vector2] = []
	for point in _pulse(turning):
		onward.append(ScanDisplay.section_place(point.position - turning.head_position(),
				turning.heading_degrees()))

	assert_float(_mean(below).y).is_greater(0.0)
	assert_float(_mean(onward).y).is_greater(0.0)
	assert_float(_mean(onward).x).is_greater(0.0)
	assert_float(_mean(onward).x).is_greater(_mean(below).x)


# --- The world-up 3D view ---------------------------------------------------

func test_in_the_world_up_view_deeper_is_always_straight_down_the_screen() -> void:
	for bearing in BEARINGS:
		var here := ScanDisplay.world_up_place(Vector3(30.0, -40.0, 70.0), bearing)
		var deeper := ScanDisplay.world_up_place(Vector3(30.0, -140.0, 70.0), bearing)

		assert_float(deeper.y).is_greater(here.y)
		assert_float(deeper.x).is_equal_approx(here.x, 0.001)


func test_the_world_up_view_turns_with_the_compass_heading_and_shows_ahead_to_the_right() -> void:
	var north := Vector3.FORWARD * 100.0

	var heading_north := ScanDisplay.world_up_place(north, 0.0)
	var heading_east := ScanDisplay.world_up_place(north, 90.0)

	assert_float(heading_north.distance_to(heading_east)).is_greater(1.0)
	for bearing in BEARINGS:
		# Ahead along the compass heading: to the right, as on the moving map.
		assert_float(ScanDisplay.world_up_place(_heading(bearing, 0.0) * 100.0, bearing).x).is_greater(0.0)


func test_in_the_world_up_view_a_dive_s_returns_lie_below_the_vessel() -> void:
	for sim: DiveSimulation in [_diving(), _mid_turn()]:
		var places: Array[Vector2] = []
		for point in _pulse(sim):
			places.append(ScanDisplay.world_up_place(point.position - sim.head_position(),
					sim.heading_degrees()))

		assert_float(_mean(places).y).is_greater(0.0)


# --- All three --------------------------------------------------------------

func test_every_candidate_view_has_a_name_of_its_own_for_the_screen() -> void:
	var sim := DiveSimulation.new(MediumLayout.first_dive())
	var names := {}

	for view in sim.scan_views():
		var name := ScanDisplay.title(view)
		assert_str(name).is_not_empty()
		names[name] = true

	assert_int(names.size()).is_equal(sim.scan_views().size())


func test_the_display_names_the_candidate_the_simulation_holds() -> void:
	var sim := _diving()
	var display: ScanDisplay = auto_free(ScanDisplay.new())
	display.sim = sim
	add_child(display)
	var first := display.caption()

	sim.debug_next_scan_view()

	assert_str(first).contains(ScanDisplay.title(sim.scan_views()[0]))
	assert_str(display.caption()).contains(ScanDisplay.title(sim.scan_view()))
	assert_str(display.caption()).is_not_equal(first)


## The display's own source, for the checks that read it.
static func _display_source() -> String:
	return (load("res://view/scan_display.gd") as GDScript).source_code


func test_the_display_reads_the_scan_and_never_the_layout_or_a_clock() -> void:
	# Every view is drawn from the simulation's queries alone, and nothing in
	# it runs on its own time, so a view changes only as the vessel does.
	var source: String = _display_source()
	for word in ["MediumLayout", "_layout", "medium_at", "boundary_depths", "Time.", "get_ticks", "randf", "randi"]:
		assert_bool(source.contains(word)) \
				.override_failure_message("scan_display.gd names %s" % word) \
				.is_false()


# --- The Beam's width and the scope's range ---------------------------------

## A quiet vessel straight down with a Boundary this many metres below the
## Head, three clean pulses sent, and a display of the game's own size
## reading it.
func _boundary_below(metres: float) -> Array:
	var start := DiveSimulation.new(MediumLayout.uniform(DiveTestKit.rock(1.0))).depth()
	var sim := DiveSimulation.new(MediumLayout.layered([[0.0, DiveTestKit.rock(1.0)],
			[start + metres, DiveTestKit.basalt(4.0, 1.0, 0.02)]]))
	DiveTestKit.quiet_scan(sim)
	var display: ScanDisplay = auto_free(ScanDisplay.new())
	display.size = (load("res://view/habitat.gd") as GDScript).call(&"_navigation_display_px")
	display.sim = sim
	add_child(display)
	display._process(0.0)
	return [sim, display]


func test_the_display_names_the_beam_s_width_in_every_view() -> void:
	var sim := _diving()
	var display: ScanDisplay = auto_free(ScanDisplay.new())
	display.sim = sim
	add_child(display)

	for view in sim.scan_views():
		var shown := {}
		for width in DiveSimulation.BEAM_WIDTHS:
			sim.set_beam_width(width)
			assert_str(display.beam_label().to_lower()).contains(String(width))
			shown[display.beam_label()] = true
		assert_int(shown.size()).is_equal(DiveSimulation.BEAM_WIDTHS.size())
		sim.debug_next_scan_view()


func test_the_display_names_the_sweep_s_range_and_how_far_a_running_one_has_got() -> void:
	var sim := DiveSimulation.new(_banded())
	var display: ScanDisplay = auto_free(ScanDisplay.new())
	display.sim = sim
	add_child(display)
	var shown := {}
	for metres in DiveSimulation.SWEEP_RANGES:
		sim.set_sweep_range(metres)
		assert_str(display.sweep_label()).contains("%d m" % roundi(metres))
		shown[display.sweep_label()] = true
	assert_int(shown.size()).is_equal(DiveSimulation.SWEEP_RANGES.size())

	sim.start_sweep()
	DiveTestKit.run(sim, sim.sweep_duration() * 0.2, 0.5)
	var early := display.sweep_label()
	DiveTestKit.run(sim, sim.sweep_duration() * 0.4, 0.5)

	assert_str(early).contains("%")
	assert_str(display.sweep_label()).is_not_equal(early)
	assert_str(display.sweep_label()).contains("%d%%" % floori(sim.sweep_progress() * 100.0))


func test_the_scope_steps_in_for_a_nearer_boundary_and_out_with_none_ahead() -> void:
	var ranges := {}
	var last := 0.0
	for ahead in range(5, 250, 5):
		var shown := ScanDisplay.scope_range(ahead).x
		# A Boundary further ahead never shows on a shorter range, and the one
		# it was chosen for is in view.
		assert_float(shown).is_greater_equal(last)
		assert_float(shown).is_greater(ahead)
		last = shown
		ranges[shown] = true

	# It steps: more than two ranges between a near Boundary and a far one.
	assert_int(ranges.size()).is_greater(2)
	assert_float(ScanDisplay.scope_range(INF).x).is_greater_equal(last)
	assert_float(ScanDisplay.scope_range(30.0).x).is_less(ScanDisplay.scope_range(INF).x)


func test_a_boundary_30_m_ahead_is_drawn_clear_of_the_vessel_s_marker() -> void:
	var staged := _boundary_below(30.0)
	var display: ScanDisplay = staged[1]
	var pane := display.single_pane()

	var shown := 30.0 * ScanDisplay.scope_scale(pane, display.scope_shown().x)
	var at_the_furthest := 30.0 * ScanDisplay.scope_scale(pane, ScanDisplay.scope_range(INF).x)

	assert_float(display.scope_shown().x).is_less(ScanDisplay.scope_range(INF).x)
	assert_float(shown).is_greater(at_the_furthest)
	assert_float(shown).is_greater(4.0 * ScanDisplay.VESSEL_PX)


func test_the_scope_s_range_changes_only_on_a_pulse() -> void:
	# A Boundary well ahead, then the vessel closes on it with no pulse: the
	# range holds until the next pulse, which steps it in.
	var staged := _boundary_below(150.0)
	var sim: DiveSimulation = staged[0]
	var display: ScanDisplay = staged[1]
	var before := display.scope_shown()
	sim.set_autopilot(DiveSimulation.STATION_THERMAL, true)
	sim.set_power(1.0)
	var start := sim.depth()
	while sim.depth() < start + 120.0:
		sim.advance(0.5)
		display._process(0.0)
		assert_vector(display.scope_shown()).is_equal(before)

	DiveTestKit.quiet_scan(sim)
	display._process(0.0)

	assert_float(display.scope_shown().x).is_less(before.x)


# --- The rock beyond a Boundary (#122) ----------------------------------------

func test_harder_rock_beyond_is_hatched_and_softer_stippled_more_marks_the_stronger() -> void:
	for contrast in [0.1, 0.3, 0.6]:
		assert_bool(ScanDisplay.rock_hatched(contrast)).is_true()
		assert_bool(ScanDisplay.rock_hatched(-contrast)).is_false()
		assert_int(ScanDisplay.rock_marks(-contrast)).is_equal(ScanDisplay.rock_marks(contrast))
		assert_str(ScanDisplay.rock_words(contrast)).contains("HARDER")
		assert_str(ScanDisplay.rock_words(-contrast)).contains("SOFTER")
	assert_int(ScanDisplay.rock_marks(0.6)).is_greater(ScanDisplay.rock_marks(0.1))
	assert_str(ScanDisplay.rock_words(0.6)).is_not_equal(ScanDisplay.rock_words(0.1))
	# Rock that sounds the same, or a patch that says nothing: no band.
	assert_int(ScanDisplay.rock_marks(0.0)).is_equal(0)
	assert_int(ScanDisplay.rock_marks(NAN)).is_equal(0)


func test_navigation_says_what_lies_beyond_the_boundary_ahead() -> void:
	var into_harder: Array = _boundary_below(30.0)
	var sim: DiveSimulation = into_harder[0]
	assert_str(ScanDisplay.rock_label(sim)).contains(ScanDisplay.rock_words(sim.rock_ahead()))
	assert_str(ScanDisplay.rock_label(sim)).contains("HARDER")
	assert_str(ScanDisplay.rock_label(sim)).contains("%d%%" % roundi(sim.rock_ahead_confidence() * 100.0))

	var unscanned := DiveSimulation.new(MediumLayout.first_dive())
	assert_str(ScanDisplay.rock_label(unscanned)).not_contains("HARDER")
	assert_str(ScanDisplay.rock_label(unscanned)).not_contains("SOFTER")


func test_a_rock_is_named_only_as_surface_control_s_expectation_until_the_column_shows_it() -> void:
	var guess := {name = &"granite", depth = 604.0, confirmed = false}
	var shown := {name = &"granite", depth = 604.0, confirmed = true}

	assert_str(ScanDisplay.expected_label(guess)).contains("GRANITE")
	assert_str(ScanDisplay.expected_label(guess)).contains("EXPECTED")
	assert_str(ScanDisplay.expected_label(shown)).contains("GRANITE")
	assert_str(ScanDisplay.expected_label(shown)).not_contains("EXPECTED")
	# Shortened for a narrow pane, still marked as a guess.
	assert_str(ScanDisplay.expected_label(guess, true)).contains("?")
	assert_str(ScanDisplay.expected_label(shown, true)).not_contains("?")
	# The display has no other way to a rock's name: not the Medium the Head
	# is in, not the Column, not the Bore Station's record.
	var source: String = _display_source()
	for word in ["medium()", "column_at", "survey()", "composition"]:
		assert_bool(source.contains(word)) \
				.override_failure_message("scan_display.gd names %s" % word) \
				.is_false()


func test_the_scope_s_range_follows_the_boundary_ahead_of_the_vessel_however_the_beam_is_aimed() -> void:
	# The Boundary 30 m dead ahead steps the scope in; the Beam then aimed
	# square across and pulsed there finds no Boundary along its aim, and the
	# scope keeps to the one ahead of the vessel.
	var staged := _boundary_below(30.0)
	var sim: DiveSimulation = staged[0]
	var display: ScanDisplay = staged[1]
	var before := display.scope_shown()
	assert_float(before.x).is_less(ScanDisplay.scope_range(INF).x)

	sim.set_beam_aim(90.0, 0.0)
	DiveTestKit.quiet_scan(sim)
	display._process(0.0)

	assert_vector(display.scope_shown()).is_equal(before)


## The area an outline on the screen covers, square pixels.
func _area(outline: PackedVector2Array) -> float:
	var twice := 0.0
	for i in outline.size():
		twice += outline[i].cross(outline[(i + 1) % outline.size()])
	return absf(twice) * 0.5


func test_a_target_s_region_is_drawn_in_every_view_round_its_middle_and_smaller_as_it_narrows() -> void:
	var head := Vector3(0.0, -400.0, 0.0)
	var wide := TargetRegion.new(&"A", head + Vector3(20.0, -60.0, 10.0), Vector3(20.0, 30.0, 20.0))
	var narrow := TargetRegion.new(&"A", wide.centre, Vector3(6.0, 5.0, 6.0))
	var down := _heading(0.0, 90.0)
	var views: Array[Callable] = [
		func(offset: Vector3) -> Vector2: return ScanDisplay.scope_place(offset, down, 0.0),
		func(offset: Vector3) -> Vector2: return ScanDisplay.plan_place(offset, 0.0),
		func(offset: Vector3) -> Vector2: return ScanDisplay.section_place(offset, 0.0),
		func(offset: Vector3) -> Vector2: return ScanDisplay.world_up_place(offset, 0.0),
	]
	for place in views:
		var outline := ScanDisplay.region_outline(wide, head, place, 1.0)
		assert_int(outline.size()).is_greater(2)
		assert_bool(Geometry2D.is_point_in_polygon(place.call(wide.centre - head), outline)).is_true()
		assert_float(_area(ScanDisplay.region_outline(narrow, head, place, 1.0))).is_less(_area(outline))
		# Its inner shares lie inside its rim, so the fill builds toward the middle.
		assert_float(_area(ScanDisplay.region_outline(wide, head, place, 0.5))).is_less(_area(outline))
