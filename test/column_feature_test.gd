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
