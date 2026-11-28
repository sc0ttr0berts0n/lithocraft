# The First dive reworked for the survey, the Beam, a target and a Glide
# home, and the Glide drill (ticket #128): their start states, where target A
# lies, and the conditions their new steps tick on, each something the
# Lithocraft does. Tested at the simulation's interface. Assert relationships,
# never tuned constants (ADR 0001).
extends GdUnitTestSuite


func _target_a(sim: DiveSimulation) -> Array:
	return sim.found_features().filter(func(f: ColumnFeature) -> bool: return f.target == &"A")


# --- The First dive's target ------------------------------------------------

func test_the_first_dive_names_target_a_in_its_orders_and_the_survey_places_it() -> void:
	var sim := Scenario.first_dive().start()
	assert_array(sim.orders().map(func(goal: Dictionary) -> String: return goal.text)).contains(
			[Scenario.identify_target(&"A").text])
	assert_int(sim.target_regions().size()).is_equal(1)
	assert_str(sim.target_regions()[0].label).is_equal(&"A")


func test_target_a_lies_in_the_granite_where_the_line_straight_down_cuts_into_it() -> void:
	var scenario := Scenario.first_dive()
	var body: TargetBody = scenario.layout.targets()[0]
	assert_str(scenario.layout.medium_at_point(body.centre).name).is_equal(
			scenario.layout.medium_at(scenario.layout.boundary_depths()[1] + 0.01).name)
	# Its whole fuzzy place below the granite's Boundary and clear of its folds.
	var region: TargetRegion = scenario.start().target_regions()[0]
	assert_float(-(region.centre.y + region.half_size.y)).is_greater(scenario.layout.boundary_depths()[1] + 10.0)
	# The line straight down from the start passes through the body.
	var top := Vector3(0.0, body.centre.y + 100.0, 0.0)
	var bottom := Vector3(0.0, body.centre.y - 100.0, 0.0)
	assert_array(body.crossings(top, bottom)).is_not_empty()


func test_a_first_dive_crawled_straight_down_cuts_into_target_a() -> void:
	var sim := Scenario.first_dive().start()
	var body: TargetBody = Scenario.first_dive().layout.targets()[0]
	sim.start_below(-body.centre.y - 30.0)
	sim.set_autopilot(DiveSimulation.STATION_REACTOR, true)
	sim.set_autopilot(DiveSimulation.STATION_DRIVE, true)
	assert_bool(DiveTestKit.fly_until(sim, func(s: DiveSimulation) -> bool: return not _target_a(s).is_empty() or s.depth() > -body.centre.y + 30.0, 3000.0)).is_true()
	assert_array(_target_a(sim)).is_not_empty()


# --- The conditions the Glide's steps tick on ----------------------------------

## The Glide drill as it begins, its orders read.
func _drill() -> DiveSimulation:
	var sim := Scenario.glide_drill().start()
	sim.read_orders()
	return sim


func test_the_glide_drill_begins_halted_at_quiet_ship_in_porous_rock_with_a_scan_to_glide_on() -> void:
	var scenario := Scenario.glide_drill()
	var sim := _drill()
	assert_bool(sim.quiet_ship()).is_true()
	assert_float(sim.speed()).is_equal(0.0)
	assert_float(sim.depth()).is_greater(0.0)
	assert_float(sim.medium().porosity).is_greater_equal(sim.seal_porosity())
	assert_str(sim.medium().name).is_equal(scenario.layout.medium_at(0.0).name)
	assert_float(sim.glide_reach()).is_greater(0.0)


func test_starting_a_glide_ticks_its_step_only_once_the_lithocraft_glides() -> void:
	var sim := _drill()
	var gliding := Scenario.gliding()
	# V pressed with nothing plotted, and at Quiet Ship: refused, nothing glides.
	sim.start_glide()
	sim.advance(0.1)
	assert_bool(gliding.call(sim, sim.take_events())).is_false()
	sim.plot_glide(100.0)
	sim.set_quiet_ship(false)
	sim.advance(0.1)
	sim.start_glide()
	assert_bool(gliding.call(sim, [])).is_false()
	sim.advance(0.5)
	assert_bool(gliding.call(sim, sim.take_events())).is_true()


func test_out_of_a_glide_the_crawl_begins_only_once_the_head_is_spun_up() -> void:
	var sim := _drill()
	var crawling := Scenario.crawling()
	sim.plot_glide(100.0)
	sim.set_quiet_ship(false)
	sim.advance(0.1)
	sim.start_glide()
	sim.set_autopilot(DiveSimulation.STATION_DRIVE, true)
	assert_dict(DiveTestKit.run_until(sim, &"glide_ended", 120.0, [], 0.05)).is_not_empty()
	DiveTestKit.run(sim, 5.0, 0.1)
	# Halted at idle, however long it waits.
	assert_str(sim.glide_state()).is_equal(DiveSimulation.GLIDE_IDLE)
	assert_bool(crawling.call(sim, [])).is_false()
	sim.shift()
	DiveTestKit.run(sim, 10.0, 0.1)
	assert_bool(crawling.call(sim, [])).is_true()


func test_the_lithocraft_is_straight_on_its_course_only_once_it_has_come_round() -> void:
	var sim := Scenario.glide_drill().start()
	sim.set_quiet_ship(false)
	sim.set_autopilot(DiveSimulation.STATION_DRIVE, true)
	assert_bool(sim.straight_on_course()).is_true()
	assert_bool(Scenario.straight_on_course().call(sim, [])).is_true()
	# A Course plotted a step off: not straight on it until the turn is done.
	sim.set_course(0.0, 90.0 - 15.0)
	sim.advance(0.1)
	assert_bool(sim.straight_on_course()).is_false()
	assert_bool(DiveTestKit.fly_until(sim, func(s: DiveSimulation) -> bool: return s.straight_on_course(), 20000.0)).is_true()
	# Nudged off it at the Drive, the Lithocraft no longer follows it.
	sim.set_attended(DiveSimulation.STATION_DRIVE, true)
	sim.nudge_pitch(1.0)
	assert_bool(sim.straight_on_course()).is_false()


func test_the_scan_shows_the_glide_home_above_a_boundary_only_when_it_shows_the_rock_beyond() -> void:
	# Deep in the granite, pointed up its line: surveyed, the scan shows both
	# Boundaries above; unsurveyed, nothing.
	var scenario := Scenario.first_dive()
	var granite := scenario.layout.medium_at(scenario.layout.boundary_depths()[1] + 0.01).name
	var middle := scenario.layout.medium_at(scenario.layout.boundary_depths()[0] + 0.01).name
	var shown := Scenario.glide_shown_above(granite)
	var surveyed := DiveSimulation.new(scenario.layout)
	surveyed.start_below(scenario.layout.boundary_depths()[1] + 150.0)
	surveyed.start_surveyed()
	surveyed.set_course(0.0, -90.0)
	var blind := DiveSimulation.new(scenario.layout)
	blind.start_below(scenario.layout.boundary_depths()[1] + 150.0)
	blind.set_course(0.0, -90.0)
	assert_bool(shown.call(surveyed, [])).is_true()
	assert_bool(shown.call(blind, [])).is_false()
	# A Glide stops short of the furthest Boundary the scan shows, so the
	# shallowest Boundary shown is never passed.
	assert_bool(Scenario.glide_shown_above(middle).call(surveyed, [])).is_false()
