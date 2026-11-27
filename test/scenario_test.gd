# Scenarios and their start states (ticket #35): each Scenario sets the
# simulation's starting state through its commands, and its Orders and
# Checklist tick as the First dive's do. The Shift drill starts under way a
# short way above a Boundary; Stranded in the granite starts stranded and
# sealed in, the clock running. Tested at the simulation's interface. Assert
# relationships, never tuned constants (ADR 0001).
extends GdUnitTestSuite


# --- Every Scenario ------------------------------------------------------

func test_the_start_menu_has_three_scenarios_the_first_dive_first() -> void:
	var all := Scenario.all()
	assert_int(all.size()).is_equal(3)
	assert_str(all[0].title).is_equal(Scenario.first_dive().title)
	var titles := []
	for scenario in all:
		assert_str(scenario.title).is_not_empty()
		assert_str(scenario.summary).is_not_empty()
		assert_bool(scenario.title in titles).is_false()
		titles.append(scenario.title)


func test_every_scenario_has_orders_and_a_checklist_of_distinct_steps() -> void:
	for scenario in Scenario.all():
		assert_array(scenario.orders).is_not_empty()
		assert_array(scenario.phases).is_not_empty()
		var ids := []
		for phase in scenario.phases:
			assert_array(phase.steps).is_not_empty()
			for step in phase.steps:
				assert_bool(step.station == &"" or step.station in DiveSimulation.STATIONS).is_true()
				assert_str(step.text).is_not_empty()
				assert_bool(step.id in ids).override_failure_message("%s: %s twice" % [scenario.title, step.id]).is_false()
				ids.append(step.id)


## Every command that states what the crew intends and by itself moves
## nothing, sent to this dive.
static func _state_every_intention(sim: DiveSimulation) -> void:
	sim.read_orders()
	sim.set_course(0.0, 90.0)
	sim.set_course(0.0, 0.0)
	sim.set_course(0.0, -90.0)
	sim.nudge_pitch(1.0)
	sim.nudge_heading(1.0)
	sim.set_power(1.0)
	sim.set_steering_effort(1.0)
	sim.set_heat_split(0.5)
	sim.set_uploading(true)
	sim.set_quiet_ship(true)
	sim.pulse()
	# The Reactor's selector and its two controls, on STANDBY: nothing of the
	# plasma moves until a swap.
	sim.select_channel(DiveSimulation.CHANNEL_ACTIVE)
	sim.select_channel(DiveSimulation.CHANNEL_STANDBY)
	sim.tune_frequency(sim.wobble_frequency() * 1.5)
	sim.tune_amplitude(sim.wobble_amplitude() * 0.5)
	sim.set_upload_priority(DiveSimulation.UPLOAD_MOST_VALUABLE_FIRST)
	for station in DiveSimulation.STATIONS:
		sim.set_autopilot(station, true)


func test_no_phase_begins_early_on_what_the_crew_only_intends() -> void:
	# Lists every early trigger of every Scenario (ticket #59). Each is tried
	# against the crew's intentions alone, the dive not yet run: a trigger
	# must be something the simulation reports the dive doing.
	var triggers := {}
	for scenario in Scenario.all():
		var sim := scenario.start()
		sim.take_events()
		_state_every_intention(sim)
		var intentions := sim.take_events()
		assert_array(DiveTestKit.types(intentions)).contains([&"course_plotted", &"orders_read"])
		var titles := []
		for phase in scenario.phases:
			if not phase.begins_when.is_valid():
				continue
			titles.append(phase.title)
			assert_bool(phase.begins_when.call(sim, intentions)) \
				.override_failure_message("%s: \"%s\" begins on an intention, not on what the Lithocraft does" % [scenario.title, phase.title]) \
				.is_false()
		triggers[scenario.title] = titles
	# A new early trigger is added here, and so read against the rule.
	assert_dict(triggers).is_equal({
		"First dive": ["Sand", "The first Boundary", "Sandstone", "Granite", "Turn and climb", "Surface"],
		"Shift drill": [],
		"Stranded in the granite": ["Still dark", "Relit", "Home"],
	})


func test_every_scenario_opens_with_its_orders_from_surface_control() -> void:
	for scenario in Scenario.all():
		var sim := scenario.start()
		assert_bool(DiveTestKit.fly_until(sim, func(s: DiveSimulation) -> bool: return not s.surface_messages().is_empty(), 600.0, 0.5)).is_true()


# --- The Scenario start commands ------------------------------------------

func test_starting_below_puts_the_head_that_deep_in_its_own_medium_tuned_to_it() -> void:
	var layout := Scenario.first_dive().layout
	var deep := layout.boundary_depths()[0] + 10.0
	var sim := DiveSimulation.new(layout)
	sim.start_below(deep)
	assert_float(sim.depth()).is_equal_approx(deep, 0.01)
	assert_str(sim.medium().name).is_equal(layout.medium_at(deep).name)
	# Cut with the Residual inside the Band all the way: it is flat now, and
	# the Head is as fresh as at the surface.
	assert_bool(sim.out_of_band()).is_false()
	assert_float(sim.head_wear()).is_equal(0.0)
	assert_float(sim.plasma_stability()).is_equal(DiveSimulation.new(layout).plasma_stability())
	# The hull at the rock's temperature: no warmer than the rock round it.
	assert_float(sim.vessel_temperature()).is_less_equal(sim.surroundings_temperature() + 0.01)


func test_starting_below_records_the_column_cut_and_keeps_it_aboard() -> void:
	var layout := Scenario.first_dive().layout
	var sim := DiveSimulation.new(layout)
	sim.start_below(layout.boundary_depths()[0] + 10.0)
	assert_array(sim.unsold_survey()).is_not_empty()
	assert_array(sim.uploaded_survey()).is_empty()
	assert_float(sim.distance()).is_greater(0.0)


func test_starting_below_dense_rock_leaves_the_tunnel_sealed_behind() -> void:
	var layout := Scenario.first_dive().layout
	var granite_top := layout.boundary_depths()[1]
	var shallow := DiveSimulation.new(layout)
	shallow.start_below(granite_top - 10.0)
	assert_bool(shallow.tunnel_sealed()).is_false()
	var deep := DiveSimulation.new(layout)
	deep.start_below(granite_top + 3.0 * deep.vessel_length())
	assert_bool(deep.tunnel_sealed()).is_true()


func test_starting_below_raises_none_of_the_descents_events() -> void:
	var layout := Scenario.first_dive().layout
	var sim := DiveSimulation.new(layout)
	sim.start_below(layout.boundary_depths()[1] + 50.0)
	assert_array(sim.take_events()).is_empty()


func test_the_start_commands_are_ignored_once_the_dive_has_begun() -> void:
	var layout := Scenario.first_dive().layout
	var sim := DiveSimulation.new(layout)
	sim.advance(1.0)
	sim.start_below(layout.boundary_depths()[1] + 50.0)
	assert_float(sim.depth()).is_less(1.0)
	sim.start_dark(0.5)
	assert_bool(sim.plasma_lost()).is_false()


func test_starting_dark_sealed_in_strands_the_lithocraft_with_the_head_worn() -> void:
	var layout := Scenario.first_dive().layout
	var sim := DiveSimulation.new(layout)
	sim.start_below(layout.boundary_depths()[1] + 50.0)
	sim.start_dark(0.5)
	assert_bool(sim.plasma_lost()).is_true()
	assert_bool(sim.stranded()).is_true()
	assert_float(sim.head_wear()).is_greater(0.0)
	assert_array(DiveTestKit.types(sim.take_events())).contains([&"plasma_lost", &"stranded"])


func test_starting_dark_with_the_tunnel_open_brings_the_lithocraft_home() -> void:
	var layout := Scenario.first_dive().layout
	var sim := DiveSimulation.new(layout)
	sim.start_below(layout.boundary_depths()[0] + 10.0)
	sim.start_dark(0.5)
	assert_bool(sim.stranded()).is_false()
	assert_bool(sim.surfaced()).is_true()


func test_a_worn_head_started_dark_is_harder_to_relight_than_a_fresh_one() -> void:
	var layout := Scenario.first_dive().layout
	var fresh := DiveSimulation.new(layout)
	fresh.start_below(layout.boundary_depths()[1] + 50.0)
	fresh.start_dark(0.0)
	var worn := DiveSimulation.new(layout)
	worn.start_below(layout.boundary_depths()[1] + 50.0)
	worn.start_dark(0.8)
	assert_float(worn.relight_chance()).is_less(fresh.relight_chance())


# --- The Shift drill -------------------------------------------------------

func test_the_shift_drill_starts_in_the_sand_a_short_way_above_the_sandstone() -> void:
	var scenario := Scenario.shift_drill()
	var sim := scenario.start()
	var boundary := scenario.layout.boundary_depths()[0]
	assert_str(sim.medium().name).is_equal(scenario.layout.medium_at(0.0).name)
	assert_float(sim.depth()).is_greater(0.0)
	assert_float(sim.depth()).is_less(boundary)
	# Nearer the Boundary than the surface.
	assert_float(boundary - sim.depth()).is_less(sim.depth())
	assert_bool(sim.plasma_lost()).is_false()
	assert_bool(sim.out_of_band()).is_false()


func test_the_shift_drill_leaves_the_crew_only_the_reactor() -> void:
	var scenario := Scenario.shift_drill()
	var sim := scenario.start()
	assert_bool(sim.autopilot(DiveSimulation.STATION_DRIVE)).is_true()
	assert_bool(sim.autopilot(DiveSimulation.STATION_THERMAL)).is_true()
	# The Shift is the crew's to make, not the Reactor's autopilot's.
	assert_bool(sim.autopilot(DiveSimulation.STATION_REACTOR)).is_false()
	for phase in scenario.phases:
		for step in phase.steps:
			assert_bool(step.station in [&"", DiveSimulation.STATION_REACTOR]).is_true()


func test_the_shift_drill_is_under_way_and_reaches_the_boundary_with_no_crew_command() -> void:
	var sim := Scenario.shift_drill().start()
	var before := sim.depth()
	assert_dict(DiveTestKit.run_until(sim, &"boundary_approaching", 600.0, [], 0.5)).is_not_empty()
	assert_float(sim.depth()).is_greater(before)
	assert_dict(DiveTestKit.run_until(sim, &"boundary_crossed", 600.0, [], 0.5)).is_not_empty()


func test_the_shift_drills_checklist_and_orders_tick_as_the_shift_is_made() -> void:
	var scenario := Scenario.shift_drill()
	var below := scenario.layout.medium_at(scenario.layout.boundary_depths()[0] + 0.01)
	var below_wobble := DiveTestKit.wobble_in(below)
	var sim := scenario.start()
	sim.read_orders()
	sim.advance(0.1)
	assert_str(DiveTestKit.step_state(sim, &"read_orders")).is_equal(DiveSimulation.STEP_DONE)
	assert_str(DiveTestKit.next_step_id(sim)).is_equal(&"pretune_standby")
	assert_dict(DiveTestKit.run_until(sim, &"boundary_approaching", 600.0, [], 0.5)).is_not_empty()
	assert_str(DiveTestKit.step_state(sim, &"pretune_standby")).is_equal(DiveSimulation.STEP_PENDING)
	# The drill began with a pulse: there is a guess to pretune against.
	# It is of the rock below, off the truth as a poor scan's is, and nearer
	# it than no guess at all would be: STANDBY as it began, tuned for the
	# rock the Head is in.
	var guess := sim.wobble_ahead_frequency()
	assert_bool(is_nan(guess)).is_false()
	assert_float(absf(guess - below_wobble.x)).is_less(absf(sim.wobble_frequency() - below_wobble.x))
	DiveTestKit.tune(sim, DiveSimulation.CHANNEL_STANDBY, DiveTestKit.wobble_ahead(sim))
	sim.advance(0.1)
	assert_str(DiveTestKit.step_state(sim, &"pretune_standby")).is_equal(DiveSimulation.STEP_DONE)
	assert_dict(DiveTestKit.run_until(sim, &"boundary_crossed", 600.0, [], 0.1)).is_not_empty()
	assert_bool(DiveTestKit.achieved(sim, &"clean_shift")).is_false()
	sim.shift()
	sim.advance(0.1)
	assert_str(DiveTestKit.step_state(sim, &"shift")).is_equal(DiveSimulation.STEP_DONE)
	assert_bool(DiveTestKit.achieved(sim, &"clean_shift")).is_true()


func test_a_shift_drill_shift_that_leaves_the_residual_outside_the_band_is_not_clean() -> void:
	var scenario := Scenario.shift_drill()
	var sim := scenario.start()
	sim.read_orders()
	DiveTestKit.tune(sim, DiveSimulation.CHANNEL_STANDBY, DiveTestKit.wobble_in(scenario.layout.medium_at(scenario.layout.boundary_depths()[0] + 0.01)))
	DiveTestKit.run_until(sim, &"boundary_crossed", 600.0, [], 0.5)
	# STANDBY was pretuned, but the Shift is made with it well wide of the Wobble.
	DiveTestKit.shift_to(sim, DiveTestKit.wobble(sim) * Vector2(1.5, 1.0))
	sim.advance(0.1)
	assert_str(DiveTestKit.step_state(sim, &"shift")).is_equal(DiveSimulation.STEP_DONE)
	assert_bool(DiveTestKit.achieved(sim, &"clean_shift")).is_false()


# --- Stranded in the granite ---------------------------------------------------

func test_stranded_in_the_granite_starts_stranded_and_sealed_in_with_the_clock_running() -> void:
	var scenario := Scenario.stranded_in_the_granite()
	var sim := scenario.start()
	var granite := scenario.layout.medium_at(scenario.layout.boundary_depths()[1] + 0.01)
	assert_str(sim.medium().name).is_equal(granite.name)
	assert_bool(sim.plasma_lost()).is_true()
	assert_bool(sim.stranded()).is_true()
	assert_bool(sim.tunnel_sealed()).is_true()
	assert_bool(sim.dead()).is_false()
	# The clock runs against a rescue on its way.
	var clock := sim.stranding_clock()
	assert_float(clock).is_less(INF)
	assert_float(sim.rescue_time()).is_greater(0.0)
	assert_float(sim.rescue_time()).is_less(INF)
	DiveTestKit.run(sim, 60.0)
	assert_float(sim.stranding_clock()).is_less(clock)
	# Survey aboard for the link to send on the store.
	assert_array(sim.unsold_survey()).is_not_empty()


func test_stranded_in_the_granite_starts_with_a_relight_less_sure_than_on_a_fresh_head() -> void:
	var scenario := Scenario.stranded_in_the_granite()
	var sim := scenario.start()
	var fresh := DiveSimulation.new(scenario.layout)
	fresh.start_below(sim.depth())
	fresh.start_dark(0.0)
	assert_float(sim.relight_chance()).is_less(fresh.relight_chance())


## Ends a dive of Stranded in the granite so another can begin: stranded, the
## rescue comes or the hull fails; relit and under way, the crew holds
## self-destruct at Thermal until the hull fails.
func _end_dive(sim: DiveSimulation) -> void:
	if not sim.stranded():
		sim.set_attended(DiveSimulation.STATION_THERMAL, true)
		sim.hold_self_destruct(true)
		for i in int(sim.self_destruct_hold_length()) + 1:
			sim.advance(1.0)
		sim.hold_self_destruct(false)
	assert_bool(DiveTestKit.fly_until(sim, func(s: DiveSimulation) -> bool: return s.surfaced() or s.dead(), 20000.0)).is_true()


## Stranded in the granite after the orders are read and a first relight
## tried that lit the Head (`lit`) or did not. The Head's luck runs on from
## dive to dive, so it dives again (the rescue left to come, or not) until the
## first relight goes that way. The relight's luck has a fixed seed, so the
## same dives come every run.
func _first_relight(lit: bool) -> DiveSimulation:
	var sim := Scenario.stranded_in_the_granite().start()
	for dive in 30:
		sim.read_orders()
		sim.advance(0.1)
		sim.relight()
		sim.advance(0.1)
		if sim.stranded() != lit:
			return sim
		_end_dive(sim)
		sim.new_dive()
	fail("no first relight %s in thirty dives" % ("lit" if lit else "failed"))
	return sim


func test_the_stranded_checklist_asks_for_a_relight_after_the_orders() -> void:
	var sim := Scenario.stranded_in_the_granite().start()
	sim.read_orders()
	sim.advance(0.1)
	assert_str(DiveTestKit.step_state(sim, &"read_orders")).is_equal(DiveSimulation.STEP_DONE)
	assert_str(DiveTestKit.next_step_id(sim)).is_equal(&"relight")


func test_a_relight_that_fails_leads_to_the_link_cooling_and_the_rescue() -> void:
	var sim := _first_relight(false)
	assert_str(DiveTestKit.phase_title(sim)).is_equal("Still dark")
	assert_str(DiveTestKit.next_step_id(sim)).is_equal(&"link")
	sim.set_upload_priority(DiveSimulation.UPLOAD_MOST_VALUABLE_FIRST)
	sim.advance(0.1)
	assert_str(DiveTestKit.step_state(sim, &"link")).is_equal(DiveSimulation.STEP_DONE)
	assert_str(DiveTestKit.next_step_id(sim)).is_equal(&"cool")
	sim.set_heat_split(0.5)
	sim.advance(0.1)
	assert_str(DiveTestKit.step_state(sim, &"cool")).is_equal(DiveSimulation.STEP_DONE)
	assert_str(DiveTestKit.next_step_id(sim)).is_equal(&"rescued")
	assert_bool(DiveTestKit.achieved(sim, &"home_alive")).is_false()
	assert_bool(DiveTestKit.fly_until(sim, func(s: DiveSimulation) -> bool: return s.surfaced() or s.dead(), 20000.0, 1.0)).is_true()
	assert_bool(sim.surfaced()).is_true()
	assert_str(DiveTestKit.step_state(sim, &"rescued")).is_equal(DiveSimulation.STEP_DONE)
	assert_str(DiveTestKit.step_state(sim, &"paid")).is_equal(DiveSimulation.STEP_DONE)
	assert_bool(DiveTestKit.achieved(sim, &"home_alive")).is_true()


func test_a_relight_that_lights_leads_to_the_climb_home_shifting_by_hand() -> void:
	var scenario := Scenario.stranded_in_the_granite()
	var sim := _first_relight(true)
	assert_str(DiveTestKit.step_state(sim, &"relight")).is_equal(DiveSimulation.STEP_DONE)
	assert_str(DiveTestKit.phase_title(sim)).is_equal("Relit")
	sim.set_autopilot(DiveSimulation.STATION_THERMAL, true)
	sim.advance(0.1)
	sim.set_course(0.0, -90.0)
	sim.advance(0.1)
	sim.set_autopilot(DiveSimulation.STATION_DRIVE, true)
	sim.advance(0.1)
	for id in [&"thermal_autopilot", &"plot_climb", &"drive_autopilot"]:
		assert_str(DiveTestKit.step_state(sim, id)).override_failure_message(id).is_equal(DiveSimulation.STEP_DONE)
	# The Reactor is the crew's: each Boundary up, pretune standby for the
	# Medium above and Shift as the Head crosses.
	var boundaries := scenario.layout.boundary_depths()
	for b in range(boundaries.size() - 1, -1, -1):
		var above := scenario.layout.medium_at(boundaries[b] - 0.01)
		assert_dict(DiveTestKit.run_until(sim, &"boundary_approaching", 40000.0, [], 1.0,
				func() -> void: sim.set_time_rate(sim.max_time_rate()))).is_not_empty()
		# With no scan of the Boundary above there is nothing to pretune against.
		assert_str(DiveTestKit.next_step_id(sim)).is_equal(StringName("pulse_%s" % above.name))
		DiveTestKit.quiet_scan(sim, 6)
		sim.set_time_rate(1.0)
		assert_str(DiveTestKit.step_state(sim, StringName("pulse_%s" % above.name))).is_equal(DiveSimulation.STEP_DONE)
		DiveTestKit.tune(sim, DiveSimulation.CHANNEL_STANDBY, DiveTestKit.wobble_ahead(sim))
		sim.advance(0.1)
		assert_str(DiveTestKit.step_state(sim, StringName("pretune_standby_%s" % above.name))).is_equal(DiveSimulation.STEP_DONE)
		assert_dict(DiveTestKit.run_until(sim, &"boundary_crossed", 4000.0, [], 0.1)).is_not_empty()
		sim.shift()
		sim.advance(0.1)
		assert_str(DiveTestKit.step_state(sim, StringName("shift_%s" % above.name))).is_equal(DiveSimulation.STEP_DONE)
	assert_str(DiveTestKit.next_step_id(sim)).is_equal(&"climbed")
	assert_bool(DiveTestKit.fly_until(sim, func(s: DiveSimulation) -> bool: return s.surfaced() or s.dead(), 40000.0)).is_true()
	assert_bool(sim.surfaced()).is_true()
	assert_str(DiveTestKit.step_state(sim, &"climbed")).is_equal(DiveSimulation.STEP_DONE)
	assert_str(DiveTestKit.phase_title(sim)).is_equal("Home")
	assert_str(DiveTestKit.step_state(sim, &"paid")).is_equal(DiveSimulation.STEP_DONE)
	assert_bool(DiveTestKit.achieved(sim, &"home_alive")).is_true()


func test_a_second_relight_that_lights_leaves_the_dark_for_the_climb() -> void:
	var sim := Scenario.stranded_in_the_granite().start()
	for dive in 30:
		sim.read_orders()
		sim.advance(0.1)
		sim.relight()
		sim.advance(0.1)
		if sim.stranded():
			sim.relight()
			sim.advance(0.1)
			if not sim.stranded():
				break
		_end_dive(sim)
		sim.new_dive()
	assert_bool(sim.stranded()).is_false()
	assert_str(DiveTestKit.step_state(sim, &"relight")).is_equal(DiveSimulation.STEP_MISSED)
	assert_str(DiveTestKit.phase_title(sim)).is_equal("Relit")
