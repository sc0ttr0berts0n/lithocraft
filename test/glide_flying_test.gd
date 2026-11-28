# The Glide flown by hand (ticket #126), tested at the simulation's
# interface: pushed off its line, held on it by the Drive's nudge (its nudges)
# or loosely by its autopilot, the Head and hull wearing only while it is off,
# faster the further off. Assert relationships, never tuned constants (ADR
# 0001). DiveTestKit.fly_glide() is the careful hand.
extends GdUnitTestSuite

const SOFT_TO := 60.0
const HARD_TO := 900.0
## A Glide long enough that its push takes it well off a line nobody holds.
const LONG_M := 600.0


## Soft rock over hard over soft, the hard deep enough for a long Glide.
func _layers(first := DiveTestKit.soft(), second := DiveTestKit.hard()) -> MediumLayout:
	return MediumLayout.layered([[0.0, first], [SOFT_TO, second], [HARD_TO, DiveTestKit.soft()]])


## A dive at the surface with the survey's soundings of every Boundary, the
## Reactor's autopilot engaged, and a Glide of `metres` (held to what the scan
## shows) under way.
func _gliding(metres := LONG_M, layout := _layers()) -> DiveSimulation:
	var sim := DiveSimulation.new(layout)
	sim.start_surveyed()
	sim.set_autopilot(DiveSimulation.STATION_REACTOR, true)
	sim.advance(0.1)
	sim.plot_glide(metres)
	sim.start_glide()
	sim.advance(0.02)
	assert_bool(sim.gliding()).is_true()
	return sim


## The same Glide left to the Drive's autopilot.
func _on_autopilot(metres := LONG_M) -> DiveSimulation:
	var sim := _gliding(metres)
	sim.set_autopilot(DiveSimulation.STATION_DRIVE, true)
	return sim


## The world direction of a heading and pitch in degrees, as the simulation's.
static func _direction_of(heading: float, pitch: float) -> Vector3:
	var p := deg_to_rad(pitch)
	var h := deg_to_rad(heading)
	return Vector3(cos(p) * sin(h), -sin(p), -cos(p) * cos(h))


# --- Criterion 1: on the line nothing wears; left alone, the Head and hull do

func test_a_glide_held_on_its_line_wears_neither_the_head_nor_the_hull() -> void:
	var sim := _gliding()
	var head := sim.head_wear()
	var hull := sim.vessel_wear()

	assert_dict(DiveTestKit.fly_glide(sim, true)).is_not_empty()

	assert_float(sim.head_wear()).is_equal(head)
	assert_float(sim.vessel_wear()).is_equal(hull)


func test_a_glide_left_alone_drifts_off_its_line_and_wears_the_head_and_the_hull() -> void:
	var sim := _gliding()
	var head := sim.head_wear()
	var hull := sim.vessel_wear()
	var last := []

	assert_dict(DiveTestKit.fly_glide(sim, false, Vector2.ZERO, [], 0.02, last)).is_not_empty()

	assert_float(last[0].length()).is_greater(sim.glide_slack())
	assert_float(sim.head_wear()).is_greater(head)
	assert_float(sim.vessel_wear()).is_greater(hull)


func test_while_it_slaps_its_sheath_the_drive_warns_and_the_hull_takes_damage() -> void:
	var sim := _gliding()
	var warned := false
	var damaged := false
	for i in 3000:
		sim.advance(0.02)
		sim.take_events()
		if sim.glide_contact() > 0.0:
			warned = warned or (sim.call_reason(DiveSimulation.STATION_DRIVE) == &"off_glide_line"
					and sim.call_warns(DiveSimulation.STATION_DRIVE))
			damaged = damaged or sim.hull_taking_damage()
		if not sim.gliding():
			break

	assert_bool(warned).is_true()
	assert_bool(damaged).is_true()


func test_a_glide_held_on_its_line_never_warns() -> void:
	var sim := _gliding()
	var seen := []

	DiveTestKit.fly_glide(sim, true, Vector2.ZERO, seen)

	var reasons := seen.filter(func(e: Dictionary) -> bool: return e.type == &"station_call") \
			.map(func(e: Dictionary) -> StringName: return e.reason)
	assert_array(reasons).not_contains([&"off_glide_line"])


# --- Criterion 2: further off wears faster ---------------------------------

func test_further_off_the_line_wears_faster() -> void:
	var near := _gliding()
	var far := _gliding()
	var slack := near.glide_slack()

	DiveTestKit.fly_glide(near, true, Vector2(slack * 2.0, 0.0))
	DiveTestKit.fly_glide(far, true, Vector2(slack * 3.0, 0.0))

	assert_float(near.head_wear()).is_greater(0.0)
	assert_float(far.head_wear()).is_greater(near.head_wear())
	assert_float(near.vessel_wear()).is_greater(0.0)
	assert_float(far.vessel_wear()).is_greater(near.vessel_wear())


func test_inside_the_sheath_s_slack_nothing_wears_however_far_off() -> void:
	var sim := _gliding()

	DiveTestKit.fly_glide(sim, true, Vector2(0.0, sim.glide_slack() * 0.5))

	assert_float(sim.head_wear()).is_equal(0.0)
	assert_float(sim.vessel_wear()).is_equal(0.0)


# --- Criterion 3: the autopilot holds it loosely ---------------------------

func test_the_drive_s_autopilot_wears_less_than_no_hand_and_more_than_a_line_held() -> void:
	var held := _gliding()
	var alone := _gliding()
	var auto := _on_autopilot()

	DiveTestKit.fly_glide(held, true)
	DiveTestKit.fly_glide(alone, false)
	DiveTestKit.fly_glide(auto, false)

	assert_float(auto.head_wear()).is_greater(held.head_wear())
	assert_float(auto.head_wear()).is_less(alone.head_wear())
	assert_float(auto.vessel_wear()).is_greater(held.vessel_wear())
	assert_float(auto.vessel_wear()).is_less(alone.vessel_wear())


func test_the_drive_s_autopilot_keeps_a_glide_nearer_its_line_than_no_hand() -> void:
	var alone := _gliding()
	var auto := _on_autopilot()
	var alone_off := []
	var auto_off := []

	DiveTestKit.fly_glide(alone, false, Vector2.ZERO, [], 0.02, alone_off)
	DiveTestKit.fly_glide(auto, false, Vector2.ZERO, [], 0.02, auto_off)

	assert_float(auto_off[0].length()).is_less(alone_off[0].length())


func test_a_nudge_takes_the_glide_off_the_autopilot() -> void:
	var sim := _on_autopilot()
	sim.set_attended(DiveSimulation.STATION_DRIVE, true)

	sim.nudge_heading(1)

	assert_bool(sim.autopilot(DiveSimulation.STATION_DRIVE)).is_false()


# --- #161: the autopilot holds a Glide it was engaged for --------------------

## The same Glide started with the Drive's autopilot already engaged.
func _started_on_autopilot() -> DiveSimulation:
	var sim := DiveSimulation.new(_layers())
	sim.start_surveyed()
	sim.set_autopilot(DiveSimulation.STATION_REACTOR, true)
	sim.set_autopilot(DiveSimulation.STATION_DRIVE, true)
	sim.advance(0.1)
	sim.plot_glide(LONG_M)
	sim.take_events()
	sim.start_glide()
	sim.advance(0.02)
	assert_bool(sim.gliding()).is_true()
	return sim


## Flies this Glide to its end at a raised time rate, nobody at the Drive,
## and says what the Drive's call did while it glided: whether it showed the
## Glide off its line, whether that was ever a warning, and whether the time
## rate fell.
func _off_line_at_a_raised_rate(sim: DiveSimulation) -> Dictionary:
	var raised := 4.0
	sim.set_time_rate(raised)
	assert_float(sim.time_rate()).is_equal(raised)
	var seen := {shown = false, warned = false, slowed = false}
	DiveTestKit.fly_glide(sim, false, Vector2.ZERO, [], 0.02, [], 600.0, func() -> void:
		if not sim.gliding():
			return
		if sim.call_reason(DiveSimulation.STATION_DRIVE) == &"off_glide_line":
			seen.shown = seen.shown or sim.call_urgency(DiveSimulation.STATION_DRIVE) > 0.0
			seen.warned = seen.warned or sim.call_warns(DiveSimulation.STATION_DRIVE)
		seen.slowed = seen.slowed or sim.time_rate() < raised)
	return seen


func test_starting_a_glide_leaves_the_drive_s_autopilot_engaged() -> void:
	var sim := _started_on_autopilot()

	assert_bool(sim.autopilot(DiveSimulation.STATION_DRIVE)).is_true()
	assert_array(DiveTestKit.types(sim.take_events())).not_contains([&"autopilot_off"])


func test_a_nudge_in_a_glide_started_on_the_autopilot_disengages_it() -> void:
	var sim := _started_on_autopilot()
	sim.set_attended(DiveSimulation.STATION_DRIVE, true)

	sim.nudge_pitch(1)

	assert_bool(sim.autopilot(DiveSimulation.STATION_DRIVE)).is_false()


func test_on_the_autopilot_a_glide_past_the_slack_is_reported_and_leaves_a_raised_time_rate() -> void:
	var sim := _started_on_autopilot()

	var seen := _off_line_at_a_raised_rate(sim)

	assert_bool(seen.shown).override_failure_message("the Drive never showed the Glide off its line").is_true()
	assert_bool(seen.warned).override_failure_message("off the line on the autopilot was a warning").is_false()
	assert_bool(seen.slowed).override_failure_message("the time rate fell on the autopilot").is_false()
	assert_float(sim.head_wear()).is_greater(0.0)


func test_flown_by_nobody_a_glide_past_the_slack_warns_and_drops_a_raised_time_rate() -> void:
	var sim := _gliding()

	var seen := _off_line_at_a_raised_rate(sim)

	assert_bool(seen.shown).is_true()
	assert_bool(seen.warned).is_true()
	assert_bool(seen.slowed).is_true()


func test_off_the_line_on_the_autopilot_becomes_a_warning_once_it_lets_go() -> void:
	var sim := _started_on_autopilot()
	sim.set_time_rate(4.0)
	for i in 30000:
		sim.advance(0.02)
		if sim.call_reason(DiveSimulation.STATION_DRIVE) == &"off_glide_line" or not sim.gliding():
			break
	assert_str(sim.call_reason(DiveSimulation.STATION_DRIVE)).is_equal(&"off_glide_line")
	assert_bool(sim.call_warns(DiveSimulation.STATION_DRIVE)).is_false()

	sim.set_autopilot(DiveSimulation.STATION_DRIVE, false)
	sim.advance(0.02)

	assert_str(sim.call_reason(DiveSimulation.STATION_DRIVE)).is_equal(&"off_glide_line")
	assert_bool(sim.call_warns(DiveSimulation.STATION_DRIVE)).is_true()
	assert_float(sim.time_rate()).is_equal(1.0)


# --- How the crew corrects: nudges nudge the Glide ----------------------------

func test_a_nudge_in_a_glide_turns_it_finely_and_leaves_what_the_drive_steers_for() -> void:
	var nudged := _gliding()
	var alone := _gliding()
	nudged.set_attended(DiveSimulation.STATION_DRIVE, true)
	var heading := nudged.steered_heading()
	var pitch := nudged.steered_pitch()

	nudged.nudge_heading(1)
	DiveTestKit.run(nudged, 2.0, 0.02)
	DiveTestKit.run(alone, 2.0, 0.02)

	assert_float(nudged.glide_nudge_degrees()).is_less(nudged.nudge_degrees())
	assert_float(nudged.glide_off_line().x).is_greater(alone.glide_off_line().x)
	assert_bool(nudged.overriding()).is_false()
	assert_float(nudged.steered_heading()).is_equal(heading)
	assert_float(nudged.steered_pitch()).is_equal(pitch)


func test_a_pitch_nudge_in_a_glide_turns_it_steeper() -> void:
	var nudged := _gliding()
	var alone := _gliding()
	nudged.set_attended(DiveSimulation.STATION_DRIVE, true)

	nudged.nudge_pitch(1)
	DiveTestKit.run(nudged, 2.0, 0.02)
	DiveTestKit.run(alone, 2.0, 0.02)

	assert_float(nudged.glide_off_line().y).is_greater(alone.glide_off_line().y)
	assert_float(nudged.glide_off_line().x).is_equal_approx(alone.glide_off_line().x, 1e-6)


# --- What pushes it ----------------------------------------------------------

func test_the_push_is_seeded_so_the_same_glide_flown_the_same_drifts_the_same() -> void:
	var one := _gliding()
	var two := _gliding()
	var one_off := []
	var two_off := []

	DiveTestKit.fly_glide(one, false, Vector2.ZERO, [], 0.02, one_off)
	DiveTestKit.fly_glide(two, false, Vector2.ZERO, [], 0.02, two_off)

	assert_vector(one_off[0]).is_not_equal(Vector2.ZERO)
	assert_vector(two_off[0]).is_equal(one_off[0])
	assert_float(two.head_wear()).is_equal(one.head_wear())


## Soft rock over hard (or the reverse) across a folded Boundary, and the same
## Media with it flat: crossing the fold, the rock is harder on one side.
func _folded(first: Medium, second: Medium, folded: bool) -> MediumLayout:
	var layout := _layers(first, second)
	return layout.with_waviness(8.0, 60.0, 5) if folded else layout


## Where a Boundary's surface lies deeper, as metres of Vector2(right,
## steeper) across a vertical Glide's line from a Head at `place` heading
## `heading` degrees: the way the upper Medium reaches further down.
static func _down_dip(layout: MediumLayout, place: Vector3, heading: float) -> Vector2:
	var h := deg_to_rad(heading)
	var right := Vector3(cos(h), 0.0, sin(h))
	var steeper := Vector3(-sin(h), 0.0, cos(h))
	var depth_at := func(at: Vector3) -> float: return layout.boundary_depth_at(0, at.x, at.z)
	return Vector2(depth_at.call(place + right) - depth_at.call(place - right),
			depth_at.call(place + steeper) - depth_at.call(place - steeper))


func test_rock_harder_on_one_side_pushes_the_glide_toward_the_softer_side() -> void:
	for media: Array in [[DiveTestKit.soft(), DiveTestKit.hard()], [DiveTestKit.hard(), DiveTestKit.soft()]]:
		var flat := _gliding(200.0, _folded(media[0], media[1], false))
		var layout := _folded(media[0], media[1], true)
		var folded := _gliding(200.0, layout)
		var heading := folded.heading_degrees()
		var flat_off := []
		var folded_off := []
		var crossed_at := Vector3.ZERO
		var seen := []
		DiveTestKit.fly_glide(flat, false, Vector2.ZERO, [], 0.02, flat_off)
		DiveTestKit.fly_glide(folded, false, Vector2.ZERO, seen, 0.02, folded_off)
		for event: Dictionary in seen:
			if event.type == &"boundary_crossed":
				crossed_at = Vector3(0.0, -event.depth, 0.0)
		var pushed: Vector2 = folded_off[0] - flat_off[0]
		var toward_softer := _down_dip(layout, crossed_at, heading)
		if media[0].hardness > media[1].hardness:
			toward_softer = -toward_softer  # The lower rock reaches up where the fold rises.

		assert_float(pushed.length()).is_greater(0.0)
		assert_float(pushed.dot(toward_softer)).is_greater(0.0)


# --- The line to hold, and where it ends --------------------------------------

func test_the_line_to_hold_points_back_toward_the_line_and_further_the_further_off() -> void:
	var held := _gliding()
	var alone := _gliding()
	DiveTestKit.fly_glide(held, true, Vector2.ZERO, [], 0.02, [], 6.0)
	DiveTestKit.fly_glide(alone, false, Vector2.ZERO, [], 0.02, [], 6.0)
	assert_bool(alone.gliding()).is_true()
	var line := held.course_direction()
	var heading := alone.heading_degrees()
	var h := deg_to_rad(heading)
	var off := alone.glide_off_line()
	var off_world := Vector3(cos(h), 0.0, sin(h)) * off.x + Vector3(-sin(h), 0.0, cos(h)) * off.y
	var aim_alone := _direction_of(alone.glide_aim().x, alone.glide_aim().y)
	var aim_held := _direction_of(held.glide_aim().x, held.glide_aim().y)

	assert_float(off.length()).is_greater(held.glide_off_line().length())
	assert_float(aim_alone.angle_to(line)).is_greater(aim_held.angle_to(line))
	assert_float(aim_alone.dot(off_world)).is_less(0.0)


func test_a_drifting_glide_still_ends_at_its_plotted_length_within_its_drift() -> void:
	var sim := _gliding(300.0)
	var start := sim.head_position()
	var line := sim.course_direction()
	var end := sim.glide_end()
	var length := (end - start).dot(line)
	var last := []

	var ended := DiveTestKit.fly_glide(sim, false, Vector2.ZERO, [], 0.02, last)

	assert_str(ended.by).is_equal(Glide.BY_LENGTH)
	var along := (sim.head_position() - start).dot(line)
	assert_float(along).is_less_equal(length + 0.05)
	assert_float(along).is_greater(length - 0.05)
	assert_float(sim.head_position().distance_to(end)).is_less_equal(last[0].length() + 0.5)
	assert_float(last[0].length()).is_greater(sim.glide_slack())


func test_a_drifting_glide_never_runs_past_what_the_scan_has_shown() -> void:
	var sim := DiveSimulation.new(_layers())
	sim.start_surveyed()
	sim.set_autopilot(DiveSimulation.STATION_REACTOR, true)
	sim.advance(0.1)
	var start := sim.head_position()
	var line := sim.course_direction()
	var reach := sim.glide_reach()
	sim.plot_glide(100000.0)
	sim.start_glide()

	DiveTestKit.fly_glide(sim, false)

	assert_float((sim.head_position() - start).dot(line)).is_less_equal(reach + 0.05)
