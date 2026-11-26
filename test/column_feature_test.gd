# Features of interest in the Column, observed and recorded at the Bore
# Station, tested at the simulation's interface. Assert relationships, never
# tuned constants (ADR 0001).
extends GdUnitTestSuite

const FEATURE_DEPTH := 20.0


## Test values only: a feature to find.
func _curiosity() -> ColumnFeature:
	return ColumnFeature.new(&"curiosity", 0.3, 50.0)


func _layout_with_one_feature() -> MediumLayout:
	return MediumLayout.uniform(DiveTestKit.rock(1.0, 1.0, 0.1)).with_features([[FEATURE_DEPTH, _curiosity()]])


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


func test_the_first_dive_meets_features_from_time_to_time_in_every_medium() -> void:
	var sim := DiveSimulation.new(MediumLayout.first_dive())
	sim.set_power(1.0)
	# Nobody at the Reactor or Thermal: their autopilots see the dive through.
	sim.set_autopilot(DiveSimulation.STATION_REACTOR, true)
	sim.set_autopilot(DiveSimulation.STATION_THERMAL, true)
	var media_with_features := {}
	var gaps: Array[float] = []
	var last_at := 0.0
	while sim.depth() < 1200.0:
		sim.advance(1.0)
	for feature in sim.found_features():
		media_with_features[sim.column_at(sim.distance() - feature.at).name] = true
		gaps.append(feature.at - last_at)
		last_at = feature.at

	assert_array(media_with_features.keys()).contains_exactly_in_any_order(
			[&"sand", &"sandstone", &"granite"])
	# From time to time: never two at once in the Column, never a long drought.
	for gap in gaps:
		assert_float(gap).is_greater(sim.vessel_length())
		assert_float(gap).is_less(400.0)


func test_a_feature_appears_in_the_column_once_the_head_reaches_it() -> void:
	var sim := DiveSimulation.new(_layout_with_one_feature())
	sim.set_power(0.5)

	while sim.depth() < FEATURE_DEPTH - 1.0:
		sim.advance(0.1)
		assert_array(sim.features_in_column()).is_empty()

	var id := _advance_until_found(sim)
	var feature := _found(sim, id)
	assert_str(feature.kind).is_equal(&"curiosity")
	assert_float(sim.distance() - feature.at).is_between(0.0, sim.vessel_length())


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
	assert_float(sim.distance() - at).is_greater(sim.vessel_length())


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


## Dives past the feature, stopping while it is in the Column, observing it or
## not, then carries on until it has left. The two dives cover the same path.
func _dive_past_feature(observe: bool) -> DiveSimulation:
	var sim := DiveSimulation.new(_layout_with_one_feature())
	sim.set_power(0.5)
	var id := _advance_until_found(sim)
	if observe:
		sim.set_observed_feature(id)
	sim.set_power(0.0)
	sim.advance(600.0)
	sim.set_power(0.5)
	while sim.distance() < FEATURE_DEPTH + 40.0:
		sim.advance(0.5)
	return sim


func test_a_recorded_feature_raises_the_surveys_value() -> void:
	var ignored := _dive_past_feature(false)
	var recorded := _dive_past_feature(true)

	assert_int(recorded.survey().size()).is_equal(ignored.survey().size())
	assert_float(ignored.survey_value()).is_greater(0.0)
	assert_float(recorded.survey_value()).is_greater(ignored.survey_value())


func test_a_half_recorded_feature_adds_nothing() -> void:
	var ignored := DiveSimulation.new(_layout_with_one_feature())
	var rushed := DiveSimulation.new(_layout_with_one_feature())
	for sim in [ignored, rushed]:
		sim.set_power(1.0)
		var id := _advance_until_found(sim)
		if sim == rushed:
			sim.set_observed_feature(id)
		_advance_until_gone(sim, id)
	assert_bool(rushed.found_features()[0].recorded > 0.0).is_true()

	assert_float(rushed.survey_value()).is_equal_approx(ignored.survey_value(), 0.0001)


func test_nothing_can_be_extracted_from_the_column() -> void:
	var sim := _dive_past_feature(true)
	var feature: ColumnFeature = sim.found_features()[0]
	assert_bool(feature.is_recorded()).is_true()
	# Recording it left it in the Column: it went out through the Tail.
	assert_float(sim.distance() - feature.at).is_greater(sim.vessel_length())
	assert_array(sim.features_in_column()).is_empty()
	# The Column there is still the Medium it always was.
	var behind := sim.distance() - feature.at
	assert_str(sim.column_at(behind).name).is_equal(DiveTestKit.rock(1.0, 1.0, 0.1).name)
	# And the simulation offers no command that takes anything out.
	for method in sim.get_script().get_script_method_list():
		var method_name := String(method.name).to_lower()
		for word in ["extract", "sample", "cut", "collect", "remove"]:
			assert_bool(method_name.contains(word)) \
					.override_failure_message("%s looks like extraction" % method.name) \
					.is_false()


func test_a_shuttered_bore_records_a_feature_more_slowly() -> void:
	var open := DiveSimulation.new(_layout_with_one_feature())
	var shuttered := DiveSimulation.new(_layout_with_one_feature())
	for sim in [open, shuttered]:
		sim.set_power(0.5)
		var id := _advance_until_found(sim)
		sim.set_observed_feature(id)
		sim.set_power(0.0)
	shuttered.set_quiet_ship(true)

	open.advance(2.0)
	shuttered.advance(2.0)

	assert_bool(shuttered.shuttered()).is_true()
	assert_float(shuttered.found_features()[0].recorded).is_less(
			open.found_features()[0].recorded)


func test_a_recorded_feature_is_paid_for_once_its_record_reaches_the_surface() -> void:
	var ignored := _dive_past_feature(false)
	var recorded := _dive_past_feature(true)
	# Stopped, so nothing new is recorded; the link sends up all that is aboard.
	for sim in [ignored, recorded]:
		sim.set_power(0.0)
		sim.advance(100000.0)

	var records := recorded.uploaded_survey().filter(
			func(s: SurveyStretch) -> bool: return s.is_feature_record())
	assert_int(records.size()).is_equal(1)
	assert_str(records[0].feature_kind).is_equal(&"curiosity")
	assert_float(recorded.paid()).is_greater(ignored.paid())
	# All of it is up, so what was paid is what the survey is worth.
	assert_float(recorded.paid()).is_equal_approx(recorded.survey_value(), 0.0001)


func test_a_feature_record_waits_aboard_until_the_link_sends_it() -> void:
	var sim := DiveSimulation.new(_layout_with_one_feature())
	sim.set_power(0.5)
	var id := _advance_until_found(sim)
	sim.set_observed_feature(id)
	sim.set_power(0.0)
	var paid_before := sim.paid()

	# Record it in small steps: the moment it is complete, it is worth more to
	# the survey than has been paid for it.
	while not _found(sim, id).is_recorded():
		sim.advance(0.1)
	assert_float(sim.survey_value()).is_greater(sim.paid())

	sim.advance(100000.0)
	assert_float(sim.paid()).is_greater(paid_before)
