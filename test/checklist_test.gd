# Orders, goals and the Checklist (ticket #34): a Scenario's Orders and
# Checklist are plain data, evaluated against the simulation at its seam.
# Each step ticks when the simulation sees it done, and not before; each goal
# reports achieved or not yet; surface control's messages come down the link,
# slowed to its trickle once sealed in. Tested at the simulation's interface.
# Assert relationships, never tuned constants (ADR 0001).
extends GdUnitTestSuite


## The first dive's Media in a short layout, so the whole Checklist can be
## walked in a few hundred metres: the Checklist reads Media by name, never by
## depth. A feature in each Medium.
func _short_first_dive() -> MediumLayout:
	return MediumLayout.layered([
		[0.0, Medium.sand()],
		[60.0, Medium.sandstone()],
		[100.0, Medium.granite()],
	]).with_features([
		[20.0, ColumnFeature.fulgurite()],
		[66.0, ColumnFeature.petrified_wood()],
		[106.0, ColumnFeature.quartz_vein()],
	])


func _first_dive_on(layout: MediumLayout) -> DiveSimulation:
	var sim := DiveSimulation.new(layout)
	sim.set_scenario(Scenario.first_dive())
	return sim


## Advances in steps of `step` (the time rate raised before each, if `fast`)
## until `done` holds of the sim or `seconds` have passed. Returns whether it
## held.
static func _fly_until(sim: DiveSimulation, done: Callable, seconds := 3000.0,
		step := 1.0, fast := true) -> bool:
	for i in int(seconds / step):
		if done.call(sim):
			return true
		if fast:
			sim.set_time_rate(sim.max_time_rate())
		sim.advance(step)
		sim.take_events()
	return done.call(sim)


## The frequency the plasma wobbles at in this Medium, read from a dive in it.
static func _wobble_in(medium: Medium) -> float:
	return DiveSimulation.new(MediumLayout.uniform(medium)).plasma_frequency()


## A one-phase Scenario whose steps are these [id, condition] pairs, in order.
static func _scenario_of(steps: Array, phases_after := []) -> Scenario:
	var scenario := Scenario.new()
	var phase := Scenario.Phase.new("Only")
	for s in steps:
		phase.steps.append(Scenario.Step.new(s[0], "", &"", &"", s[1]))
	scenario.phases.append(phase)
	scenario.phases.append_array(phases_after)
	return scenario


# --- The Orders and the Checklist are plain data -------------------------

func test_the_first_dive_has_orders_and_a_checklist_in_seven_phases() -> void:
	var scenario := Scenario.first_dive()
	assert_array(scenario.orders).is_not_empty()
	assert_int(scenario.phases.size()).is_equal(7)
	var ids := []
	for phase in scenario.phases:
		assert_array(phase.steps).is_not_empty()
		for step in phase.steps:
			assert_bool(step.station == &"" or step.station in DiveSimulation.STATIONS).is_true()
			assert_str(step.text).is_not_empty()
			ids.append(step.id)
	# Every step can be told apart.
	for id in ids:
		assert_int(ids.count(id)).is_equal(1)


func test_a_scenario_starts_its_own_dive_on_its_own_layout() -> void:
	var scenario := Scenario.first_dive()
	var sim := scenario.start()
	assert_str(sim.scenario_title()).is_equal(scenario.title)
	assert_str(DiveTestKit.next_step_id(sim)).is_equal(scenario.phases[0].steps[0].id)
	assert_int(sim.orders().size()).is_equal(scenario.orders.size())


func test_a_dive_without_a_scenario_has_no_checklist() -> void:
	var sim := DiveSimulation.new(MediumLayout.uniform(Medium.sand()))
	DiveTestKit.run(sim, 5.0)
	assert_array(sim.checklist()).is_empty()
	assert_array(sim.orders()).is_empty()
	assert_dict(sim.next_step()).is_empty()


# --- How steps tick ------------------------------------------------------

func test_a_step_ticks_when_its_condition_is_met_and_not_before() -> void:
	var sim := DiveSimulation.new(MediumLayout.uniform(Medium.sand()))
	sim.set_scenario(_scenario_of([[&"deep", Scenario.when(
			func(s: DiveSimulation) -> bool: return s.depth() > 5.0)]]))
	sim.set_power(0.3)
	assert_bool(_fly_until(sim, func(s: DiveSimulation) -> bool: return s.depth() > 4.0, 600.0, 0.1, false)).is_true()
	assert_str(DiveTestKit.step_state(sim, &"deep")).is_equal(DiveSimulation.STEP_PENDING)
	assert_bool(_fly_until(sim, func(s: DiveSimulation) -> bool: return s.depth() > 5.5, 600.0, 0.1, false)).is_true()
	assert_str(DiveTestKit.step_state(sim, &"deep")).is_equal(DiveSimulation.STEP_DONE)


func test_steps_tick_in_order() -> void:
	var sim := DiveSimulation.new(MediumLayout.uniform(Medium.sand()))
	sim.set_scenario(_scenario_of([
		[&"first", Scenario.on_event(&"orders_read")],
		[&"second", Scenario.when(func(_s: DiveSimulation) -> bool: return true)],
	]))
	DiveTestKit.run(sim, 3.0)
	# The second is already true, but waits for the first.
	assert_str(DiveTestKit.step_state(sim, &"second")).is_equal(DiveSimulation.STEP_PENDING)
	assert_str(DiveTestKit.next_step_id(sim)).is_equal(&"first")
	sim.read_orders()
	sim.advance(1.0)
	assert_str(DiveTestKit.step_state(sim, &"first")).is_equal(DiveSimulation.STEP_DONE)
	assert_str(DiveTestKit.step_state(sim, &"second")).is_equal(DiveSimulation.STEP_DONE)
	assert_dict(sim.next_step()).is_empty()


func test_one_event_ticks_one_step() -> void:
	var sim := DiveSimulation.new(MediumLayout.uniform(Medium.sand()))
	sim.set_scenario(_scenario_of([
		[&"once", Scenario.on_event(&"orders_read")],
		[&"twice", Scenario.on_event(&"orders_read")],
	]))
	sim.read_orders()
	sim.advance(1.0)
	assert_str(DiveTestKit.step_state(sim, &"once")).is_equal(DiveSimulation.STEP_DONE)
	assert_str(DiveTestKit.step_state(sim, &"twice")).is_equal(DiveSimulation.STEP_PENDING)
	sim.read_orders()
	sim.advance(1.0)
	assert_str(DiveTestKit.step_state(sim, &"twice")).is_equal(DiveSimulation.STEP_DONE)


func test_a_later_phase_beginning_leaves_unfinished_steps_missed() -> void:
	var sim := DiveSimulation.new(MediumLayout.uniform(Medium.sand()))
	var later := Scenario.Phase.new("Later", Scenario.on_event(&"orders_read"))
	later.steps.append(Scenario.Step.new(&"after", "", &"", &"",
			Scenario.when(func(_s: DiveSimulation) -> bool: return false)))
	sim.set_scenario(_scenario_of([[&"never", Scenario.when(
			func(_s: DiveSimulation) -> bool: return false)]], [later]))
	sim.advance(1.0)
	assert_int(sim.checklist_phase()).is_equal(0)
	sim.read_orders()
	sim.advance(1.0)
	assert_int(sim.checklist_phase()).is_equal(1)
	assert_str(DiveTestKit.step_state(sim, &"never")).is_equal(DiveSimulation.STEP_MISSED)
	assert_str(DiveTestKit.next_step_id(sim)).is_equal(&"after")


func test_a_new_dive_starts_the_checklist_afresh() -> void:
	var sim := _first_dive_on(MediumLayout.uniform(Medium.sand()))
	sim.read_orders()
	sim.advance(1.0)
	assert_str(DiveTestKit.step_state(sim, &"read_orders")).is_equal(DiveSimulation.STEP_DONE)
	assert_bool(_home_from_the_sand(sim)).is_true()
	assert_bool(DiveTestKit.achieved(sim, &"surfaced")).is_true()
	sim.new_dive()
	sim.advance(1.0)
	assert_str(DiveTestKit.step_state(sim, &"read_orders")).is_equal(DiveSimulation.STEP_PENDING)
	assert_bool(DiveTestKit.achieved(sim, &"surfaced")).is_false()


## Flies a dive in uniform sand round to the surface: Thermal's autopilot
## on, the Drive at a power the sand grips, steering hard, the Course plotted
## straight up. Returns whether it surfaced.
static func _home_from_the_sand(sim: DiveSimulation) -> bool:
	sim.set_autopilot(DiveSimulation.STATION_THERMAL, true)
	sim.set_power(0.5)
	sim.set_steering_effort(1.0)
	sim.set_course(0.0, -90.0)
	return _fly_until(sim, func(s: DiveSimulation) -> bool: return s.surfaced(), 6000.0)


# --- The first dive's Checklist, step by step ----------------------------

func test_the_startup_steps_tick_as_each_is_done() -> void:
	var sim := _first_dive_on(_short_first_dive())
	sim.advance(1.0)
	assert_str(DiveTestKit.next_step_id(sim)).is_equal(&"read_orders")
	sim.read_orders()
	sim.advance(1.0)
	assert_str(DiveTestKit.step_state(sim, &"read_orders")).is_equal(DiveSimulation.STEP_DONE)

	for pair in [[&"reactor_autopilot", DiveSimulation.STATION_REACTOR],
			[&"thermal_autopilot", DiveSimulation.STATION_THERMAL]]:
		assert_str(DiveTestKit.next_step_id(sim)).is_equal(pair[0])
		sim.advance(1.0)
		assert_str(DiveTestKit.step_state(sim, pair[0])).is_equal(DiveSimulation.STEP_PENDING)
		sim.set_autopilot(pair[1], true)
		sim.advance(1.0)
		assert_str(DiveTestKit.step_state(sim, pair[0])).is_equal(DiveSimulation.STEP_DONE)

	# A level Course is not the dive the orders want.
	assert_str(DiveTestKit.next_step_id(sim)).is_equal(&"plot_course")
	sim.set_course(0.0, 0.0)
	sim.advance(1.0)
	assert_str(DiveTestKit.step_state(sim, &"plot_course")).is_equal(DiveSimulation.STEP_PENDING)
	sim.set_course(0.0, 90.0)
	sim.advance(1.0)
	assert_str(DiveTestKit.step_state(sim, &"plot_course")).is_equal(DiveSimulation.STEP_DONE)

	assert_str(DiveTestKit.next_step_id(sim)).is_equal(&"drive_autopilot")
	sim.set_autopilot(DiveSimulation.STATION_DRIVE, true)
	sim.advance(1.0)
	assert_str(DiveTestKit.step_state(sim, &"drive_autopilot")).is_equal(DiveSimulation.STEP_DONE)
	assert_int(sim.checklist_phase()).is_equal(1)


func test_the_checklist_moves_on_once_under_way_even_with_the_orders_unread() -> void:
	var sim := _first_dive_on(_short_first_dive())
	sim.set_autopilot(DiveSimulation.STATION_DRIVE, true)
	sim.advance(0.1)
	assert_int(sim.checklist_phase()).is_equal(0)
	assert_bool(_fly_until(sim, func(s: DiveSimulation) -> bool: return s.checklist_phase() == 1, 600.0, 0.5)).is_true()
	assert_float(sim.depth()).is_greater(sim.vessel_length())
	assert_str(DiveTestKit.step_state(sim, &"read_orders")).is_equal(DiveSimulation.STEP_MISSED)
	assert_str(DiveTestKit.next_step_id(sim)).is_equal(&"pulse")


## A first dive on the short layout with its startup done: the Reactor's and
## Thermal's autopilots engaged, the Course a dive, the Drive's autopilot on.
func _started() -> DiveSimulation:
	var sim := _first_dive_on(_short_first_dive())
	sim.read_orders()
	sim.advance(0.1)
	sim.set_autopilot(DiveSimulation.STATION_REACTOR, true)
	sim.advance(0.1)
	sim.set_autopilot(DiveSimulation.STATION_THERMAL, true)
	sim.advance(0.1)
	sim.set_course(0.0, 90.0)
	sim.advance(0.1)
	sim.set_autopilot(DiveSimulation.STATION_DRIVE, true)
	sim.advance(0.1)
	return sim


func test_the_sand_steps_tick_as_each_is_done() -> void:
	var sim := _started()
	assert_str(DiveTestKit.next_step_id(sim)).is_equal(&"pulse")
	sim.pulse()
	sim.advance(0.1)
	assert_str(DiveTestKit.step_state(sim, &"pulse")).is_equal(DiveSimulation.STEP_DONE)

	# A pulse with the vessel running is not a Quiet Ship scan.
	assert_str(DiveTestKit.next_step_id(sim)).is_equal(&"quiet_scan")
	sim.pulse()
	sim.advance(0.1)
	assert_str(DiveTestKit.step_state(sim, &"quiet_scan")).is_equal(DiveSimulation.STEP_PENDING)
	sim.set_quiet_ship(true)
	sim.advance(0.1)
	sim.pulse()
	sim.advance(0.1)
	assert_str(DiveTestKit.step_state(sim, &"quiet_scan")).is_equal(DiveSimulation.STEP_DONE)

	assert_str(DiveTestKit.next_step_id(sim)).is_equal(&"quiet_off")
	sim.advance(1.0)
	assert_str(DiveTestKit.step_state(sim, &"quiet_off")).is_equal(DiveSimulation.STEP_PENDING)
	sim.set_quiet_ship(false)
	sim.advance(0.1)
	assert_str(DiveTestKit.step_state(sim, &"quiet_off")).is_equal(DiveSimulation.STEP_DONE)

	assert_str(DiveTestKit.next_step_id(sim)).is_equal(&"observe")
	assert_bool(_fly_until(sim, func(s: DiveSimulation) -> bool: return not s.features_in_column().is_empty(), 600.0, 0.5)).is_true()
	assert_str(DiveTestKit.step_state(sim, &"observe")).is_equal(DiveSimulation.STEP_PENDING)
	sim.set_observed_feature(sim.features_in_column()[0].id)
	sim.advance(0.1)
	assert_str(DiveTestKit.step_state(sim, &"observe")).is_equal(DiveSimulation.STEP_DONE)


## The sand steps done too, on a dive from _started().
func _through_the_sand() -> DiveSimulation:
	var sim := _started()
	sim.pulse()
	sim.advance(0.1)
	sim.set_quiet_ship(true)
	sim.advance(0.1)
	sim.pulse()
	sim.advance(0.1)
	sim.set_quiet_ship(false)
	sim.advance(0.1)
	_fly_until(sim, func(s: DiveSimulation) -> bool: return not s.features_in_column().is_empty(), 600.0, 0.5)
	sim.set_observed_feature(sim.features_in_column()[0].id)
	sim.advance(0.1)
	return sim


func test_the_first_boundary_begins_as_it_approaches_and_wants_the_dial_ready_then_a_shift() -> void:
	var sim := _through_the_sand()
	var seen := []
	assert_dict(DiveTestKit.run_until(sim, &"boundary_approaching", 600.0, seen, 0.5)).is_not_empty()
	sim.advance(0.1)
	assert_str(sim.checklist()[sim.checklist_phase()].title).is_equal(Scenario.first_dive().phases[2].title)
	# The dial still holds the sand's wobble: not ready for the sandstone.
	assert_str(DiveTestKit.next_step_id(sim)).is_equal(&"ready_dial")
	assert_str(DiveTestKit.step_state(sim, &"ready_dial")).is_equal(DiveSimulation.STEP_PENDING)
	sim.set_shift_dial(_wobble_in(Medium.sandstone()))
	sim.advance(0.1)
	assert_str(DiveTestKit.step_state(sim, &"ready_dial")).is_equal(DiveSimulation.STEP_DONE)

	assert_str(DiveTestKit.next_step_id(sim)).is_equal(&"shift")
	assert_dict(DiveTestKit.run_until(sim, &"boundary_crossed", 600.0, [], 0.1)).is_not_empty()
	assert_str(DiveTestKit.step_state(sim, &"shift")).is_equal(DiveSimulation.STEP_PENDING)
	sim.shift(sim.shift_dial())
	sim.advance(0.1)
	assert_str(DiveTestKit.step_state(sim, &"shift")).is_equal(DiveSimulation.STEP_DONE)
	assert_str(sim.checklist()[sim.checklist_phase()].title).is_equal(Scenario.first_dive().phases[3].title)


func test_a_shift_the_autopilot_makes_is_not_the_crews() -> void:
	var sim := _through_the_sand()
	assert_bool(_fly_until(sim, func(s: DiveSimulation) -> bool: return s.medium().name == &"sandstone", 2000.0, 0.5)).is_true()
	# The Reactor's autopilot Shifts late; the crew never did.
	assert_bool(_fly_until(sim, func(s: DiveSimulation) -> bool: return not s.shift_due(), 2000.0, 0.5)).is_true()
	sim.advance(0.1)
	assert_str(DiveTestKit.step_state(sim, &"shift")).is_equal(DiveSimulation.STEP_MISSED)
	assert_str(sim.checklist()[sim.checklist_phase()].title).is_equal(Scenario.first_dive().phases[3].title)


## A dive from _through_the_sand() made through the first Boundary: the dial
## readied and a Shift on it as the Head crosses.
func _into_the_sandstone() -> DiveSimulation:
	var sim := _through_the_sand()
	DiveTestKit.run_until(sim, &"boundary_approaching", 600.0, [], 0.5)
	sim.set_shift_dial(_wobble_in(Medium.sandstone()))
	sim.advance(0.1)
	DiveTestKit.run_until(sim, &"boundary_crossed", 600.0, [], 0.1)
	sim.shift(sim.shift_dial())
	sim.advance(0.1)
	return sim


func test_the_sandstone_and_granite_steps_tick_as_each_is_done() -> void:
	var sim := _into_the_sandstone()
	assert_str(DiveTestKit.next_step_id(sim)).is_equal(&"observe_sandstone")
	# Observing nothing: no feature in the sandstone yet. The link is stopped,
	# so the step after this one cannot tick with it.
	sim.set_observed_feature(-1)
	sim.set_uploading(false)
	sim.advance(0.1)
	assert_str(DiveTestKit.step_state(sim, &"observe_sandstone")).is_equal(DiveSimulation.STEP_PENDING)
	assert_bool(_fly_until(sim, func(s: DiveSimulation) -> bool: return not s.features_in_column().is_empty(), 2000.0, 0.5)).is_true()
	sim.set_observed_feature(sim.features_in_column()[0].id)
	sim.advance(0.1)
	assert_str(DiveTestKit.step_state(sim, &"observe_sandstone")).is_equal(DiveSimulation.STEP_DONE)

	# The link sends what is aboard while the tunnel is open; stopped, it
	# cannot.
	assert_str(DiveTestKit.next_step_id(sim)).is_equal(&"upload")
	DiveTestKit.run(sim, 20.0)
	assert_str(DiveTestKit.step_state(sim, &"upload")).is_equal(DiveSimulation.STEP_PENDING)
	sim.set_uploading(true)
	assert_bool(_fly_until(sim, func(s: DiveSimulation) -> bool: return s.unsold_survey().is_empty(), 600.0, 0.5)).is_true()
	sim.advance(0.1)
	assert_str(DiveTestKit.step_state(sim, &"upload")).is_equal(DiveSimulation.STEP_DONE)

	assert_str(DiveTestKit.next_step_id(sim)).is_equal(&"ready_dial_granite")
	sim.set_shift_dial(_wobble_in(Medium.sand()))
	sim.advance(0.1)
	assert_str(DiveTestKit.step_state(sim, &"ready_dial_granite")).is_equal(DiveSimulation.STEP_PENDING)
	sim.set_shift_dial(_wobble_in(Medium.granite()))
	sim.advance(0.1)
	assert_str(DiveTestKit.step_state(sim, &"ready_dial_granite")).is_equal(DiveSimulation.STEP_DONE)

	assert_str(DiveTestKit.next_step_id(sim)).is_equal(&"shift_granite")
	assert_bool(DiveTestKit.achieved(sim, &"into_the_granite")).is_false()
	assert_dict(DiveTestKit.run_until(sim, &"boundary_crossed", 3000.0, [], 0.1)).is_not_empty()
	sim.advance(0.1)
	assert_bool(DiveTestKit.achieved(sim, &"into_the_granite")).is_true()
	assert_str(DiveTestKit.step_state(sim, &"shift_granite")).is_equal(DiveSimulation.STEP_PENDING)
	sim.shift(sim.shift_dial())
	sim.advance(0.1)
	assert_str(DiveTestKit.step_state(sim, &"shift_granite")).is_equal(DiveSimulation.STEP_DONE)

	assert_str(DiveTestKit.next_step_id(sim)).is_equal(&"observe_granite")
	assert_bool(_fly_until(sim, func(s: DiveSimulation) -> bool: return not s.features_in_column().is_empty(), 3000.0, 0.5)).is_true()
	sim.set_observed_feature(sim.features_in_column()[0].id)
	sim.advance(0.1)
	assert_str(DiveTestKit.step_state(sim, &"observe_granite")).is_equal(DiveSimulation.STEP_DONE)
	assert_str(DiveTestKit.next_step_id(sim)).is_equal(&"plot_climb")


func test_turning_for_home_ticks_on_the_climb_and_surfacing_on_the_pay() -> void:
	# In sand all the way, so the arc home is quick; plotting the climb
	# begins the turn whatever came before.
	var sim := _first_dive_on(MediumLayout.uniform(Medium.sand()))
	sim.set_autopilot(DiveSimulation.STATION_THERMAL, true)
	sim.set_power(0.5)
	sim.set_steering_effort(1.0)
	DiveTestKit.run(sim, 20.0)
	assert_str(DiveTestKit.step_state(sim, &"plot_climb")).is_equal(DiveSimulation.STEP_PENDING)
	sim.set_course(0.0, -90.0)
	sim.advance(0.1)
	assert_str(DiveTestKit.step_state(sim, &"plot_climb")).is_equal(DiveSimulation.STEP_DONE)
	assert_str(DiveTestKit.step_state(sim, &"read_orders")).is_equal(DiveSimulation.STEP_MISSED)

	assert_str(DiveTestKit.next_step_id(sim)).is_equal(&"climbing")
	assert_bool(_fly_until(sim, func(s: DiveSimulation) -> bool: return s.pitch() < 45.0, 3000.0)).is_true()
	assert_str(DiveTestKit.step_state(sim, &"climbing")).is_equal(DiveSimulation.STEP_PENDING)
	assert_bool(_fly_until(sim, func(s: DiveSimulation) -> bool: return DiveTestKit.step_state(s, &"climbing") == DiveSimulation.STEP_DONE, 3000.0)).is_true()
	assert_float(sim.pitch()).is_less(0.0)

	assert_str(DiveTestKit.next_step_id(sim)).is_equal(&"paid")
	assert_bool(DiveTestKit.achieved(sim, &"surfaced")).is_false()
	assert_bool(_fly_until(sim, func(s: DiveSimulation) -> bool: return s.surfaced(), 6000.0)).is_true()
	assert_str(DiveTestKit.step_state(sim, &"paid")).is_equal(DiveSimulation.STEP_DONE)
	assert_bool(DiveTestKit.achieved(sim, &"surfaced")).is_true()


# --- Goals ---------------------------------------------------------------

func test_every_goal_starts_not_yet_achieved() -> void:
	var sim := Scenario.first_dive().start()
	sim.advance(1.0)
	for goal in sim.orders():
		assert_str(goal.text).is_not_empty()
		assert_bool(goal.achieved).is_false()


func test_the_survey_goal_is_achieved_once_the_link_has_been_paid() -> void:
	var sim := _first_dive_on(MediumLayout.uniform(Medium.sand()))
	sim.set_power(0.5)
	# Not before anything reaches the surface.
	assert_bool(DiveTestKit.achieved(sim, &"survey_paid")).is_false()
	assert_bool(_fly_until(sim, func(s: DiveSimulation) -> bool: return s.paid_this_dive() > 0.0, 600.0, 0.5)).is_true()
	sim.advance(0.1)
	assert_bool(DiveTestKit.achieved(sim, &"survey_paid")).is_true()


func test_a_goal_once_achieved_stays_achieved() -> void:
	# Granite at the top, sand under it: the goal is met at once, then left.
	var sim := _first_dive_on(MediumLayout.layered([[0.0, Medium.granite()], [3.0, Medium.sand()]]))
	sim.advance(0.1)
	assert_bool(DiveTestKit.achieved(sim, &"into_the_granite")).is_true()
	sim.set_power(0.5)
	assert_bool(_fly_until(sim, func(s: DiveSimulation) -> bool: return s.medium().name == &"sand", 600.0, 0.5)).is_true()
	sim.advance(0.1)
	assert_bool(DiveTestKit.achieved(sim, &"into_the_granite")).is_true()


# --- Surface control's messages -------------------------------------------

## Seconds from the moment `sent` first holds to the message's arrival, on a
## dive in `layout` at full power, or INF if it never arrives.
static func _message_delay(layout: MediumLayout, sent: Callable) -> float:
	var sim := DiveSimulation.new(layout)
	var scenario := Scenario.new()
	scenario.messages.append(Scenario.Message.new(
			"Surface control here. We hear you, and we are watching the link.", sent))
	sim.set_scenario(scenario)
	sim.set_power(1.0)
	var sent_at := INF
	var seconds := 0.0
	while seconds < 20000.0:
		if is_inf(sent_at) and sent.call(sim, []):
			sent_at = seconds
		sim.advance(0.5)
		seconds += 0.5
		for event in sim.take_events():
			if event.type == &"surface_message":
				return seconds - sent_at
	return INF


func test_surface_messages_arrive_later_once_sealed_in_than_while_the_tunnel_is_open() -> void:
	var sealing := MediumLayout.layered([[0.0, Medium.sand()], [5.0, DiveTestKit.rock()]])
	var when_sealed := func(s: DiveSimulation, _e: Array) -> bool: return s.tunnel_sealed()
	var at_once := func(_s: DiveSimulation, _e: Array) -> bool: return true
	var sealed_delay := _message_delay(sealing, when_sealed)
	var open_delay := _message_delay(sealing, at_once)
	assert_float(open_delay).is_less(INF)
	assert_float(sealed_delay).is_less(INF)
	assert_float(sealed_delay).is_greater(open_delay * 10.0)


func test_a_message_is_not_shown_before_it_has_arrived() -> void:
	var sim := DiveSimulation.new(MediumLayout.layered([[0.0, Medium.sand()], [5.0, DiveTestKit.rock()]]))
	var scenario := Scenario.new()
	scenario.messages.append(Scenario.Message.new("A long way down the rock to you.",
			func(s: DiveSimulation, _e: Array) -> bool: return s.tunnel_sealed()))
	sim.set_scenario(scenario)
	sim.set_power(1.0)
	assert_bool(_fly_until(sim, func(s: DiveSimulation) -> bool: return s.tunnel_sealed(), 600.0, 0.5)).is_true()
	sim.advance(0.5)
	assert_array(sim.surface_messages()).is_empty()
	assert_int(sim.messages_on_the_way()).is_equal(1)


func test_the_first_dive_opens_with_its_orders_from_surface_control() -> void:
	var sim := Scenario.first_dive().start()
	DiveTestKit.run(sim, 10.0)
	assert_array(sim.surface_messages()).is_not_empty()
	assert_int(sim.messages_on_the_way()).is_equal(0)


func test_an_event_taken_before_the_checklist_saw_it_still_counts() -> void:
	var sim := _first_dive_on(_short_first_dive())
	sim.read_orders()
	sim.take_events()
	sim.advance(0.1)
	assert_str(DiveTestKit.step_state(sim, &"read_orders")).is_equal(DiveSimulation.STEP_DONE)
