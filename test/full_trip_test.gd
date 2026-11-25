# The full trip: from the surface of the first dive's desert, through sand,
# sandstone and granite to a few kilometres down, an arc back, surfacing and
# selling the survey. Tested at the simulation's interface. Assert
# relationships, never tuned constants (ADR 0001).
extends GdUnitTestSuite

## How deep the scripted dive goes before turning back: "a few kilometres".
const TURN_AT_M := 2000.0
## Simulated seconds before a scripted dive is given up on.
const GIVE_UP_S := 60000.0


## Flies the first dive the way a solo player at the Reactor and Thermal
## Stations would: Drive at `power`, heat split `to_column`, a Shift on the
## plasma's frequency whenever one is due, time run fast between calls. The
## Course is straight down until TURN_AT_M, when Navigation plots it straight
## up; the unattended Drive follows it round its gentle arc until the
## Lithocraft surfaces. Stops at the payment. Returns {sim, events, deepest}.
func _full_trip(to_column := 0.0, power := 1.0) -> Dictionary:
	var sim := DiveSimulation.new(MediumLayout.first_dive())
	sim.set_attended(DiveSimulation.STATION_REACTOR, true)
	sim.set_attended(DiveSimulation.STATION_THERMAL, true)
	sim.set_power(power)
	sim.set_heat_split(to_column)
	var events := []
	var deepest := 0.0
	var seconds := 0.0
	while seconds < GIVE_UP_S:
		var before := sim.distance()
		sim.set_time_rate(sim.max_time_rate())
		sim.advance(1.0)
		seconds += 1.0
		deepest = maxf(deepest, sim.depth())
		if sim.depth() >= TURN_AT_M and sim.course_pitch() > -90.0:
			sim.set_course(sim.course_heading(), -90.0)
			assert_bool(sim.attended(DiveSimulation.STATION_DRIVE)).is_false()
		if sim.shift_due():
			sim.shift(sim.plasma_frequency())
		var done := false
		for event in sim.take_events():
			events.append(event)
			done = done or event.type == &"paid"
		if done or (sim.distance() == before and sim.speed() == 0.0 and seconds > 10.0):
			break
	return {sim = sim, events = events, deepest = deepest}


## What a trip down to TURN_AT_M and back should meet, read from the first
## dive's layout rather than written out, so the layout can be retuned: each
## Boundary above the turn crossed on the way down, the tunnel sealing once the
## Head has gone from rock with pore space into rock without, the same
## Boundaries crossed the other way on the way up, then surfacing and the pay.
static func _story_of_the_layout(seal_porosity: float) -> Array:
	var layout := MediumLayout.first_dive()
	var down := []
	var up := []
	var sealing := false
	for depth in layout.boundary_depths():
		if depth >= TURN_AT_M:
			continue
		var above := layout.medium_at(depth - 0.01)
		var below := layout.medium_at(depth + 0.01)
		down.append("boundary_crossed %s>%s" % [above.name, below.name])
		up.push_front("boundary_crossed %s>%s" % [below.name, above.name])
		if not sealing and above.porosity >= seal_porosity and below.porosity < seal_porosity:
			sealing = true
			down.append("tunnel_sealed")
	return down + up + ["surfaced", "paid"]


static func _of_types(events: Array, types: Array) -> Array:
	return events.filter(func(e: Dictionary) -> bool: return e.type in types)


static func _first(events: Array, type: StringName) -> Dictionary:
	for event in events:
		if event.type == type:
			return event
	return {}


func test_a_full_dive_goes_down_through_both_boundaries_and_back_and_is_paid() -> void:
	var trip := _full_trip()
	var sim: DiveSimulation = trip.sim
	var events: Array = trip.events

	var story := _of_types(events, [&"boundary_crossed", &"tunnel_sealed", &"surfaced", &"paid"])
	var steps := story.map(func(e: Dictionary) -> String:
		return "%s %s>%s" % [e.type, e.get("from", ""), e.get("to", "")] \
				if e.type == &"boundary_crossed" else String(e.type))
	var expected := _story_of_the_layout(sim.seal_porosity())
	assert_array(steps).is_equal(expected)
	# Each Boundary was announced before it was crossed, and every Shift the
	# crew made at one was clean.
	var types := DiveTestKit.types(events)
	var crossings := expected.filter(func(s: String) -> bool: return s.begins_with("boundary"))
	assert_int(types.count(&"boundary_approaching")).is_equal(crossings.size())
	assert_int(types.find(&"boundary_approaching")).is_less(types.find(&"boundary_crossed"))
	var shifts := _of_types(events, [&"shift_result"])
	assert_int(shifts.size()).is_greater_equal(4)
	for shift in shifts:
		assert_bool(shift.clean).is_true()
	assert_bool(sim.plasma_lost()).is_false()
	# A few kilometres down, and back at the surface.
	assert_float(trip.deepest).is_greater_equal(TURN_AT_M)
	assert_float(sim.depth()).is_less_equal(0.0)
	assert_bool(sim.surfaced()).is_true()
	# The survey carried home is sold on surfacing: a payment results and
	# nothing is left aboard.
	var paid := _first(events, &"paid")
	assert_float(paid.amount).is_greater(0.0)
	assert_float(paid.carried_home).is_greater(0.0)
	assert_float(sim.paid()).is_greater_equal(paid.amount)
	assert_float(sim.unsold_value()).is_equal(0.0)


func test_a_dive_that_protected_the_column_pays_more_than_one_that_cooked_it() -> void:
	var protected := _full_trip(0.0)
	var cooked := _full_trip(1.0)

	var protected_paid := _first(protected.events, &"paid")
	var cooked_paid := _first(cooked.events, &"paid")
	assert_dict(protected_paid).is_not_empty()
	assert_dict(cooked_paid).is_not_empty()
	assert_float(protected_paid.amount).is_greater(cooked_paid.amount)
	# And the payment says why: the cooked survey's records are poorer.
	assert_float(protected_paid.mean_quality).is_greater(cooked_paid.mean_quality)
	assert_float(cooked_paid.lost_to_quality).is_greater(protected_paid.lost_to_quality)


func test_the_payment_breaks_down_what_was_paid_and_why() -> void:
	var trip := _full_trip()
	var paid := _first(trip.events, &"paid")

	# What came up the link during the dive plus what was carried home is the
	# whole dive's pay.
	assert_float(paid.by_link + paid.carried_home).is_equal_approx(paid.amount, 0.001)
	assert_float(paid.by_link).is_greater(0.0)
	# Paid for each Medium the dive went through.
	var by_medium: Dictionary = paid.by_medium
	for medium in [&"sand", &"sandstone", &"granite"]:
		assert_float(by_medium.get(medium, 0.0)).is_greater(0.0)
	var medium_total := 0.0
	for medium in by_medium:
		medium_total += by_medium[medium]
	assert_float(medium_total).is_equal_approx(paid.amount, 0.001)
	assert_int(paid.stretches).is_greater(0)
	assert_float(paid.metres).is_greater(TURN_AT_M)
	assert_float(paid.mean_quality).is_between(0.0, 1.0)


func test_after_surfacing_the_crew_can_start_another_dive_straight_away() -> void:
	var trip := _full_trip()
	var sim: DiveSimulation = trip.sim
	var paid := sim.paid()

	# Surfaced, the Lithocraft waits at the surface.
	sim.advance(5.0)
	assert_float(sim.speed()).is_equal(0.0)

	sim.new_dive()
	var types := sim.take_events().map(func(e: Dictionary) -> StringName: return e.type)
	assert_array(types).contains([&"new_dive"])
	assert_bool(sim.surfaced()).is_false()
	assert_float(sim.paid()).is_equal(paid)
	assert_float(sim.depth()).is_equal(0.0)
	assert_float(sim.pitch()).is_equal_approx(90.0, 0.01)
	assert_bool(sim.tunnel_sealed()).is_false()

	sim.set_power(1.0)
	for i in 30:
		sim.advance(1.0)
	assert_float(sim.depth()).is_greater(10.0)


func test_a_new_dive_is_only_for_a_vessel_at_the_surface() -> void:
	var sim := DiveSimulation.new(MediumLayout.first_dive())
	sim.set_power(1.0)
	for i in 30:
		sim.advance(1.0)
	var depth := sim.depth()

	sim.new_dive()

	assert_float(sim.depth()).is_equal(depth)
	assert_array(sim.take_events().map(func(e: Dictionary) -> StringName: return e.type)) \
			.not_contains([&"new_dive"])
