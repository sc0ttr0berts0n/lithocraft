# The hull's feel near the crew: how many sparks spit, and how many groans
# start, per metre of outer wall within reach of where the crew are, in the
# Habitat as it is against a room as short as the one the feel was tuned in.
# View logic (HullFeel), stepped by hand with a hull held at one damage.
# Assert relationships, never tuned constants (ADR 0001).
extends GdUnitTestSuite

const Habitat := preload("res://view/habitat.gd")
const STEP := 1.0 / 30.0
const SECONDS := 600.0
## How far along the wall counts as near the crew: half the short room, so
## from its middle the whole of it is near.
const REACH_M := HullFeel.TUNED_IN_M / 2.0
## As dense as before, give or take this share: the two rooms never put the
## same spark at quite the same place.
const GIVE := 0.2
const SEED := 20261127


## A hull taking damage, held at that damage: the feel is stepped, not the dive.
func _damaged() -> DiveSimulation:
	var sim := DiveTestKit.heating(1.0)
	sim.set_autopilot(DiveSimulation.STATION_REACTOR, true)
	var hot := func(s: DiveSimulation) -> bool: return s.hull_taking_damage()
	assert_bool(DiveTestKit.fly_until(sim, hot, 1200.0)).is_true()
	return sim


## The metres of wall within reach of a crew member at `z`, in a room this long.
func _wall_near(z: float, length: float) -> float:
	return minf(z + REACH_M, length / 2.0) - maxf(z - REACH_M, -length / 2.0)


## What the crew at `z` in a room `length` long get from `sim`'s hull over
## SECONDS: {sparks = lit emitters within reach, averaged over the steps, per
## metre of wall within reach; groans = groans started within reach, per
## metre of wall within reach}.
func _felt(sim: DiveSimulation, length: float, z: float) -> Dictionary:
	seed(SEED)
	var feel: HullFeel = auto_free(HullFeel.new())
	feel.sim = sim
	feel.ring_radius = Habitat.OUTER_RADIUS
	feel.length = length
	add_child(feel)
	var groans := [0]
	feel.groaned.connect(func(at: Vector3) -> void: groans[0] += int(absf(at.z - z) <= REACH_M))
	var sparks := 0
	var steps := int(SECONDS / STEP)
	for step in steps:
		feel.step(STEP, Vector3.DOWN, z)
		for spot in feel.spark_spots():
			assert_float(absf(spot.z)).is_less_equal(length / 2.0)
			sparks += int(absf(spot.z - z) <= REACH_M)
	var wall := _wall_near(z, length)
	return {sparks = float(sparks) / steps / wall, groans = groans[0] / wall}


## Asserts the crew `from_cap` metres from an end cap of the Habitat (the
## Head's, or the Tail's if `by_tail`) get what they would that far from the
## same end of the short room.
func _assert_as_dense_as_before(from_cap: float, by_tail: bool) -> void:
	var sim := _damaged()
	var side := 1.0 if by_tail else -1.0
	var before := _felt(sim, HullFeel.TUNED_IN_M, side * (HullFeel.TUNED_IN_M / 2.0 - from_cap))
	var now := _felt(sim, Habitat.LENGTH, side * (Habitat.LENGTH / 2.0 - from_cap))

	assert_float(before.sparks).is_greater(0.0)
	assert_float(before.groans).is_greater(0.0)
	assert_float(now.sparks).is_between(before.sparks * (1.0 - GIVE), before.sparks * (1.0 + GIVE))
	assert_float(now.groans).is_between(before.groans * (1.0 - GIVE), before.groans * (1.0 + GIVE))


func test_the_habitat_is_longer_than_the_room_the_feel_was_tuned_in() -> void:
	assert_float(Habitat.LENGTH).is_greater(HullFeel.TUNED_IN_M)


func test_on_the_head_end_floor_sparks_and_groans_are_as_dense_as_in_the_short_room() -> void:
	_assert_as_dense_as_before(CrewMember.BODY, false)


func test_at_the_ring_by_the_head_sparks_and_groans_are_as_dense_as_in_the_short_room() -> void:
	_assert_as_dense_as_before(Habitat.RING_ABOVE_HEAD_FLOOR, false)


func test_at_the_ring_by_the_tail_sparks_and_groans_are_as_dense_as_in_the_short_room() -> void:
	_assert_as_dense_as_before(Habitat.RING_ABOVE_TAIL_FLOOR, true)


func test_on_the_tail_end_cap_sparks_and_groans_are_as_dense_as_in_the_short_room() -> void:
	_assert_as_dense_as_before(CrewMember.BODY, true)


func test_part_way_along_the_slide_sparks_and_groans_are_as_dense_as_at_its_ends() -> void:
	var sim := _damaged()
	var by_head := _felt(sim, Habitat.LENGTH, Habitat.ring_z(0.0))
	var part_way := _felt(sim, Habitat.LENGTH, Habitat.ring_z(0.5))

	assert_float(part_way.sparks).is_between(by_head.sparks * (1.0 - GIVE), by_head.sparks * (1.0 + GIVE))
	assert_float(part_way.groans).is_between(by_head.groans * (1.0 - GIVE), by_head.groans * (1.0 + GIVE))


func test_the_same_moment_sparks_and_groans_from_the_same_places() -> void:
	var sim := _damaged()
	var heard := [[], []]
	var seen := [[], []]
	for run in 2:
		seed(SEED)
		var feel: HullFeel = auto_free(HullFeel.new())
		feel.sim = sim
		feel.length = Habitat.LENGTH
		add_child(feel)
		feel.groaned.connect(func(at: Vector3) -> void: heard[run].append(at))
		for step in 1800:
			feel.step(STEP, Vector3.DOWN, Habitat.ring_z())
		seen[run] = feel.spark_spots()

	assert_array(seen[0]).is_not_empty()
	assert_array(heard[0]).is_not_empty()
	assert_array(seen[1]).is_equal(seen[0])
	assert_array(heard[1]).is_equal(heard[0])


func test_the_habitat_tells_the_feel_where_the_crew_are() -> void:
	var habitat := DiveTestKit.staged_habitat(self, Scenario.first_dive())
	var feel: HullFeel = habitat.find_children("*", "HullFeel", false, false)[0]
	habitat._physics_process(1.0 / 60.0)
	var standing := feel.near_crew()
	habitat.seat_at(DiveSimulation.STATION_DRIVE)
	habitat._physics_process(1.0 / 60.0)
	var seated := feel.near_crew()
	var ring: float = DiveTestKit.station(habitat, "Drive").position.z

	# Standing on the Head end cap the stretch starts at the cap; seated it
	# has the ring of Stations inside it.
	assert_float(standing.x).is_equal_approx(-Habitat.LENGTH / 2.0, 0.001)
	assert_float(seated.x).is_less(ring)
	assert_float(seated.y).is_greater(ring)
	assert_float(seated.y - seated.x).is_equal_approx(HullFeel.TUNED_IN_M, 0.001)
