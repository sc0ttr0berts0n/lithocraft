## A Scenario: a dive chosen to be played, with its own layout, start state,
## Orders and Checklist. Plain data: the conditions are Callables that read
## the simulation through its public interface only, so a Scenario can be
## written without touching DiveSimulation. DiveSimulation keeps the progress
## (Checklist); see set_scenario() and docs/conventions/scenarios-and-checklist.md.
##
## Every condition is a Callable(sim: DiveSimulation, events: Array) -> bool:
## `events` are those raised since it was last asked. Build them with when()
## (a state of the simulation) or on_event() (an event, optionally matching).
class_name Scenario
extends RefCounted

## The Shift drill begins this many metres of depth above the first Boundary:
## far enough that the Boundary's call comes after the crew has looked round,
## near enough that it comes within a minute. Tuned for play (ADR 0001).
const _DRILL_ABOVE_BOUNDARY_M := 40.0
## Stranded in the granite begins this many metres of depth into the granite:
## the sealed tunnel behind is long enough that, uncooled, the hull fails
## before the rescue cuts through it, and cooled on the store it holds. Tuned
## for play (ADR 0001).
const _STRANDED_INTO_GRANITE_M := 200.0
## The Head's wear as Stranded in the granite begins, as the Residual that
## lost its plasma left it: worn enough that a relight is a gamble, not a sure
## thing. Tuned for play (ADR 0001).
const _STRANDED_HEAD_WEAR := 0.8
## Steering, 0 to 1, below which the Head counts as going straight for
## turning_for_home(): a turn that has settled eases its steering toward
## nothing but leaves a trace of rounding, never quite zero, and a trace is
## not a turn. Tuned for play (ADR 0001).
const _TURNING_STEERING := 0.01
## The Prospecting drill begins halted this many metres of depth into the
## granite, its target's middle this far below the start and this far to one
## side (east): within the reach of the shortest turn on the way down, and
## off the straight line down by more than the body is wide, so the dive must
## be steered into it. Tuned for play (ADR 0001).
const _PROSPECT_INTO_GRANITE_M := 60.0
const _PROSPECT_TARGET_BELOW_M := 120.0
const _PROSPECT_TARGET_OFF_M := 12.0
## The First dive's target A lies this many metres of depth into the granite
## (its middle), on the line straight down: past the granite's first
## features, so the crew has settled into the rock before it, and far enough
## below the Boundary's folds that the survey's wide place of it stays clear
## of them. Tuned for play (ADR 0001).
const _FIRST_DIVE_TARGET_INTO_GRANITE_M := 190.0
## The Glide drill begins halted this many metres down in the sand, and
## asks for a Glide this long: down across the sandstone's Boundary and well
## into the sandstone, short of the granite, so the tunnel it leaves is all
## porous rock and the vessel comes out at idle in a rock it did not start in.
## Tuned for play (ADR 0001).
const _GLIDE_DRILL_START_M := 40.0
const _GLIDE_DRILL_PLOT_M := 300.0


## A goal of the Orders, achieved once its condition has held.
class Goal:
	extends RefCounted
	var id: StringName
	var text: String
	var achieved_when: Callable
	## The depth this goal sends the dive to, metres below the surface, as
	## surface control's survey has it; NAN for a goal with no depth.
	## Navigation's moving map marks it.
	var target_depth := NAN
	## The target this goal sends the dive to find (TargetBody.label), &"" for
	## none: the scan views name its region by it.
	var target: StringName = &""

	func _init(p_id: StringName, p_text: String, p_achieved_when: Callable) -> void:
		id = p_id
		text = p_text
		achieved_when = p_achieved_when


## A step of the Checklist: what to do, at which Station (one of
## DiveSimulation.STATIONS, or &"" for none), the key-map action that does it
## (&"" for none), and when the simulation sees it done. A step that takes a
## second control names its action too (and_also()): pretuning STANDBY may
## need its frequency, its amplitude or both.
class Step:
	extends RefCounted
	var id: StringName
	var text: String
	var station: StringName
	var action: StringName
	## A second key-map action the step may take, &"" for none.
	var also: StringName = &""
	var done_when: Callable

	## Names a second key-map action the step may take; returns the step.
	func and_also(p_action: StringName) -> Step:
		also = p_action
		return self

	func _init(p_id: StringName, p_text: String, p_station: StringName,
			p_action: StringName, p_done_when: Callable) -> void:
		id = p_id
		text = p_text
		station = p_station
		action = p_action
		done_when = p_done_when


## A phase of the Checklist: its steps in order, and what begins it early
## (an invalid Callable: only finishing the phase before does). What begins a
## phase early is something the Lithocraft has done (a Boundary nearing or
## crossed, the vessel climbing, surfacing), never what the crew intends (a
## plotted Course, an engaged autopilot): intentions tick steps.
class Phase:
	extends RefCounted
	var title: String
	var steps: Array[Step] = []
	var begins_when: Callable

	func _init(p_title: String, p_begins_when := Callable()) -> void:
		title = p_title
		begins_when = p_begins_when


## A message surface control sends down the link once its condition holds.
## It is sent once a dive, unless it says when it may be sent again
## (again_after()).
class Message:
	extends RefCounted
	var text: String
	var sent_when: Callable
	## Once sent, the message may be sent again after this has held; an
	## invalid Callable (the default): never again this dive.
	var again_when := Callable()

	## Lets the message be sent again once `condition` has held since it was
	## last sent; returns the message.
	func again_after(condition: Callable) -> Message:
		again_when = condition
		return self

	func _init(p_text: String, p_sent_when: Callable) -> void:
		text = p_text
		sent_when = p_sent_when


var title := ""
## Where the dive begins and what it asks, in a line, for the start menu and
## the Habitat's opening notice.
var summary := ""
## The world the Scenario's dives are in.
var layout: MediumLayout = null
var orders: Array[Goal] = []
var phases: Array[Phase] = []
var messages: Array[Message] = []
## The start state: called with the simulation at the start of each of the
## Scenario's dives, after the Checklist is set up. Does nothing by default.
## It works through DiveSimulation's commands only: the crew's, and the
## Scenario start commands (start_below(), start_dark()) for a start the
## crew's cannot reach.
var prepare := func(_sim: DiveSimulation) -> void: pass


## A new dive in this Scenario: its layout, its Orders and Checklist, its
## start state.
func start() -> DiveSimulation:
	var sim := DiveSimulation.new(layout)
	sim.set_scenario(self)
	return sim


# --- Conditions ------------------------------------------------------------

## A condition that always holds: a message sent as the dive begins.
static func always() -> Callable:
	return func(_sim: DiveSimulation, _events: Array) -> bool: return true


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


## Holds while STANDBY's predicted Residual is inside the Band as it is now:
## its Counter-wave against the scan's guess of the Wobble ahead, which is
## what the crew can see. So it is only as true as the scan, and never holds
## with no scan of the Boundary ahead: there is nothing to pretune against.
static func standby_pretuned() -> Callable:
	return when(func(sim: DiveSimulation) -> bool:
		# NAN (no scan) is not inside the Band.
		return sim.residual(DiveSimulation.CHANNEL_STANDBY) <= sim.band())


## Holds while the scan shows the Boundary ahead: there is an Inferred
## Boundary along the Head's direction, and so a guess of the Wobble beyond
## it for STANDBY to be pretuned against. What the simulation sees, however
## many pulses it took.
static func scan_shows_boundary_ahead() -> Callable:
	return when(func(sim: DiveSimulation) -> bool: return not is_nan(sim.wobble_ahead_frequency()))


## Holds while the Head is in a Medium of this name.
static func in_medium(medium_name: StringName) -> Callable:
	return when(func(sim: DiveSimulation) -> bool: return sim.medium().name == medium_name)


## A goal of the Orders: identify the target of this label (a TargetBody the
## Scenario's layout holds, placed with MediumLayout.with_targets()). The
## survey gives its place with a wide error (DiveSimulation.start_surveyed(),
## so `prepare` calls it) and the scan narrows it; the goal is achieved once
## the target has been cut into, so it is in the Column, and the Bore Station
## has recorded it there in full (DiveSimulation.identified_targets()).
static func identify_target(label: StringName) -> Goal:
	var goal := Goal.new(StringName("identify_target_%s" % String(label).to_lower()),
			"Find target %s, crawl through it and record it in the Column" % label,
			target_identified(label))
	goal.target = label
	return goal


## Holds once the target of this label is identified: in the Column and
## recorded there in full.
static func target_identified(label: StringName) -> Callable:
	return when(func(sim: DiveSimulation) -> bool: return label in sim.identified_targets())


## Holds while the scan has narrowed the target of this label: its region is
## smaller than the Orders gave it, by the vessel's own points.
static func target_narrowed(label: StringName) -> Callable:
	return when(func(sim: DiveSimulation) -> bool: return label in sim.narrowed_targets())


## Holds while the target of this label is in the Column.
static func target_in_column(label: StringName) -> Callable:
	return when(func(sim: DiveSimulation) -> bool:
		return sim.features_in_column().any(func(f: ColumnFeature) -> bool: return f.target == label))


## Holds while the Bore Station observes the target of this label in the
## Column.
static func observing_target(label: StringName) -> Callable:
	return when(func(sim: DiveSimulation) -> bool:
		return sim.features_in_column().any(func(f: ColumnFeature) -> bool:
			return f.target == label and f.id == sim.observed_feature()))


## Holds while the Bore Station observes a feature with the Head in a Medium
## of this name.
static func observing_in(medium_name: StringName) -> Callable:
	return when(func(sim: DiveSimulation) -> bool:
		return sim.observed_feature() >= 0 and sim.medium().name == medium_name)


## Holds on a Shift (a swap: only the crew makes one, the Reactor's autopilot
## none) with the Head in a Medium of this name.
static func shift_in(medium_name: StringName) -> Callable:
	return on_event(&"shift_result", func(_event: Dictionary, sim: DiveSimulation) -> bool:
		return sim.medium().name == medium_name)


## Holds while the Head is in a Medium of this name with the Residual inside
## the Band: the Boundary into it is behind, whether by a Shift, by tuning
## ACTIVE or by the Reactor's autopilot.
static func settled_in(medium_name: StringName) -> Callable:
	return when(func(sim: DiveSimulation) -> bool:
		return sim.medium().name == medium_name and not sim.out_of_band())


## Holds when the Course is plotted downward (`down`) or upward.
static func course_plotted(down: bool) -> Callable:
	return on_event(&"course_plotted", func(event: Dictionary, _sim: DiveSimulation) -> bool:
		return event.pitch > 0.0 if down else event.pitch < 0.0)


## Holds while the Lithocraft is climbing: the Head cutting above level and
## the vessel moving, so its depth is falling. A Course plotted upward is not
## a climb until the Lithocraft has come round to it.
static func climbing() -> Callable:
	return when(func(sim: DiveSimulation) -> bool: return sim.pitch() < 0.0 and sim.speed() > 0.0)


## Holds while the Course plotted is a climb.
static func course_is_a_climb() -> Callable:
	return when(func(sim: DiveSimulation) -> bool: return sim.course_pitch() < 0.0)


## Holds while the Lithocraft is halted at Quiet Ship: still, its Head at
## idle, so a pulse or a Sweep is clean. Quiet Ship set but the vessel still
## slowing is not yet halted.
static func halted_at_quiet_ship() -> Callable:
	return when(func(sim: DiveSimulation) -> bool: return sim.quiet_ship() and sim.speed() == 0.0)


## Holds on a pulse of the Beam at this width (one of
## DiveSimulation.BEAM_WIDTHS), by hand or by itself: what the Beam sent, not
## the width set.
static func pulsed_at_width(width: StringName) -> Callable:
	return on_event(&"pulse_sent", func(event: Dictionary, _sim: DiveSimulation) -> bool:
		return event.width == width and not event.get("drowned", false))


## Holds on a Sweep run all the way out to square across, with the region of
## the target of this label narrowed by the vessel's own points: the Sweep
## done, whatever narrowed it.
static func swept_for(label: StringName) -> Callable:
	return on_event(&"sweep_ended", func(event: Dictionary, sim: DiveSimulation) -> bool:
		return event.finished and label in sim.narrowed_targets())


## Holds while the Head points straight along the Course, as a Glide needs to
## start: the turn toward it done.
static func straight_on_course() -> Callable:
	return when(func(sim: DiveSimulation) -> bool: return sim.straight_on_course())


## Holds while the Glide the scan has shown along the Course would take the
## Head up past the depth surface control's survey expects the top of the
## Medium of this name at: the scan shows the way through the rock above it,
## not only to its Boundary. Read from the scan (glide_reach()) and the
## survey's expected rocks, never the layout.
static func glide_shown_above(medium_name: StringName) -> Callable:
	return when(func(sim: DiveSimulation) -> bool:
		for rock in sim.expected_rocks():
			if rock.name == medium_name:
				return sim.glide_reach() > 0.0 and sim.depth() - sim.glide_reach() < rock.depth
		return false)


## Holds while a Glide is plotted.
static func glide_plotted() -> Callable:
	return when(func(sim: DiveSimulation) -> bool: return sim.glide_plotted() > 0.0)


## Holds while the Lithocraft glides: its jet running and the vessel moving.
## A Glide only plotted, or refused, is not one.
static func gliding() -> Callable:
	return when(func(sim: DiveSimulation) -> bool: return sim.gliding() and sim.speed() > 0.0)


## Holds while the Lithocraft crawls again: no Glide and no idle after one,
## the Head spun up and the vessel moving.
static func crawling() -> Callable:
	return when(func(sim: DiveSimulation) -> bool:
		return sim.glide_state() == DiveSimulation.GLIDE_NONE and not sim.quiet_ship() and sim.speed() > 0.0)


## Holds while the Lithocraft is turning for home and still diving: a climb
## is plotted and the Drive steers for one, and the Head, cutting below level
## and moving, is being steered round. Something the Lithocraft does: a climb
## plotted is not a turn until the vessel has begun to come round to it.
## Steering left over from an earlier turn counts: the Head always bends
## toward what the Drive steers for now, so it comes round to the climb at
## once. The trace a settled turn leaves does not (_TURNING_STEERING).
static func turning_for_home() -> Callable:
	return when(func(sim: DiveSimulation) -> bool:
		return sim.course_pitch() < 0.0 and sim.steered_pitch() < 0.0 \
				and sim.pitch() > 0.0 and sim.speed() > 0.0 and sim.steering() >= _TURNING_STEERING)


# --- The Scenarios -----------------------------------------------------------

## Every Scenario, in the order the start menu lists them: the First dive,
## then the drills in the order a new crew meets their lessons (the Glide's
## untimed tuning at idle before the Shift drill's tuning under way, then
## prospecting), then the stranding.
static func all() -> Array[Scenario]:
	return [first_dive(), glide_drill(), shift_drill(), prospecting_drill(), stranded_in_the_granite()]


## The First dive: from the desert surface down through the sandstone into
## the granite, through target A, and home with the data by a Glide. Its Media
## are read from its layout, shallowest first, so the steps follow the
## layout's own order.
static func first_dive() -> Scenario:
	var s := Scenario.new()
	s.title = "First dive"
	var ground := MediumLayout.first_dive()
	var boundaries := ground.boundary_depths()
	var top := ground.medium_at(0.0)
	var middle := ground.medium_at(boundaries[0] + 0.01)
	var bottom := ground.medium_at(boundaries[1] + 0.01)
	# Target A on the line straight down, deep in the granite.
	s.layout = ground.with_targets([TargetBody.hematite_breccia(&"A",
			Vector3(0.0, -(boundaries[1] + _FIRST_DIVE_TARGET_INTO_GRANITE_M), 0.0))])
	s.summary = "From the desert surface down through the %s into the %s, through target A, and home by a Glide with the data." % [
			middle.name, bottom.name]

	# Surface control's own survey puts the top of the deepest Medium at its
	# Boundary, so the Orders' target depth is that Boundary's depth.
	var into_bottom := Goal.new(&"into_the_granite",
			"Survey down through the %s into the %s" % [middle.name, bottom.name], in_medium(bottom.name))
	into_bottom.target_depth = boundaries[1]
	s.orders = [
		into_bottom,
		identify_target(&"A"),
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
		# Ticks on a pulse the Beam sends by itself: the switch set is only an
		# intention until the Lithocraft has covered the ground for one.
		Step.new(&"beam_pulsing", "Switch on the Beam's own pulsing: it pulses as the Lithocraft covers ground",
				DiveSimulation.STATION_NAVIGATION, &"beam_pulsing",
				on_event(&"pulse_sent", func(event: Dictionary, _sim: DiveSimulation) -> bool: return event.by_itself)),
		Step.new(&"quiet_scan", "Quiet Ship, then pulse by hand: a clean scan", DiveSimulation.STATION_NAVIGATION,
				&"quiet_ship", on_event(&"pulse_sent", func(event: Dictionary, _sim: DiveSimulation) -> bool:
					return event.quiet_ship)).and_also(&"pulse"),
		Step.new(&"quiet_off", "Quiet Ship off, under way again", DiveSimulation.STATION_NAVIGATION,
				&"quiet_ship", when(func(sim: DiveSimulation) -> bool: return not sim.quiet_ship())),
		Step.new(&"observe", "Observe a feature as it passes through the Bore", DiveSimulation.STATION_BORE,
				&"observe", observing_in(top.name)),
	]

	var first_boundary := Phase.new("The first Boundary", on_event(&"boundary_approaching"))
	first_boundary.steps = [
		_pulse_for_the_boundary(&"pulse_boundary"),
		Step.new(&"pretune_standby", "Pretune standby for the %s" % middle.name, DiveSimulation.STATION_REACTOR,
				&"tune_frequency", standby_pretuned()).and_also(&"tune_amplitude"),
		Step.new(&"shift", "Shift as the Head crosses", DiveSimulation.STATION_REACTOR,
				&"shift", shift_in(middle.name)),
		_tune_active(&"tune_active", middle.name),
	]

	var sandstone := Phase.new(String(middle.name).capitalize(), settled_in(middle.name))
	sandstone.steps = [
		Step.new(&"observe_sandstone", "Observe a feature in the %s" % middle.name, DiveSimulation.STATION_BORE,
				&"observe", observing_in(middle.name)),
		Step.new(&"upload", "Send everything aboard up the link before the %s seals the tunnel" % bottom.name,
				DiveSimulation.STATION_BORE, &"link", when(func(sim: DiveSimulation) -> bool:
					return sim.uploading() and not sim.tunnel_sealed() and sim.unsold_survey().is_empty())),
		_pulse_for_the_boundary(&"pulse_boundary_granite"),
		Step.new(&"pretune_standby_granite", "Pretune standby for the %s" % bottom.name, DiveSimulation.STATION_REACTOR,
				&"tune_frequency", standby_pretuned()).and_also(&"tune_amplitude"),
		Step.new(&"shift_granite", "Shift into the %s" % bottom.name, DiveSimulation.STATION_REACTOR,
				&"shift", shift_in(bottom.name)),
		_tune_active(&"tune_active_granite", bottom.name),
	]

	var granite := Phase.new(String(bottom.name).capitalize(), settled_in(bottom.name))
	granite.steps = [
		Step.new(&"observe_granite", "Observe a feature in the %s: sealed in, it goes up the link slowly" % bottom.name,
				DiveSimulation.STATION_BORE, &"observe", observing_in(bottom.name)),
	]

	# Target A, below on the line down: halt, Sweep for it, crawl on into it
	# and record it. Begins early once the Head has cut into it.
	var target := Phase.new("Target A", target_in_column(&"A"))
	target.steps = [
		Step.new(&"quiet_sweep", "Quiet Ship: halt for a clean Sweep", DiveSimulation.STATION_NAVIGATION,
				&"quiet_ship", halted_at_quiet_ship()),
		Step.new(&"sweep_target", "Sweep for target A, and pulse: the Beam sees ahead, the Sweep round about, and its region narrows",
				DiveSimulation.STATION_NAVIGATION, &"sweep", swept_for(&"A")).and_also(&"pulse"),
		Step.new(&"quiet_off_target", "Quiet Ship off, under way again: the Course runs through the region",
				DiveSimulation.STATION_NAVIGATION, &"quiet_ship", when(func(sim: DiveSimulation) -> bool: return not sim.quiet_ship())),
		Step.new(&"in_column", "Crawl into target A: it passes into the Column", DiveSimulation.STATION_DRIVE,
				&"", target_in_column(&"A")),
		Step.new(&"observe_target", "Observe target A as it passes through the Bore", DiveSimulation.STATION_BORE,
				&"observe", observing_target(&"A")),
		Step.new(&"identified", "Record it in full before it leaves the Bore", DiveSimulation.STATION_BORE,
				&"", target_identified(&"A")),
	]

	# The turn begins early once the Lithocraft is climbing, never on a climb
	# plotted: a Course is an intention. Its first step reads the Course as it
	# stands, so a climb already plotted when the phase begins ticks it; the
	# climbing step ticks with it, and the Glide home's steps follow, so the
	# Checklist always has the climb's next step to show.
	var turn := Phase.new("Turn and climb", climbing())
	turn.steps = [
		Step.new(&"plot_climb", "Plot the Course: climb. The Lithocraft goes forward only, so the way home is a turn",
				DiveSimulation.STATION_NAVIGATION, &"plot_pitch", course_is_a_climb()),
		Step.new(&"climbing", "Turn for home: the Drive follows the Course round, and deepens through the turn before it rises",
				DiveSimulation.STATION_DRIVE, &"", climbing()),
	]

	# The climb home through the rock above is a Glide: scanned, plotted,
	# started straight on the Course and held on its line. No Shift is asked
	# of it: it crosses the Boundary above with no Wobble on the plasma.
	var glide := Phase.new("Glide home")
	glide.steps = [
		Step.new(&"narrow_beam", "Narrow the Beam: it reaches further, to the Boundaries above", DiveSimulation.STATION_NAVIGATION,
				&"beam_width", pulsed_at_width(DiveSimulation.BEAM_NARROW)),
		Step.new(&"straight_on", "Come round straight onto the climb: a Glide runs only straight along the Course",
				DiveSimulation.STATION_DRIVE, &"", straight_on_course()),
		Step.new(&"quiet_glide_scan", "Quiet Ship: halt for a clean scan of the way home", DiveSimulation.STATION_NAVIGATION,
				&"quiet_ship", halted_at_quiet_ship()),
		Step.new(&"pulse_way_home", "Pulse until Navigation shows the Glide home up through the %s" % middle.name,
				DiveSimulation.STATION_NAVIGATION, &"pulse", glide_shown_above(bottom.name)),
		Step.new(&"plot_glide", "Plot the Glide: all the scan shows", DiveSimulation.STATION_NAVIGATION,
				&"plot_glide_all", glide_plotted()),
		Step.new(&"quiet_off_glide", "Quiet Ship off: a Glide cannot start at Quiet Ship", DiveSimulation.STATION_NAVIGATION,
				&"quiet_ship", when(func(sim: DiveSimulation) -> bool: return not sim.quiet_ship())),
		Step.new(&"start_glide", "Start the Glide", DiveSimulation.STATION_DRIVE, &"glide", gliding()),
		Step.new(&"hold_glide", "Hold the Glide on its line to its end: nudge toward the ball's diamond, or engage the Drive's autopilot, which holds it loosely",
				DiveSimulation.STATION_DRIVE, &"nudge_pitch", on_event(&"glide_ended")).and_also(&"nudge_heading"),
	]

	# Out of the Glide, halted with the Head at idle in whatever rock it
	# ended in: begins as the Glide ends, however it ended.
	var idle := Phase.new("Out of the Glide", on_event(&"glide_ended"))
	idle.steps = _out_of_the_glide(middle.name)

	# The Boundary into the top Medium, crawled: the Glide stopped short of it.
	# Begins early as the Lithocraft climbs across that Boundary however it
	# came up (a dive left to the autopilots never glides); never on being in
	# the top Medium alone, which it also is at the surface and on a turn for
	# home made in it.
	var climbing_into_top := func(sim: DiveSimulation, events: Array) -> bool:
		return climbing().call(sim, events) and on_event(&"boundary_crossed",
				func(event: Dictionary, _sim: DiveSimulation) -> bool: return event.to == top.name).call(sim, events)
	var into_top := Phase.new("Into the %s" % top.name, climbing_into_top)
	into_top.steps = [
		_pulse_for_the_boundary(StringName("pulse_boundary_%s" % top.name)),
		Step.new(StringName("pretune_standby_%s" % top.name), "Pretune standby for the %s" % top.name,
				DiveSimulation.STATION_REACTOR, &"tune_frequency", standby_pretuned()).and_also(&"tune_amplitude"),
		Step.new(StringName("shift_%s" % top.name), "Shift into the %s" % top.name, DiveSimulation.STATION_REACTOR,
				&"shift", shift_in(top.name)),
		_tune_active(StringName("tune_active_%s" % top.name), top.name),
	]

	var surface := Phase.new("Surface", on_event(&"surfaced"))
	surface.steps = [
		Step.new(&"paid", "Crawl up to the surface and be paid", &"", &"", on_event(&"paid")),
	]

	s.phases = [startup, sand, first_boundary, sandstone, granite, target, turn, glide, idle, into_top, surface]
	# Surface control surveyed the ground before the dive: its faint points
	# are in the scan as the dive begins, and its wide place of target A.
	s.prepare = func(sim: DiveSimulation) -> void: sim.start_surveyed()

	s.messages = [
		Message.new(("Orders for your first dive: survey down through the %s into the %s, find target A there and record it, "
				+ "then surface with the data. Our survey of this ground is in your scan, faint. "
				+ "You are paid for survey once it is uploaded, or brought home.") % [middle.name, bottom.name], always()),
		Message.new("We have you nearing the %s. Pretune standby at the Reactor and swap it in as you cross." % middle.name,
				on_event(&"boundary_approaching")),
		Message.new("The tunnel has sealed behind you. You are on sound through the rock now: slow both ways.",
				on_event(&"tunnel_sealed")),
		Message.new(("%s confirmed. Survey a feature. Target A lies below you on your line: "
				+ "something dense and magnetic that our survey cannot name. Halt and sweep for it, then crawl through it.")
				% String(bottom.name).capitalize(), in_medium(bottom.name)),
		Message.new("Target A is in the Column. Record it before it leaves the Bore.", target_in_column(&"A")),
		Message.new(("Target A identified: hematite breccia, granite shattered and cemented by iron oxide, "
				+ "with a little copper. It is paid for once its record is up the link or brought home. Turn for home."),
				target_identified(&"A")),
		# Before the Glide is first used: what it costs.
		Message.new(("Come home by a Glide: the Head melts the whole face and the vessel runs fast and straight, "
				+ "and crosses Boundaries with no Shift. It costs: no Column, so nothing surveyed or seen; "
				+ "deaf to every pulse; the Reactor's whole output; and off its line it wears the Head and hull. "
				+ "It runs only as far as your scan has shown, and ends halted with the Head at idle: "
				+ "tune standby for the rock round you and Shift to spin it up."),
				target_identified(&"A")),
		# One for each turn for home: the same turn until the climb is given
		# up for another Course, however the turn itself goes.
		Message.new("Turning for home: you will deepen through the turn.", turning_for_home()) \
				.again_after(when(func(sim: DiveSimulation) -> bool: return sim.course_pitch() >= 0.0)),
		Message.new("We hear you are dark. A rescue is coming down the tunnel. Keep the hull cool.",
				on_event(&"stranded")),
		Message.new("Welcome home. The survey is paid for.", on_event(&"paid")),
	]
	return s


## The Glide drill: halted at Quiet Ship in the sand of the First dive's
## ground, the Reactor's and Thermal's autopilots engaged. Scan, plot a Glide
## down across the sandstone's Boundary, start it and hold its line, come out
## at idle in the sandstone, tune STANDBY for it and Shift to spin the Head up
## into the Crawl. All in porous rock, so the rough tunnel the Glide leaves
## dims the link, which the Bore Station shows.
static func glide_drill() -> Scenario:
	var s := Scenario.new()
	s.title = "Glide drill"
	s.layout = MediumLayout.first_dive()
	var boundary := s.layout.boundary_depths()[0]
	var above := s.layout.medium_at(boundary - 0.01)
	var below := s.layout.medium_at(boundary + 0.01)
	s.summary = "Halted in the %s: scan, plot a Glide down into the %s, hold its line, come out at idle, tune standby and spin up." % [
			above.name, below.name]
	s.prepare = func(sim: DiveSimulation) -> void:
		sim.start_below(_GLIDE_DRILL_START_M)
		# The same ground as the First dive, surveyed from the surface alike.
		sim.start_surveyed()
		sim.set_autopilot(DiveSimulation.STATION_REACTOR, true)
		sim.set_autopilot(DiveSimulation.STATION_THERMAL, true)
		sim.set_quiet_ship(true)

	s.orders = [
		Goal.new(&"glide_and_crawl_on", "Glide down into the %s, come out at idle and crawl on" % below.name,
				when(func(sim: DiveSimulation) -> bool:
					return not sim.glided_stretches().is_empty() and sim.medium().name == below.name \
							and sim.glide_state() == DiveSimulation.GLIDE_NONE and sim.speed() > 0.0 and not sim.out_of_band())),
	]

	var plot := Phase.new("Plot and glide")
	plot.steps = [
		Step.new(&"read_orders", "Read the orders", &"", &"toggle_checklist", on_event(&"orders_read")),
		Step.new(&"quiet_scan", "Pulse at Quiet Ship: a Glide runs only as far as the scan has shown",
				DiveSimulation.STATION_NAVIGATION, &"pulse", on_event(&"pulse_sent", func(event: Dictionary, _sim: DiveSimulation) -> bool:
					return event.quiet_ship)),
		Step.new(&"plot_glide", "Plot a Glide of %d m down the Course: each press lengthens it" % _GLIDE_DRILL_PLOT_M,
				DiveSimulation.STATION_NAVIGATION, &"plot_glide_step",
				when(func(sim: DiveSimulation) -> bool: return sim.glide_plotted() >= _GLIDE_DRILL_PLOT_M)),
		Step.new(&"quiet_off", "Quiet Ship off: a Glide cannot start at Quiet Ship", DiveSimulation.STATION_NAVIGATION,
				&"quiet_ship", when(func(sim: DiveSimulation) -> bool: return not sim.quiet_ship())),
		Step.new(&"start_glide", "Start the Glide", DiveSimulation.STATION_DRIVE, &"glide", gliding()),
		Step.new(&"hold_glide", "Hold the Glide on its line to its end: engage the Drive's autopilot, which holds it loosely, or nudge toward the ball's diamond",
				DiveSimulation.STATION_DRIVE, &"autopilot_drive", on_event(&"glide_ended")).and_also(&"nudge_pitch"),
	]
	var idle := Phase.new("Out of the Glide", on_event(&"glide_ended"))
	idle.steps = _out_of_the_glide(below.name)
	s.phases = [plot, idle]

	s.messages = [
		Message.new(("Glide drill: you are halted at Quiet Ship in the %s, the Reactor and Thermal on their autopilots. "
				+ "Scan, plot a Glide of %d m, start it and hold its line. It is fast and straight, crosses the %s's "
				+ "Boundary with no Shift, and costs: no Column, deaf, the Reactor's whole output, and wear off its line.")
				% [above.name, _GLIDE_DRILL_PLOT_M, below.name], always()),
		Message.new(("Out of the Glide, in the %s. Its tunnel is rough-walled in this porous rock: our light up it is dimmer, "
				+ "and your link slower. Tune standby for the rock round you and Shift to spin the Head up.") % below.name,
				on_event(&"glide_ended")),
		Message.new("Crawling again. That is the drill.", s.orders[0].achieved_when),
	]
	return s


## The Shift drill: the Lithocraft under way in the sand a short way above
## the sandstone, its Drive and Thermal on their autopilots and a pulse just
## sent, so the crew has only the Reactor to work: pretune standby against the
## scan's guess of the sandstone's Wobble and swap it in as the Head crosses.
static func shift_drill() -> Scenario:
	var s := Scenario.new()
	s.title = "Shift drill"
	s.layout = MediumLayout.first_dive()
	var boundary := s.layout.boundary_depths()[0]
	var above := s.layout.medium_at(boundary - 0.01)
	var below := s.layout.medium_at(boundary + 0.01)
	s.summary = "Under way in the %s a short way above the %s: pretune standby and swap it in as the Head crosses." % [
			above.name, below.name]
	s.prepare = func(sim: DiveSimulation) -> void:
		sim.start_below(boundary - _DRILL_ABOVE_BOUNDARY_M)
		# The same ground as the First dive, surveyed from the surface alike.
		sim.start_surveyed()
		sim.set_autopilot(DiveSimulation.STATION_THERMAL, true)
		sim.set_autopilot(DiveSimulation.STATION_DRIVE, true)
		# Navigation's one pulse as the drill begins: the survey's guess alone
		# is too faint to pretune well against, and the drill is the Shift.
		sim.pulse()

	s.orders = [
		Goal.new(&"clean_shift", "Shift cleanly into the %s" % below.name,
				on_event(&"shift_result", func(event: Dictionary, sim: DiveSimulation) -> bool:
					return event.clean and sim.medium().name == below.name)),
	]

	var reactor := Phase.new("The %s Boundary" % below.name)
	reactor.steps = [
		Step.new(&"read_orders", "Read the orders", &"", &"toggle_checklist", on_event(&"orders_read")),
		Step.new(&"pretune_standby", "Pretune standby for the %s" % below.name, DiveSimulation.STATION_REACTOR,
				&"tune_frequency", standby_pretuned()).and_also(&"tune_amplitude"),
		Step.new(&"shift", "Shift as the Head crosses", DiveSimulation.STATION_REACTOR,
				&"shift", shift_in(below.name)),
		_tune_active(&"tune_active", below.name),
	]
	s.phases = [reactor]

	s.messages = [
		Message.new(("Shift drill: the Drive and Thermal are on their autopilots and Navigation has pulsed. "
				+ "Yours is the Reactor: pretune standby against the scan's guess of the %s, and swap it in as the Head crosses.")
				% below.name, always()),
		Message.new("We have you nearing the %s. Pretune standby at the Reactor and swap it in as you cross." % below.name,
				on_event(&"boundary_approaching")),
		Message.new("Shift made. That is the drill: dive on, or turn for home.", shift_in(below.name)),
	]
	return s


## The Prospecting drill: halted at Quiet Ship in the granite of the First
## dive's ground, with a target below that the survey places only roughly.
## Sweep and aim the Beam until its region narrows, plot the Course into it,
## crawl through it and record it at the Bore Station: the loop of
## prospecting, without the Glide that would bring the vessel near.
static func prospecting_drill() -> Scenario:
	var s := Scenario.new()
	s.title = "Prospecting drill"
	var ground := MediumLayout.first_dive()
	var granite_top := ground.boundary_depths()[1]
	var granite := ground.medium_at(granite_top + 0.01)
	var start := granite_top + _PROSPECT_INTO_GRANITE_M
	s.layout = ground.with_targets([TargetBody.hematite_breccia(&"A",
			Vector3(_PROSPECT_TARGET_OFF_M, -(start + _PROSPECT_TARGET_BELOW_M), 0.0))])
	s.summary = "Halted in the %s above a target the survey places only roughly: sweep it, aim the Beam at it, and crawl through it." % granite.name
	s.prepare = func(sim: DiveSimulation) -> void:
		sim.start_below(start)
		sim.start_surveyed()
		sim.set_autopilot(DiveSimulation.STATION_REACTOR, true)
		sim.set_autopilot(DiveSimulation.STATION_THERMAL, true)
		sim.set_quiet_ship(true)

	s.orders = [identify_target(&"A")]

	var prospect := Phase.new("Prospect")
	prospect.steps = [
		Step.new(&"read_orders", "Read the orders", &"", &"toggle_checklist", on_event(&"orders_read")),
		Step.new(&"narrow", "Pulse, or Sweep, until target A's region narrows round what the echoes show",
				DiveSimulation.STATION_NAVIGATION, &"pulse", target_narrowed(&"A")).and_also(&"sweep"),
		Step.new(&"aim", "Aim the Beam at the region and pulse again: it tightens", DiveSimulation.STATION_NAVIGATION,
				&"beam_aim_across", on_event(&"pulse_sent", func(_event: Dictionary, sim: DiveSimulation) -> bool:
					return sim.beam_aim() != Vector2.ZERO)).and_also(&"beam_aim_up"),
		Step.new(&"plot", "Plot the Course into the region", DiveSimulation.STATION_NAVIGATION,
				&"plot_heading_step", on_event(&"course_plotted")).and_also(&"plot_pitch_step"),
	]
	# Begins early once the Head has cut into the target, however it got there.
	var crawl := Phase.new("Crawl through", target_in_column(&"A"))
	crawl.steps = [
		Step.new(&"quiet_off", "Quiet Ship off, under way again", DiveSimulation.STATION_NAVIGATION,
				&"quiet_ship", when(func(sim: DiveSimulation) -> bool: return not sim.quiet_ship())),
		Step.new(&"drive_autopilot", "Engage the Drive's autopilot: it follows the Course", DiveSimulation.STATION_DRIVE,
				&"autopilot_drive", _autopilot_on(DiveSimulation.STATION_DRIVE)),
		Step.new(&"in_column", "Crawl into target A: it passes into the Column", DiveSimulation.STATION_DRIVE,
				&"", target_in_column(&"A")),
		Step.new(&"observe_target", "Observe target A as it passes through the Bore", DiveSimulation.STATION_BORE,
				&"observe", observing_target(&"A")),
		Step.new(&"identified", "Record it in full: slow, or stop, to give the Bore Station time", DiveSimulation.STATION_BORE,
				&"", target_identified(&"A")),
	]
	s.phases = [prospect, crawl]

	s.messages = [
		Message.new(("Prospecting drill: our survey saw something dense and magnetic below you in the %s and cannot say what it is. "
				+ "Find target A, crawl through it and record it.") % granite.name, always()),
		Message.new("Target A is in the Column. Record it before it leaves the Bore.", target_in_column(&"A")),
		Message.new("Target A identified. That is the drill.", target_identified(&"A")),
	]
	return s


## Stranded in the granite: sealed in a way into the granite, the Head's
## plasma just lost on a worn Head, the rescue called and the stranding clock
## running. Relight if the Head will light and climb home; if it will not,
## send the survey aboard up the link, cool the hull on the emergency store
## and wait for the rescue.
static func stranded_in_the_granite() -> Scenario:
	var s := Scenario.new()
	s.title = "Stranded in the granite"
	s.layout = MediumLayout.first_dive()
	var boundaries := s.layout.boundary_depths()
	var granite_top := boundaries[1]
	var top := s.layout.medium_at(0.0)
	var middle := s.layout.medium_at(boundaries[0] + 0.01)
	var bottom := s.layout.medium_at(granite_top + 0.01)
	s.summary = "Sealed in the %s, the Head dark and the stranding clock running: relight, or send the survey up, cool the hull and wait for the rescue." % bottom.name
	s.prepare = func(sim: DiveSimulation) -> void:
		sim.start_below(granite_top + _STRANDED_INTO_GRANITE_M)
		# Surveyed from the surface as the First dive's ground is: the climb
		# home has a faint guess of the Boundaries above before any pulse.
		sim.start_surveyed()
		sim.start_dark(_STRANDED_HEAD_WEAR)

	s.orders = [
		Goal.new(&"home_alive", "Come home alive: relit and climbed, or rescued",
				when(func(sim: DiveSimulation) -> bool: return sim.surfaced())),
	]

	# Two ways home, as phases. A relight that does not light begins Still
	# dark, then Wait for the rescue; one that lights, now or later, begins
	# Relit. Either ends in Home, which begins as the Lithocraft surfaces. A
	# phase that only follows another for having come next (Still dark after
	# Dark lit, Relit after the rescue) begins on the same tend as the one
	# that skips it, so the crew never sees it.
	var dark := Phase.new("Dark")
	dark.steps = [
		Step.new(&"read_orders", "Read the orders", &"", &"toggle_checklist", on_event(&"orders_read")),
		Step.new(&"relight", "Relight the Head from the emergency store", DiveSimulation.STATION_REACTOR,
				&"relight", _relight(true)),
	]

	# The relit Head is worn and its Band narrow: the Reactor's autopilot
	# tunes too slowly for it through a Boundary, so the crew makes every
	# Shift up.
	var relit := Phase.new("Relit", _relight(true))
	relit.steps = [
		Step.new(&"thermal_autopilot", "Engage Thermal's autopilot", DiveSimulation.STATION_THERMAL,
				&"autopilot_thermal", _autopilot_on(DiveSimulation.STATION_THERMAL)),
		Step.new(&"plot_climb", "Plot the Course: climb", DiveSimulation.STATION_NAVIGATION,
				&"plot_pitch", course_plotted(false)),
		Step.new(&"drive_autopilot", "Engage the Drive's autopilot: it follows the Course up",
				DiveSimulation.STATION_DRIVE, &"autopilot_drive", _autopilot_on(DiveSimulation.STATION_DRIVE)),
	]
	for medium in [middle, top]:
		relit.steps.append(Step.new(StringName("pulse_%s" % medium.name),
				"Pulse to see the Boundary above: the scan's guess of the %s shows on standby" % medium.name,
				DiveSimulation.STATION_NAVIGATION, &"pulse", on_event(&"pulse_sent")))
		relit.steps.append(Step.new(StringName("pretune_standby_%s" % medium.name),
				"Pretune standby for the %s: the worn Head's Band is narrow" % medium.name,
				DiveSimulation.STATION_REACTOR, &"tune_frequency", standby_pretuned()).and_also(&"tune_amplitude"))
		relit.steps.append(Step.new(StringName("shift_%s" % medium.name), "Shift into the %s" % medium.name,
				DiveSimulation.STATION_REACTOR, &"shift", shift_in(medium.name)))
	relit.steps.append(Step.new(&"climbed", "Climb to the surface", &"", &"time_faster", on_event(&"surfaced")))

	var still_dark := Phase.new("Still dark", _relight(false))
	still_dark.steps = [
		Step.new(&"link", "Send the most valuable survey up the link first, on the store",
				DiveSimulation.STATION_BORE, &"upload_priority", when(func(sim: DiveSimulation) -> bool:
					return sim.uploading() and sim.upload_priority() == DiveSimulation.UPLOAD_MOST_VALUABLE_FIRST)),
		Step.new(&"cool", "Run Thermal's pumps on the store to cool the hull", DiveSimulation.STATION_THERMAL,
				&"heat_split", when(func(sim: DiveSimulation) -> bool: return sim.stranded() and sim.heat_split() > 0.0)),
	]

	var wait := Phase.new("Wait for the rescue")
	wait.steps = [
		Step.new(&"rescued", "Wait for the rescue: the stranding clock against the rescue's", &"",
				&"time_faster", on_event(&"rescued")),
	]

	var home := Phase.new("Home", when(func(sim: DiveSimulation) -> bool: return sim.surfaced()))
	home.steps = [
		Step.new(&"paid", "Be paid for the survey", &"", &"",
				when(func(sim: DiveSimulation) -> bool: return sim.surfaced())),
	]
	s.phases = [dark, still_dark, wait, relit, home]

	s.messages = [
		Message.new(("We hear you are dark, sealed in the %s. A rescue is coming down the tunnel. "
				+ "Try a relight; if the Head will not light, send your survey up and keep the hull cool while you wait.")
				% bottom.name, always()),
		Message.new("You are lit. Climb home.", _relight(true)),
		Message.new("Welcome home. The survey is paid for.", on_event(&"paid")),
	]
	return s


## Holds on a relight that lit the Head (`lit`), or on one that did not
## (it failed, or the store could not pay for it).
static func _relight(lit: bool) -> Callable:
	return on_event(&"relight_result", func(event: Dictionary, _sim: DiveSimulation) -> bool:
		return (event.outcome == &"lit") == lit)


## The step before a pretune: pulse until the scan shows the Boundary ahead,
## so STANDBY has a guess of the Wobble beyond it. It ticks on what the scan
## shows, not on a count of pulses: at once if an earlier scan already does.
static func _pulse_for_the_boundary(id: StringName) -> Step:
	return Step.new(id, "Pulse until Navigation shows the Boundary ahead", DiveSimulation.STATION_NAVIGATION,
			&"pulse", scan_shows_boundary_ahead())


## The step after a Shift into the Medium of this name: STANDBY was pretuned
## against a guess, so the Shift may leave the Residual outside the Band, and
## a Shift lets the Reactor's autopilot go; the crew tunes ACTIVE until the
## Residual is inside the Band there. It ticks at once after a Shift that
## already left it inside.
static func _tune_active(id: StringName, medium_name: StringName) -> Step:
	return Step.new(id, "Select active and tune it until the Residual is inside the Band",
			DiveSimulation.STATION_REACTOR, &"tune_frequency", settled_in(medium_name)).and_also(&"tune_amplitude")


## The steps out of a Glide, halted with the Head at idle in the Medium of
## this name: STANDBY tuned for the rock round the vessel (it reads against
## the scan's guess of the rock the Glide entered), the Shift that spins the
## Head up into the Crawl, then ACTIVE tuned until the Residual is inside the
## Band, as after any Shift.
static func _out_of_the_glide(medium_name: StringName) -> Array[Step]:
	return [
		Step.new(&"tune_standby_idle", "Tune standby for the rock round the vessel: the Head waits at idle",
				DiveSimulation.STATION_REACTOR, &"tune_frequency", standby_pretuned()).and_also(&"tune_amplitude"),
		Step.new(&"spin_up", "Shift: the Head spins up and the Crawl begins", DiveSimulation.STATION_REACTOR,
				&"shift", crawling()),
		_tune_active(&"tune_active_idle", medium_name),
	]


static func _autopilot_on(station: StringName) -> Callable:
	return when(func(sim: DiveSimulation) -> bool: return sim.autopilot(station))
