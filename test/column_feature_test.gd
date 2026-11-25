# Features of interest in the Column, observed and recorded at the Bore
# Station, tested at the simulation's interface. Assert relationships, never
# tuned constants (ADR 0001).
extends GdUnitTestSuite

const FEATURE_DEPTH := 20.0


## Test values only: an easy Medium with plenty of grip, so power maps
## straight to speed.
func _rock() -> Medium:
	return Medium.new(&"rock", 1.0, 1.0, 0.1, 300.0, 1.0, {&"quartz": 1.0}, 0.5)


## Test values only: a feature to find.
func _curiosity() -> ColumnFeature:
	return ColumnFeature.new(&"curiosity", 0.3, 50.0)


func _layout_with_one_feature() -> MediumLayout:
	return MediumLayout.uniform(_rock()).with_features([[FEATURE_DEPTH, _curiosity()]])


func _in_column(sim: DiveSimulation) -> Array[ColumnFeature]:
	return sim.features_in_column()


func _found(sim: DiveSimulation, id: int) -> ColumnFeature:
	for feature in sim.found_features():
		if feature.id == id:
			return feature
	return null


## Advances in small steps until the Head has found the feature, then returns
## its id.
func _advance_until_found(sim: DiveSimulation) -> int:
	for i in 100000:
		sim.advance(0.05)
		var found := sim.features_in_column()
		if not found.is_empty():
			return found[0].id
	fail("The feature was never found")
	return -1


## Advances in small steps until the feature has left the Column.
func _advance_until_gone(sim: DiveSimulation, id: int) -> void:
	for i in 100000:
		sim.advance(0.05)
		if sim.features_in_column().all(func(f: ColumnFeature) -> bool: return f.id != id):
			return
	fail("The feature never left the Column")


func test_a_feature_appears_in_the_column_once_the_head_reaches_it() -> void:
	var sim := DiveSimulation.new(_layout_with_one_feature())
	sim.set_power(0.5)

	while sim.depth() < FEATURE_DEPTH - 1.0:
		sim.advance(0.1)
		assert_array(sim.features_in_column()).is_empty()

	var id := _advance_until_found(sim)
	var feature := _found(sim, id)
	assert_str(feature.kind).is_equal(&"curiosity")
	assert_float(sim.distance() - feature.at).is_between(0.0, sim.column_length())


func test_a_feature_slides_toward_the_tail_at_the_vessels_speed_and_leaves() -> void:
	var sim := DiveSimulation.new(_layout_with_one_feature())
	sim.set_power(0.5)
	var id := _advance_until_found(sim)
	var at := _found(sim, id).at

	var behind_before := sim.distance() - at
	sim.advance(1.0)
	var behind_after := sim.distance() - _in_column(sim)[0].at
	assert_float(behind_after - behind_before).is_equal_approx(sim.speed() * 1.0, 0.0001)
	# Where it lies along the path does not change: the Column does not move,
	# the vessel does.
	assert_float(_in_column(sim)[0].at).is_equal(at)

	_advance_until_gone(sim, id)
	assert_float(sim.distance() - at).is_greater(sim.column_length())


func test_a_feature_can_be_recorded_only_while_it_is_between_the_head_and_the_tail() -> void:
	var sim := DiveSimulation.new(_layout_with_one_feature())
	sim.set_power(0.5)
	# Before the Head reaches it there is nothing to observe.
	sim.set_observed_feature(0)
	sim.advance(1.0)
	assert_int(sim.observed_feature()).is_equal(-1)

	var id := _advance_until_found(sim)
	sim.set_observed_feature(id)
	assert_int(sim.observed_feature()).is_equal(id)
	sim.advance(0.5)
	var while_inside := _found(sim, id).recorded
	assert_float(while_inside).is_greater(0.0)

	# Driven fast, it leaves through the Tail before the record is done...
	sim.set_power(1.0)
	_advance_until_gone(sim, id)
	var as_it_left := _found(sim, id).recorded
	assert_float(as_it_left).is_less(1.0)
	# ...and once gone, no more of it can be recorded, moving or stopped.
	sim.advance(30.0)
	sim.set_power(0.0)
	sim.advance(300.0)
	assert_float(_found(sim, id).recorded).is_equal(as_it_left)
	assert_bool(_found(sim, id).is_recorded()).is_false()


func test_a_stopped_vessel_can_record_a_feature_in_full() -> void:
	var sim := DiveSimulation.new(_layout_with_one_feature())
	sim.set_power(0.5)
	var id := _advance_until_found(sim)
	sim.set_observed_feature(id)

	sim.set_power(0.0)
	sim.advance(600.0)

	assert_bool(_found(sim, id).is_recorded()).is_true()
	assert_float(_found(sim, id).recorded).is_equal(1.0)


## Observes the feature from the moment it is found until it leaves the
## Column, at one power setting, and returns how much of it was recorded.
func _recorded_passing_at(power: float) -> float:
	var sim := DiveSimulation.new(_layout_with_one_feature())
	sim.set_power(power)
	var id := _advance_until_found(sim)
	sim.set_observed_feature(id)
	_advance_until_gone(sim, id)
	return _found(sim, id).recorded


func test_moving_slower_gives_more_time_to_record_a_feature() -> void:
	var fast := _recorded_passing_at(1.0)
	var slow := _recorded_passing_at(0.1)

	assert_float(fast).is_greater(0.0)
	assert_float(slow).is_greater(fast)
