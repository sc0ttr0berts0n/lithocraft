# The Checklist follower: the First dive played by doing only what the
# Checklist says. It reads the Checklist's next step, sends the command that
# step names, and steps time until the step ticks. This is the play-test bar
# held by a machine: finished cold, surfaced and paid, from the Checklist
# alone (ticket #73). Tested at the simulation's interface; it asserts
# relationships, never tuned constants (ADR 0001).
extends GdUnitTestSuite

const _Habitat := preload("res://view/habitat.gd")

## Seconds of advance() between looks at the Checklist: how soon the follower
## acts on what it sees. A test value.
const LOOK_S := 0.5
## Simulated seconds a step is given to tick before the follower gives up on
## it, unless its entry in the table sets its own `limit`. A test value, far
## longer than any step of a dive that goes well.
const STEP_LIMIT_S := 20000.0

## The First dive followed with no key pressed first, flown once and shared by
## the tests that only read it.
var _followed := {}


# --- How each kind of step is followed --------------------------------------
#
# Each is called before every look while its step is the Checklist's next, so
# each sends its command only when the crew would: once, or when what the
# crew can see says it is time. Each sends what its step's key does
# (view/habitat.gd, `_key_<action>`), through the simulation's interface.

## Tab: opening the Checklist reads the Orders.
static func _read_orders(sim: DiveSimulation) -> void:
	sim.read_orders()


## E at a Station: its autopilot's switch, pressed if it is off.
static func _engage(sim: DiveSimulation, station: StringName) -> void:
	if not sim.autopilot(station):
		sim.set_autopilot(station, true)


## 1 or 3 at Navigation: the Course's pitch plotted outright, the heading left
## as it is.
static func _plot_pitch(sim: DiveSimulation, pitch: float) -> void:
	sim.set_course(sim.course_heading(), pitch)


## P at Navigation: one pulse.
static func _pulse(sim: DiveSimulation) -> void:
	sim.pulse()


## Q at Navigation, then P once the vessel is still and silent: the step's own
## words, "Quiet Ship, then pulse again".
static func _quiet_scan(sim: DiveSimulation) -> void:
	if not sim.quiet_ship():
		sim.set_quiet_ship(true)
	elif sim.speed() == 0.0 and sim.noise() == 0.0:
		sim.pulse()


## Q at Navigation again: Quiet Ship off.
static func _quiet_off(sim: DiveSimulation) -> void:
	if sim.quiet_ship():
		sim.set_quiet_ship(false)


## F at the Bore Station: observe the next feature in the Column not yet
## recorded, once one is there and none is being observed.
static func _observe(sim: DiveSimulation) -> void:
	if sim.observed_feature() >= 0:
		return
	for feature in sim.features_in_column():
		if not feature.is_recorded():
			sim.set_observed_feature(feature.id)
			return


## The Reactor's two tuning controls, on the channel selected (STANDBY, where
## every dive starts and a Shift leaves it): set to the scan's guess of the
## Wobble ahead, which is what the crew can see. With no guess there is
## nothing to tune to.
static func _pretune(sim: DiveSimulation) -> void:
	var guess := DiveTestKit.wobble_ahead(sim)
	if is_nan(guess.x) or is_nan(guess.y):
		return
	sim.tune_frequency(guess.x)
	sim.tune_amplitude(guess.y)


## R at the Reactor, once the Head is in the Medium the step names: "as the
## Head crosses".
static func _shift_in(sim: DiveSimulation, medium_name: StringName) -> void:
	if sim.medium().name == medium_name:
		sim.shift()


## B at the Bore Station: the link started if it is stopped.
static func _link(sim: DiveSimulation) -> void:
	if not sim.uploading():
		sim.set_uploading(true)


## A step that names no key: the crew waits for the Lithocraft to do it.
static func _wait(_sim: DiveSimulation) -> void:
	pass


## The follower's table for the First dive: for each Checklist step, by id,
## the key-map action its command belongs to (it must be the one the step
## names) and how it is followed (`follow`, called with the simulation before
## every look while the step is next). A step with no entry here fails the
## follower by name, so a new step cannot be added without saying how it is
## followed.
static func _first_dive_table() -> Dictionary:
	var layout := MediumLayout.first_dive()
	var boundaries := layout.boundary_depths()
	var middle := layout.medium_at(boundaries[0] + 0.01).name
	var bottom := layout.medium_at(boundaries[1] + 0.01).name
	return {
		&"read_orders": {action = &"toggle_checklist", follow = _read_orders},
		&"reactor_autopilot": {action = &"autopilot_reactor", follow = _engage.bind(DiveSimulation.STATION_REACTOR)},
		&"thermal_autopilot": {action = &"autopilot_thermal", follow = _engage.bind(DiveSimulation.STATION_THERMAL)},
		&"plot_course": {action = &"plot_pitch", follow = _plot_pitch.bind(_Habitat.PITCHES[0])},
		&"drive_autopilot": {action = &"autopilot_drive", follow = _engage.bind(DiveSimulation.STATION_DRIVE)},
		&"pulse": {action = &"pulse", follow = _pulse},
		&"quiet_scan": {action = &"quiet_ship", follow = _quiet_scan},
		&"quiet_off": {action = &"quiet_ship", follow = _quiet_off},
		&"observe": {action = &"observe", follow = _observe},
		&"pretune_standby": {action = &"tune_frequency", follow = _pretune},
		&"shift": {action = &"shift", follow = _shift_in.bind(middle)},
		&"observe_sandstone": {action = &"observe", follow = _observe},
		&"upload": {action = &"link", follow = _link},
		&"pretune_standby_granite": {action = &"tune_frequency", follow = _pretune},
		&"shift_granite": {action = &"shift", follow = _shift_in.bind(bottom)},
		&"observe_granite": {action = &"observe", follow = _observe},
		&"plot_climb": {action = &"plot_pitch", follow = _plot_pitch.bind(_Habitat.PITCHES[2])},
		&"climbing": {action = &"", follow = _wait},
		&"paid": {action = &"", follow = _wait},
	}


# --- The follower -------------------------------------------------------------

## Plays this dive by its Checklist alone: reads the next step, has the
## table's entry for it send its command, and steps time until the step ticks,
## time run fast between calls as the crew's own time key does (it is no
## Station's command). Stops when the Checklist has no step left, or at the
## first thing that fails the follower, which `failure` then says: a step with
## no entry in `table` (named), an entry whose action is not the one its step
## names, a step that did not tick within its time limit (named, with its
## phase), a step missed because a later phase began before it ticked (named,
## with both phases), or a dive that ended or went dark with a step still to
## do. Returns
## {sim, events, failure}; `failure` is "" for a Checklist followed to its end.
static func _follow(sim: DiveSimulation, table: Dictionary) -> Dictionary:
	var events := []
	var current := &""
	var waited := 0.0
	var failure := ""
	while failure.is_empty():
		var step := sim.next_step()
		if step.is_empty():
			break
		var id: StringName = step.id
		var where := "step \"%s\" of the phase \"%s\"" % [id, DiveTestKit.phase_title(sim)]
		if id != current:
			current = id
			waited = 0.0
		if not table.has(id):
			failure = "The follower's table has no entry for the Checklist step \"%s\"" % id
		elif table[id].action != step.action:
			failure = "The follower's entry for the %s sends \"%s\", but the step names \"%s\"" % [
					where, table[id].action, step.action]
		elif sim.dead() or sim.plasma_lost() or sim.surfaced():
			failure = "The dive ended or went dark at %.0f m with the %s still to do (%s)" % [
					sim.depth(), where, "dead" if sim.dead() else "plasma lost" if sim.plasma_lost() else "surfaced"]
		elif waited >= table[id].get("limit", STEP_LIMIT_S):
			failure = "The %s did not tick within its time limit of %.0f s (at %.0f m, in %s)" % [
					where, table[id].get("limit", STEP_LIMIT_S), sim.depth(), sim.medium().name]
		else:
			table[id].follow.call(sim)
			sim.set_time_rate(sim.max_time_rate())
			waited += LOOK_S * sim.time_rate()
			sim.advance(LOOK_S)
			for event in sim.take_events():
				events.append(event)
				if failure.is_empty() and event.type == &"checklist_step" and event.state == DiveSimulation.STEP_MISSED:
					failure = "The step \"%s\" of the phase \"%s\" was missed: the phase \"%s\" began with it still to do (at %.0f m, in %s)" % [
							event.id, sim.checklist()[event.phase].title, DiveTestKit.phase_title(sim), sim.depth(), sim.medium().name]
	return {sim = sim, events = events, failure = failure}


## The First dive followed from its start, after `first` (the one wrong key,
## if any) is sent to it.
static func _follow_the_first_dive(first := Callable()) -> Dictionary:
	var sim := Scenario.first_dive().start()
	if first.is_valid():
		first.call(sim)
	return _follow(sim, _first_dive_table())


func _followed_dive() -> Dictionary:
	if _followed.is_empty():
		_followed = _follow_the_first_dive()
	return _followed


## Every step id of this Scenario's Checklist, in order.
static func _step_ids(scenario: Scenario) -> Array:
	var ids := []
	for phase in scenario.phases:
		for step in phase.steps:
			ids.append(step.id)
	return ids


## Asserts this followed dive is the play-test bar met: the Checklist followed
## to its end, every step ticked in order and none missed, the Lithocraft
## surfaced and paid with the Orders achieved. `named` says which dive in a
## failure.
func _assert_finished_from_the_checklist_alone(dive: Dictionary, named: String) -> void:
	var sim: DiveSimulation = dive.sim
	var events: Array = dive.events
	assert_str(dive.failure).override_failure_message("%s: %s" % [named, dive.failure]).is_empty()
	# Every step ticked, in the Checklist's own order, and none was missed.
	var steps := events.filter(func(e: Dictionary) -> bool: return e.type == &"checklist_step")
	var missed := steps.filter(func(e: Dictionary) -> bool: return e.state != DiveSimulation.STEP_DONE)
	assert_array(missed.map(func(e: Dictionary) -> StringName: return e.id)) \
			.override_failure_message("%s: steps not ticked: %s" % [named, missed]).is_empty()
	assert_array(steps.map(func(e: Dictionary) -> StringName: return e.id)) \
			.append_failure_message(named).is_equal(_step_ids(Scenario.first_dive()))
	# Surfaced under its own power, and paid.
	assert_bool(sim.surfaced()).append_failure_message(named).is_true()
	assert_bool(sim.plasma_lost()).append_failure_message(named).is_false()
	assert_bool(sim.dead()).append_failure_message(named).is_false()
	assert_array(DiveTestKit.types(events)).append_failure_message(named).contains([&"surfaced", &"paid"])
	assert_float(sim.paid()).append_failure_message(named).is_greater(0.0)
	for goal in sim.orders():
		assert_bool(goal.achieved).override_failure_message("%s: the goal \"%s\" was not achieved" % [named, goal.id]).is_true()


# --- The Course keys the Checklist does not ask for ------------------------
#
# At Navigation on the surface the Checklist asks for one Course key, dive.
# These are the others, each as its key sends it (view/habitat.gd).

## Z or X at Navigation: the Course's pitch one step up (`direction` -1) or
## down (+1).
static func _step_pitch(sim: DiveSimulation, direction: float) -> void:
	sim.set_course(sim.course_heading(), sim.course_pitch() + direction * _Habitat.PITCH_STEP)


## J or L at Navigation: the Course's heading one step left (`direction` -1)
## or right (+1).
static func _step_heading(sim: DiveSimulation, direction: float) -> void:
	sim.set_course(sim.course_heading() + direction * _Habitat.HEADING_STEP, sim.course_pitch())


## Every Course key the Checklist does not ask for at the surface, by name.
static func _unasked_course_keys() -> Dictionary:
	return {
		"level": _plot_pitch.bind(_Habitat.PITCHES[1]),
		"climb": _plot_pitch.bind(_Habitat.PITCHES[2]),
		"pitch up a step": _step_pitch.bind(-1.0),
		"pitch down a step": _step_pitch.bind(1.0),
		"heading left a step": _step_heading.bind(-1.0),
		"heading right a step": _step_heading.bind(1.0),
	}


# --- Tests --------------------------------------------------------------------

func test_following_the_checklist_and_nothing_else_the_first_dive_ends_surfaced_and_paid() -> void:
	_assert_finished_from_the_checklist_alone(_followed_dive(), "Following the Checklist alone")


func test_one_unasked_course_key_at_the_surface_first_and_the_checklist_still_finishes_the_dive() -> void:
	var keys := _unasked_course_keys()
	for key in keys:
		var dive := _follow_the_first_dive(keys[key])
		# The key was a Course plotted before anything the Checklist asked for.
		assert_str(dive.events[0].type).is_equal(&"course_plotted")
		_assert_finished_from_the_checklist_alone(dive, "With the Course key \"%s\" pressed first" % key)


func test_the_follower_has_an_entry_for_every_step_of_the_first_dive_and_no_other() -> void:
	var ids := _step_ids(Scenario.first_dive())
	var entries := _first_dive_table().keys()
	ids.sort()
	entries.sort()
	assert_array(entries).is_equal(ids)


func test_a_step_with_no_entry_in_the_table_fails_the_follower_by_name() -> void:
	var scenario := Scenario.first_dive()
	for id in [scenario.phases[0].steps[0].id, scenario.phases[1].steps[0].id]:
		var table := _first_dive_table()
		table.erase(id)

		var dive := _follow(scenario.start(), table)

		assert_str(dive.failure).contains("no entry").contains("\"%s\"" % id)
		# It stopped there: the step is still the next to do.
		assert_str(DiveTestKit.next_step_id(dive.sim)).is_equal(id)


func test_an_entry_that_sends_another_command_than_its_step_names_fails_the_follower() -> void:
	var table := _first_dive_table()
	var first: Scenario.Step = Scenario.first_dive().phases[0].steps[0]
	table[first.id] = {action = &"pulse", follow = _pulse}

	var dive := _follow(Scenario.first_dive().start(), table)

	assert_str(dive.failure).contains("\"%s\"" % first.id).contains("\"pulse\"").contains("\"%s\"" % first.action)
	assert_int(dive.sim.pulses_sent()).is_equal(0)


func test_a_step_that_does_not_tick_within_its_time_limit_fails_naming_the_step_and_the_phase() -> void:
	# The first step never done, so the Lithocraft never leaves the surface
	# and no later phase can begin: the step stays the next to do.
	var scenario := Scenario.first_dive()
	var first: Scenario.Step = scenario.phases[0].steps[0]
	var table := _first_dive_table()
	table[first.id] = {action = first.action, follow = _wait, limit = 60.0}

	var dive := _follow(scenario.start(), table)

	assert_str(dive.failure).contains("time limit").contains("\"%s\"" % first.id) \
			.contains("\"%s\"" % scenario.phases[0].title)
	# It was given its own limit, not the far longer one every other step has.
	assert_float(dive.sim.dive_time()).is_greater_equal(60.0)
	assert_float(dive.sim.dive_time()).is_less(STEP_LIMIT_S)
	assert_str(DiveTestKit.next_step_id(dive.sim)).is_equal(first.id)

