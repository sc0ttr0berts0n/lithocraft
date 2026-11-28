# The Prospecting drill (ticket #124): halted in the granite above a target
# the survey places only roughly. It can be finished as its Checklist asks:
# narrow the region, aim the Beam, plot the Course into it, crawl through it
# and record it; and a dive straight down passes the target by. Tested at the
# simulation's interface. Assert relationships, never tuned constants
# (ADR 0001).
extends GdUnitTestSuite


func _drill() -> DiveSimulation:
	var sim := Scenario.prospecting_drill().start()
	sim.read_orders()
	return sim


func _region(sim: DiveSimulation) -> TargetRegion:
	return sim.target_regions()[0]


func _in_column(sim: DiveSimulation) -> ColumnFeature:
	for feature in sim.features_in_column():
		if feature.target == &"A":
			return feature
	return null


## Waits until the Head is spun down and the vessel silent.
func _quiet(sim: DiveSimulation) -> void:
	for i in 600:
		sim.advance(0.1)
		if sim.noise() == 0.0:
			return


func test_the_drill_begins_halted_with_target_a_named_in_the_orders_and_its_place_in_the_scan() -> void:
	var sim := _drill()
	assert_bool(sim.quiet_ship()).is_true()
	assert_float(sim.speed()).is_equal(0.0)
	assert_array(sim.orders().map(func(goal: Dictionary) -> String: return goal.text)).contains(
			[Scenario.identify_target(&"A").text])
	assert_int(sim.target_regions().size()).is_equal(1)
	assert_str(_region(sim).label).is_equal(&"A")


func test_a_dive_straight_down_passes_the_target_by() -> void:
	var sim := _drill()
	var below := -_region(sim).centre.y + _region(sim).half_size.y
	sim.set_quiet_ship(false)
	sim.set_autopilot(DiveSimulation.STATION_DRIVE, true)
	while sim.depth() < below:
		sim.advance(1.0)
	assert_array(sim.found_features().filter(func(f: ColumnFeature) -> bool: return f.target == &"A")).is_empty()


func test_the_drill_is_finished_by_narrowing_the_region_and_crawling_into_it() -> void:
	var sim := _drill()
	_quiet(sim)
	var before := _region(sim)
	sim.pulse()
	sim.advance(0.5)
	assert_str(DiveTestKit.next_step_id(sim)).is_equal(&"aim")
	# Aim the narrow Beam at the region as it now stands, and pulse again.
	var toward := (_region(sim).centre - sim.head_position()).normalized()
	sim.set_beam_width(DiveSimulation.BEAM_NARROW)
	sim.set_beam_aim(rad_to_deg(atan2(toward.x, -toward.y)), 0.0)
	sim.pulse()
	sim.advance(0.5)
	var after := _region(sim)
	assert_float(after.volume()).is_less(before.volume())
	# Plot the Course as the keys can: one pitch step off straight down, its
	# heading toward the region.
	var off := after.centre - sim.head_position()
	sim.set_course(rad_to_deg(atan2(off.x, -off.z)), 75.0)
	sim.advance(0.5)
	sim.set_quiet_ship(false)
	sim.set_autopilot(DiveSimulation.STATION_DRIVE, true)
	var feature: ColumnFeature = null
	for i in 4000:
		sim.advance(1.0)
		feature = _in_column(sim)
		if feature != null:
			break
	assert_object(feature).override_failure_message("never crawled into target A").is_not_null()
	sim.set_observed_feature(feature.id)
	sim.set_power(0.0)
	for i in 600:
		sim.advance(1.0)
		if sim.identified_targets().has(&"A"):
			break
	assert_bool(DiveTestKit.achieved(sim, Scenario.identify_target(&"A").id)).is_true()
	for phase in sim.checklist():
		for step in phase.steps:
			assert_str(step.state).override_failure_message("%s left %s" % [step.id, step.state]).is_equal(DiveSimulation.STEP_DONE)
