# Repair bills at the surface: what a dive cost the Lithocraft, deducted from
# what it was paid. Tested at the simulation's interface. Assert
# relationships, never tuned constants (ADR 0001).
extends GdUnitTestSuite

## Simulated seconds before a dive is given up on, and the step to run it in.
const PLENTY_S := 20000.0
const STEP_S := 0.25
## How deep the test dives go before turning back, metres.
const TURN_AT_M := 60.0
## Drive power for the test dives: low enough that cool rock never wears the
## hull with the heat sent outward.
const POWER := 0.5


## Test values only: porous rock the melt lines, so the tunnel stays open and
## the fast link carries the survey up.
func _rock(temperature := 300.0) -> Medium:
	return Medium.new(&"open", 1.0, 3.0, 0.5, temperature, 1.0, {&"quartz": 1.0}, 0.5)


## Cool rock with a pocket around TURN_AT_M hotter than the hull bears:
## lingering in it wears the hull at any power.
func _hot_pocket() -> MediumLayout:
	var bears := DiveSimulation.new(MediumLayout.uniform(_rock())).hull_damage_temperature()
	return MediumLayout.layered([[0.0, _rock()], [TURN_AT_M - 10.0, _rock(bears * 1.2)],
			[TURN_AT_M + 10.0, _rock()]])


## Cool rock, then softer rock from above TURN_AT_M: one Boundary that needs
## a Shift on the way down and again on the way up.
func _boundary() -> MediumLayout:
	var softer := Medium.new(&"softer", 0.5, 3.0, 0.5, 300.0, 1.0, {&"feldspar": 1.0}, 0.5)
	return MediumLayout.layered([[0.0, _rock()], [TURN_AT_M - 20.0, softer]])


## Down to TURN_AT_M, a stop of `linger` seconds with the Drive at rest, then
## straight back up to the surface, with every bit of heat sent outward the
## whole way so the Column is recorded alike. A crew at the Reactor makes
## every Shift on the plasma's frequency as it comes due; without one
## (`crew_shifts` false) the autopilot Shifts late. Returns the &"paid"
## event, or an empty Dictionary if the dive never surfaced.
func _dive_and_surface(layout: MediumLayout, linger := 0.0, crew_shifts := true) -> Dictionary:
	var sim := DiveSimulation.new(layout)
	sim.set_attended(DiveSimulation.STATION_THERMAL, true)
	sim.set_attended(DiveSimulation.STATION_DRIVE, true)
	sim.set_attended(DiveSimulation.STATION_REACTOR, crew_shifts)
	sim.set_heat_split(0.0)
	sim.set_power(POWER)
	var shift := func() -> void: if crew_shifts and sim.shift_due(): sim.shift(sim.plasma_frequency())
	while sim.depth() < TURN_AT_M:
		shift.call()
		sim.advance(STEP_S)
	sim.set_power(0.0)
	DiveTestKit.run(sim, linger, STEP_S)
	sim.set_power(POWER)
	sim.set_course(sim.course_heading(), -90.0)
	sim.take_events()
	return DiveTestKit.run_until(sim, &"paid", PLENTY_S, [], STEP_S, shift)


func test_a_more_worn_hull_surfaces_to_a_larger_hull_repair_and_a_smaller_payment() -> void:
	var layout := _hot_pocket()
	var brief := _dive_and_surface(layout)
	var long := _dive_and_surface(layout, 60.0)

	assert_dict(brief).is_not_empty()
	assert_dict(long).is_not_empty()
	assert_float(long.hull_repair).is_greater(brief.hull_repair)
	assert_float(long.amount).is_less(brief.amount)
	# The repair is what makes the difference: the same Column was recorded.
	assert_float(long.by_link + long.carried_home).is_equal_approx(
			brief.by_link + brief.carried_home, 0.001)


func test_a_more_worn_head_surfaces_to_a_larger_head_repair() -> void:
	var layout := _boundary()
	var crewed := _dive_and_surface(layout)
	var autopiloted := _dive_and_surface(layout, 0.0, false)

	assert_dict(crewed).is_not_empty()
	assert_dict(autopiloted).is_not_empty()
	assert_float(autopiloted.head_repair).is_greater(crewed.head_repair)
