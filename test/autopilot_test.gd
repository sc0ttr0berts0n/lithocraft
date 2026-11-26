# Each Station's autopilot as a switch, A320 style (ticket #32): engaged and
# disengaged by the crew, let go by any command that changes the Station's
# setting, and the only thing that decides whether a Station steadies itself.
# Tested at the simulation's interface. Assert relationships, never tuned
# constants (ADR 0001).
extends GdUnitTestSuite


func _soft() -> Medium:
	return Medium.new(&"soft", 1.0, 3.0, 0.3, 300.0, 1.0, {&"quartz": 1.0}, 0.5)


func _hard() -> Medium:
	return Medium.new(&"hard", 4.0, 3.0, 0.3, 300.0, 1.0, {&"feldspar": 1.0}, 0.5)


func _sim() -> DiveSimulation:
	return DiveSimulation.new(MediumLayout.uniform(DiveTestKit.rock(2.0, 2.0, 0.3)))


func _offs(events: Array) -> Array:
	return events.filter(func(e: Dictionary) -> bool: return e.type == &"autopilot_off")


## Every crew command that changes a Station's setting, by the Station it
## belongs to.
func _setting_commands() -> Array:
	return [
		[DiveSimulation.STATION_DRIVE, func(s: DiveSimulation) -> void: s.set_power(0.6)],
		[DiveSimulation.STATION_DRIVE, func(s: DiveSimulation) -> void: s.set_steering_effort(0.5)],
		[DiveSimulation.STATION_DRIVE, func(s: DiveSimulation) -> void: s.nudge_pitch(-1.0)],
		[DiveSimulation.STATION_DRIVE, func(s: DiveSimulation) -> void: s.nudge_heading(1.0)],
		[DiveSimulation.STATION_DRIVE, func(s: DiveSimulation) -> void: s.end_override()],
		[DiveSimulation.STATION_NAVIGATION, func(s: DiveSimulation) -> void: s.set_course(90.0, 0.0)],
		[DiveSimulation.STATION_NAVIGATION, func(s: DiveSimulation) -> void: s.set_quiet_ship(true)],
		[DiveSimulation.STATION_THERMAL, func(s: DiveSimulation) -> void: s.set_heat_split(0.5)],
		[DiveSimulation.STATION_REACTOR, func(s: DiveSimulation) -> void: DiveTestKit.shift_to(s, s.plasma_frequency())],
		[DiveSimulation.STATION_BORE, func(s: DiveSimulation) -> void: s.set_upload_priority(DiveSimulation.UPLOAD_NEWEST_FIRST)],
		[DiveSimulation.STATION_BORE, func(s: DiveSimulation) -> void: s.set_uploading(false)],
	]


# --- The switch ---------------------------------------------------------------

func test_every_autopilot_starts_off() -> void:
	var sim := _sim()

	for station in DiveSimulation.STATIONS:
		assert_bool(sim.autopilot(station)).is_false()


func test_the_switch_engages_and_disengages_each_station_alone() -> void:
	for station in DiveSimulation.STATIONS:
		var sim := _sim()
		sim.set_autopilot(station, true)

		for other in DiveSimulation.STATIONS:
			assert_bool(sim.autopilot(other)).is_equal(other == station)

		sim.take_events()
		sim.set_autopilot(station, false)

		assert_bool(sim.autopilot(station)).is_false()
		var offs := _offs(sim.take_events())
		assert_int(offs.size()).is_equal(1)
		assert_str(String(offs[0].station)).is_equal(String(station))
		assert_str(String(offs[0].cause)).is_equal(String(DiveSimulation.AUTOPILOT_OFF_BY_SWITCH))


func test_switching_off_an_autopilot_that_is_off_raises_nothing() -> void:
	var sim := _sim()
	sim.set_autopilot(DiveSimulation.STATION_THERMAL, false)

	assert_array(_offs(sim.take_events())).is_empty()


func test_a_setting_command_disengages_its_stations_autopilot_and_says_so() -> void:
	for command in _setting_commands():
		var sim := _sim()
		sim.set_attended(command[0], true)  # The Drive's nudges need the crew there.
		for station in DiveSimulation.STATIONS:
			sim.set_autopilot(station, true)
		sim.take_events()

		command[1].call(sim)

		for station in DiveSimulation.STATIONS:
			assert_bool(sim.autopilot(station)).is_equal(station != command[0])
		var offs := _offs(sim.take_events())
		assert_int(offs.size()).is_equal(1)
		assert_str(String(offs[0].station)).is_equal(String(command[0]))
		assert_str(String(offs[0].cause)).is_equal(String(DiveSimulation.AUTOPILOT_OFF_BY_COMMAND))


func test_taking_a_reading_leaves_the_autopilot_engaged() -> void:
	var sim := _sim()
	for station in DiveSimulation.STATIONS:
		sim.set_autopilot(station, true)
	sim.take_events()

	sim.pulse()
	sim.set_observed_feature(-1)
	sim.advance(1.0)

	for station in DiveSimulation.STATIONS:
		assert_bool(sim.autopilot(station)).is_true()
	assert_array(_offs(sim.take_events())).is_empty()


func test_a_new_dive_starts_with_every_autopilot_off() -> void:
	var sim := _sim()
	sim.set_power(0.5)
	DiveTestKit.run(sim, 5.0)
	for station in DiveSimulation.STATIONS:
		sim.set_autopilot(station, true)
	sim.debug_surface()

	sim.new_dive()

	for station in DiveSimulation.STATIONS:
		assert_bool(sim.autopilot(station)).is_false()


# --- Off: the Station holds its setting and does nothing more -----------------

func test_with_the_autopilots_off_stations_hold_their_settings_through_steady_conditions() -> void:
	var sim := _sim()
	sim.set_power(0.4)
	sim.set_heat_split(0.3)
	sim.set_course(30.0, 45.0)
	sim.set_upload_priority(DiveSimulation.UPLOAD_NEWEST_FIRST)
	# Long enough for the Drive's turn onto the Course.
	for i in 6000:
		sim.advance(1.0)
		assert_bool(sim.heat_warning()).is_false()
	var speed_before := sim.speed()
	for i in 600:
		sim.advance(1.0)

	assert_float(sim.power()).is_equal(0.4)
	assert_float(sim.heat_split()).is_equal(0.3)
	assert_float(sim.pitch()).is_equal_approx(45.0, 0.5)
	assert_float(sim.heading_degrees()).is_equal_approx(30.0, 0.5)
	assert_str(String(sim.upload_priority())).is_equal(String(DiveSimulation.UPLOAD_NEWEST_FIRST))
	assert_float(sim.speed()).is_equal_approx(speed_before, speed_before * 0.01)
	assert_float(sim.vessel_wear()).is_equal(0.0)
	assert_float(sim.head_wear()).is_equal(0.0)


## Full power, all heat outward: the hull heads for damage. Nobody is at
## Thermal either way: only the switch differs.
func _overheating(engaged: bool) -> DiveSimulation:
	var sim := _sim()
	sim.set_power(1.0)
	sim.set_autopilot(DiveSimulation.STATION_THERMAL, engaged)
	return sim


func test_thermals_autopilot_steadies_a_warning_hull_and_off_it_does_not() -> void:
	var engaged := _overheating(true)
	var off := _overheating(false)
	for i in 1200:
		engaged.advance(1.0)
		off.advance(1.0)

	assert_bool(off.heat_warning()).is_true()
	assert_float(off.heat_split()).is_equal(0.0)
	assert_float(engaged.heat_split()).is_greater(0.0)
	assert_float(engaged.vessel_wear()).is_less(off.vessel_wear())


func test_thermals_autopilot_is_slow_to_answer_a_sudden_heat() -> void:
	var sim := _overheating(true)
	var warned := false
	while not warned:
		sim.advance(0.5)
		warned = sim.heat_warning()
	sim.advance(1.0)

	# One second after the warning it has barely begun to move the split.
	assert_float(sim.heat_split()).is_less(0.1)


## Full power against a wall too weak to take it: the grip waves slip. The
## crew sets full power, then (or not) engages the Drive's autopilot and puts
## the power back to full by hand without touching the Drive's switch: the
## test reaches it through the slip itself.
func _slipping(engaged: bool) -> DiveSimulation:
	var sim := DiveSimulation.new(MediumLayout.uniform(DiveTestKit.rock(1.0, 0.2, 0.3)))
	if engaged:
		sim.set_autopilot(DiveSimulation.STATION_DRIVE, true)
	else:
		sim.set_power(1.0)
	return sim


func test_the_drives_autopilot_backs_its_power_off_to_what_the_wall_can_grip_and_off_it_does_not() -> void:
	var engaged := _slipping(true)
	var off := _slipping(false)
	for i in 20:
		engaged.advance(0.5)
		off.advance(0.5)

	assert_float(off.slip()).is_greater(0.0)
	assert_float(off.power()).is_equal(1.0)
	assert_float(engaged.slip()).is_less(0.01)
	# Backing off only stops the slipping: what the wall grips still moves it.
	assert_float(engaged.speed()).is_greater(0.0)
	assert_float(engaged.heat_produced()).is_less(off.heat_produced())


## Crosses one Boundary with the Reactor's autopilot engaged or off, and the
## crew at the Reactor either way; the crew makes no Shift. Returns the Shift
## result, if any came.
func _boundary_crossed(engaged: bool) -> DiveSimulation:
	var sim := DiveSimulation.new(MediumLayout.layered([[0.0, _soft()], [20.0, _hard()]]))
	sim.set_power(0.5)
	sim.set_attended(DiveSimulation.STATION_REACTOR, true)
	sim.set_autopilot(DiveSimulation.STATION_REACTOR, engaged)
	DiveTestKit.run_until(sim, &"boundary_crossed")
	return sim


func test_with_the_reactors_autopilot_off_a_due_shift_waits_for_the_crew() -> void:
	var sim := _boundary_crossed(false)

	assert_dict(DiveTestKit.run_until(sim, &"shift_result", 300.0)).is_empty()
	assert_bool(sim.shift_due()).is_true()


func test_the_reactors_autopilot_shifts_late_and_poorly_even_with_the_crew_watching() -> void:
	var sim := _boundary_crossed(true)
	var crewed := _boundary_crossed(false)
	crewed.advance(2.0)
	DiveTestKit.shift_to(crewed, crewed.plasma_frequency())

	var by_autopilot := DiveTestKit.run_until(sim, &"shift_result")
	var by_crew := DiveTestKit.run_until(crewed, &"shift_result")

	assert_bool(by_autopilot.autopilot).is_true()
	assert_bool(by_autopilot.clean).is_false()
	assert_bool(by_crew.autopilot).is_false()
	assert_float(by_autopilot.grade).is_less(by_crew.grade)


func test_switching_the_reactors_autopilot_on_with_a_shift_overdue_lets_it_make_it() -> void:
	var sim := _boundary_crossed(false)
	DiveTestKit.run(sim, 120.0)
	assert_bool(sim.shift_due()).is_true()

	sim.set_autopilot(DiveSimulation.STATION_REACTOR, true)
	var result := DiveTestKit.run_until(sim, &"shift_result", 5.0)

	assert_bool(result.autopilot).is_true()


func test_calls_still_come_with_the_autopilots_off() -> void:
	var sim := _boundary_crossed(false)
	DiveTestKit.run(sim, 5.0)

	assert_str(String(sim.call_reason(DiveSimulation.STATION_REACTOR))).is_equal("shift_due")


# --- The Drive's autopilot follows the Course ------------------------------

## At rest at the surface with a Course plotted, then either the Drive's
## autopilot engaged or the crew setting a high power by hand.
func _under_way(by_autopilot: bool) -> DiveSimulation:
	var sim := _sim()
	sim.set_course(60.0, 30.0)
	if by_autopilot:
		sim.set_autopilot(DiveSimulation.STATION_DRIVE, true)
	else:
		sim.set_power(1.0)
	return sim


func test_a_plotted_course_and_the_drives_autopilot_get_the_vessel_moving_along_it() -> void:
	var sim := _under_way(true)
	DiveTestKit.run(sim, 4000.0)

	assert_float(sim.distance()).is_greater(0.0)
	assert_float(sim.pitch()).is_equal_approx(30.0, 0.5)
	assert_float(sim.heading_degrees()).is_equal_approx(60.0, 0.5)
	assert_bool(sim.autopilot(DiveSimulation.STATION_DRIVE)).is_true()


func test_the_drives_autopilot_goes_slower_than_a_crew_set_high_power() -> void:
	var autopiloted := DiveTestKit.run(_under_way(true), 60.0)
	var crewed := DiveTestKit.run(_under_way(false), 60.0)

	assert_float(autopiloted.distance()).is_greater(0.0)
	assert_float(crewed.distance()).is_greater(autopiloted.distance())


func test_the_drives_autopilot_turns_more_gently_than_a_crew_steering_hard() -> void:
	var autopiloted := DiveTestKit.run(_under_way(true), 30.0)
	var crewed := _sim()
	crewed.set_course(60.0, 30.0)
	crewed.set_power(autopiloted.power())  # Same speed: only the steering differs.
	crewed.set_steering_effort(1.0)
	DiveTestKit.run(crewed, 30.0)

	assert_float(autopiloted.steering()).is_less(crewed.steering())


func test_engaging_the_drives_autopilot_ends_an_override() -> void:
	var sim := _sim()
	sim.set_attended(DiveSimulation.STATION_DRIVE, true)
	sim.nudge_pitch(-1.0)
	assert_bool(sim.overriding()).is_true()

	sim.set_autopilot(DiveSimulation.STATION_DRIVE, true)

	assert_bool(sim.overriding()).is_false()


func test_an_override_holds_after_the_crew_walks_away_from_the_drive() -> void:
	var sim := _sim()
	sim.set_attended(DiveSimulation.STATION_DRIVE, true)
	sim.nudge_pitch(-1.0)

	sim.set_attended(DiveSimulation.STATION_DRIVE, false)
	sim.advance(1.0)

	assert_bool(sim.overriding()).is_true()
