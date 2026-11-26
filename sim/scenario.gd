## A Scenario: a dive chosen to be played, with its own layout, start state,
## Orders and Checklist. Plain data: the conditions are Callables that read
## the simulation through its public interface only, so a Scenario can be
## written without touching DiveSimulation. DiveSimulation keeps the progress
## (Checklist); see set_scenario() and docs/conventions.md, "Scenarios".
##
## Every condition is a Callable(sim: DiveSimulation, events: Array) -> bool:
## `events` are those raised since it was last asked. Build them with when()
## (a state of the simulation) or on_event() (an event, optionally matching).
class_name Scenario
extends RefCounted

## How near the Shift dial must be to the wobble ahead, as a share of it, for
## the dial to count as ready. Tuned for play (ADR 0001): a few presses of the
## dial wide still counts, so the crew learn the meter, not a number.
const _DIAL_READY := 0.03


## A goal of the Orders, achieved once its condition has held.
class Goal:
	extends RefCounted
	var id: StringName
	var text: String
	var achieved_when: Callable

	func _init(p_id: StringName, p_text: String, p_achieved_when: Callable) -> void:
		id = p_id
		text = p_text
		achieved_when = p_achieved_when


## A step of the Checklist: what to do, at which Station (one of
## DiveSimulation.STATIONS, or &"" for none), the key-map action that does it
## (&"" for none), and when the simulation sees it done.
class Step:
	extends RefCounted
	var id: StringName
	var text: String
	var station: StringName
	var action: StringName
	var done_when: Callable

	func _init(p_id: StringName, p_text: String, p_station: StringName,
			p_action: StringName, p_done_when: Callable) -> void:
		id = p_id
		text = p_text
		station = p_station
		action = p_action
		done_when = p_done_when


## A phase of the Checklist: its steps in order, and what begins it early
## (an invalid Callable: only finishing the phase before does).
class Phase:
	extends RefCounted
	var title: String
	var steps: Array[Step] = []
	var begins_when: Callable

	func _init(p_title: String, p_begins_when := Callable()) -> void:
		title = p_title
		begins_when = p_begins_when


## A message surface control sends down the link once its condition holds.
class Message:
	extends RefCounted
	var text: String
	var sent_when: Callable

	func _init(p_text: String, p_sent_when: Callable) -> void:
		text = p_text
		sent_when = p_sent_when


var title := ""
## The world the Scenario's dives are in.
var layout: MediumLayout = null
var orders: Array[Goal] = []
var phases: Array[Phase] = []
var messages: Array[Message] = []
## The start state: called with the simulation at the start of each of the
## Scenario's dives, after the Checklist is set up. Does nothing by default.
var prepare := func(_sim: DiveSimulation) -> void: pass


## A new dive in this Scenario: its layout, its Orders and Checklist, its
## start state.
func start() -> DiveSimulation:
	var sim := DiveSimulation.new(layout)
	sim.set_scenario(self)
	return sim


# --- Conditions ------------------------------------------------------------

## A condition that holds while `predicate(sim)` does.
static func when(predicate: Callable) -> Callable:
	return func(sim: DiveSimulation, _events: Array) -> bool: return predicate.call(sim)


## A condition that holds when an event of this type was raised, and
## `matches(event, sim)` holds of it (any event of the type, if not given).
static func on_event(type: StringName, matches := Callable()) -> Callable:
	return func(sim: DiveSimulation, events: Array) -> bool:
		for event in events:
			if event.type == type and (not matches.is_valid() or matches.call(event, sim)):
				return true
		return false


## Holds while the Shift dial is within _DIAL_READY of the wobble in `medium`.
static func dial_ready_for(medium: Medium) -> Callable:
	var wobble := Plasma.frequency_in(medium)
	return when(func(sim: DiveSimulation) -> bool:
		return absf(sim.shift_dial() / wobble - 1.0) <= _DIAL_READY)


## Holds while the Head is in a Medium of this name.
static func in_medium(medium_name: StringName) -> Callable:
	return when(func(sim: DiveSimulation) -> bool: return sim.medium().name == medium_name)


## Holds while the Bore Station observes a feature with the Head in a Medium
## of this name.
static func observing_in(medium_name: StringName) -> Callable:
	return when(func(sim: DiveSimulation) -> bool:
		return sim.observed_feature() >= 0 and sim.medium().name == medium_name)


## Holds on a Shift the crew made (not an autopilot's) with the Head in a
## Medium of this name.
static func crew_shift_in(medium_name: StringName) -> Callable:
	return on_event(&"shift_result", func(event: Dictionary, sim: DiveSimulation) -> bool:
		return not event.autopilot and sim.medium().name == medium_name)


## Holds on a Shift of any kind with the Head in a Medium of this name.
static func any_shift_in(medium_name: StringName) -> Callable:
	return on_event(&"shift_result", func(_event: Dictionary, sim: DiveSimulation) -> bool:
		return sim.medium().name == medium_name)


## Holds when the Course is plotted downward (`down`) or upward.
static func course_plotted(down: bool) -> Callable:
	return on_event(&"course_plotted", func(event: Dictionary, _sim: DiveSimulation) -> bool:
		return event.pitch > 0.0 if down else event.pitch < 0.0)


# --- The Scenarios -----------------------------------------------------------

## The First dive: from the desert surface down through the sandstone into
## the granite, and home with the data. Its Media are read from its layout,
## shallowest first, so the steps follow the layout's own order.
static func first_dive() -> Scenario:
	var s := Scenario.new()
	s.title = "First dive"
	s.layout = MediumLayout.first_dive()
	var boundaries := s.layout.boundary_depths()
	var top := s.layout.medium_at(0.0)
	var middle := s.layout.medium_at(boundaries[0] + 0.01)
	var bottom := s.layout.medium_at(boundaries[1] + 0.01)

	s.orders = [
		Goal.new(&"into_the_granite", "Survey down through the %s into the %s" % [middle.name, bottom.name],
				in_medium(bottom.name)),
		Goal.new(&"survey_paid", "Be paid for survey: uploaded, or brought home",
				when(func(sim: DiveSimulation) -> bool: return sim.paid_this_dive() > 0.0)),
		Goal.new(&"surfaced", "Surface with the data", on_event(&"surfaced")),
	]

	var startup := Phase.new("Startup")
	startup.steps = [
		Step.new(&"read_orders", "Read the orders", &"", &"toggle_checklist", on_event(&"orders_read")),
		Step.new(&"reactor_autopilot", "Engage the Reactor's autopilot", DiveSimulation.STATION_REACTOR,
				&"autopilot_reactor", _autopilot_on(DiveSimulation.STATION_REACTOR)),
		Step.new(&"thermal_autopilot", "Engage Thermal's autopilot", DiveSimulation.STATION_THERMAL,
				&"autopilot_thermal", _autopilot_on(DiveSimulation.STATION_THERMAL)),
		Step.new(&"plot_course", "Plot the Course: dive", DiveSimulation.STATION_NAVIGATION,
				&"plot_pitch", course_plotted(true)),
		Step.new(&"drive_autopilot", "Engage the Drive's autopilot: it follows the Course, slow and safe",
				DiveSimulation.STATION_DRIVE, &"autopilot_drive", _autopilot_on(DiveSimulation.STATION_DRIVE)),
	]

	# Under way once the whole vessel is below the surface, startup done or
	# not: the checklist moves on with the dive rather than wait for Tab.
	var sand := Phase.new(String(top.name).capitalize(),
			when(func(sim: DiveSimulation) -> bool: return sim.depth() > sim.vessel_length()))
	sand.steps = [
		Step.new(&"pulse", "Pulse to see what lies ahead", DiveSimulation.STATION_NAVIGATION,
				&"pulse", on_event(&"pulse_sent")),
		Step.new(&"quiet_scan", "Quiet Ship, then pulse again: a clean scan", DiveSimulation.STATION_NAVIGATION,
				&"quiet_ship", on_event(&"pulse_sent", func(event: Dictionary, _sim: DiveSimulation) -> bool:
					return event.quiet_ship)),
		Step.new(&"quiet_off", "Quiet Ship off, under way again", DiveSimulation.STATION_NAVIGATION,
				&"quiet_ship", when(func(sim: DiveSimulation) -> bool: return not sim.quiet_ship())),
		Step.new(&"observe", "Observe a feature as it passes through the Bore", DiveSimulation.STATION_BORE,
				&"observe", observing_in(top.name)),
	]

	var first_boundary := Phase.new("The first Boundary", on_event(&"boundary_approaching"))
	first_boundary.steps = [
		Step.new(&"ready_dial", "Ready the dial for the %s" % middle.name, DiveSimulation.STATION_REACTOR,
				&"shift_dial", dial_ready_for(middle)),
		Step.new(&"shift", "Shift as the Head crosses", DiveSimulation.STATION_REACTOR,
				&"shift", crew_shift_in(middle.name)),
	]

	var sandstone := Phase.new(String(middle.name).capitalize(), any_shift_in(middle.name))
	sandstone.steps = [
		Step.new(&"observe_sandstone", "Observe a feature in the %s" % middle.name, DiveSimulation.STATION_BORE,
				&"observe", observing_in(middle.name)),
		Step.new(&"upload", "Send everything aboard up the link before the %s seals the tunnel" % bottom.name,
				DiveSimulation.STATION_BORE, &"link", when(func(sim: DiveSimulation) -> bool:
					return sim.uploading() and not sim.tunnel_sealed() and sim.unsold_survey().is_empty())),
		Step.new(&"ready_dial_granite", "Ready the dial for the %s" % bottom.name, DiveSimulation.STATION_REACTOR,
				&"shift_dial", dial_ready_for(bottom)),
		Step.new(&"shift_granite", "Shift into the %s" % bottom.name, DiveSimulation.STATION_REACTOR,
				&"shift", crew_shift_in(bottom.name)),
	]

	var granite := Phase.new(String(bottom.name).capitalize(), any_shift_in(bottom.name))
	granite.steps = [
		Step.new(&"observe_granite", "Observe a feature in the %s: sealed in, it goes up the link slowly" % bottom.name,
				DiveSimulation.STATION_BORE, &"observe", observing_in(bottom.name)),
	]

	var turn := Phase.new("Turn and climb", course_plotted(false))
	turn.steps = [
		Step.new(&"plot_climb", "Plot the Course: climb", DiveSimulation.STATION_NAVIGATION,
				&"plot_pitch", course_plotted(false)),
		Step.new(&"climbing", "Climb: the Drive follows the Course round", DiveSimulation.STATION_DRIVE,
				&"", when(func(sim: DiveSimulation) -> bool: return sim.pitch() < 0.0)),
	]

	var surface := Phase.new("Surface", on_event(&"surfaced"))
	surface.steps = [
		Step.new(&"paid", "Surface and be paid", &"", &"", on_event(&"paid")),
	]

	s.phases = [startup, sand, first_boundary, sandstone, granite, turn, surface]

	var always := func(_sim: DiveSimulation, _events: Array) -> bool: return true
	s.messages = [
		Message.new("Orders for your first dive: survey down through the %s into the %s, then surface with the data. You are paid for survey once it is uploaded, or brought home." % [middle.name, bottom.name], always),
		Message.new("We have you nearing the %s. Ready the dial at the Reactor and Shift as you cross." % middle.name,
				on_event(&"boundary_approaching")),
		Message.new("The tunnel has sealed behind you. You are on sound through the rock now: slow both ways.",
				on_event(&"tunnel_sealed")),
		Message.new("%s confirmed. Survey a feature, then turn for home." % String(bottom.name).capitalize(),
				in_medium(bottom.name)),
		Message.new("We hear you are dark. A rescue is coming down the tunnel. Keep the hull cool.",
				on_event(&"stranded")),
		Message.new("Welcome home. The survey is paid for.", on_event(&"paid")),
	]
	return s


static func _autopilot_on(station: StringName) -> Callable:
	return when(func(sim: DiveSimulation) -> bool: return sim.autopilot(station))
