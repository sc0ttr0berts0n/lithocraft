# Targets (ticket #124): a body in the rock surface control's survey has seen
# and cannot identify. The Orders give its place with a wide error, every
# tool that sounds the rock hears its surface and narrows the region, and
# crawling through it puts it in the Column, where observing and recording it
# identifies it, achieves the Orders' goal and pays its own line. Tested at
# the simulation's interface. Assert relationships, never tuned constants
# (ADR 0001).
extends GdUnitTestSuite

## Where the Head starts, metres down, and how far below it the target lies.
const START_M := 400.0
const BELOW_M := 50.0


## Test values only: a body of stiff rock, clearly unlike the host's.
func _body(centre: Vector3) -> TargetBody:
	return TargetBody.new(&"A", &"curiosity_lens", centre, Vector3(6.0, 4.0, 6.0), 8.0, 100.0)


## Test values only: one plain rock, open enough that the tunnel stays open
## (so a lost plasma brings the crew home and the dive is paid), and the
## body placed `off` from straight below the start.
func _layout(off: Vector3) -> MediumLayout:
	return MediumLayout.uniform(DiveTestKit.rock(2.0, 2.0, 0.3)).with_targets(
			[_body(Vector3(0.0, -(START_M + BELOW_M), 0.0) + off)])


## A dive START_M down in the layout, surveyed, its Orders naming target A.
func _dive(off := Vector3.ZERO, surveyed := true) -> DiveSimulation:
	var scenario := Scenario.new()
	scenario.title = "Target test"
	scenario.layout = _layout(off)
	scenario.orders = [Scenario.identify_target(&"A")]
	scenario.prepare = func(sim: DiveSimulation) -> void: _prepare(sim, surveyed)
	return scenario.start()


func _prepare(sim: DiveSimulation, surveyed: bool) -> void:
	sim.start_below(START_M)
	if surveyed:
		sim.start_surveyed()


func _region(sim: DiveSimulation) -> TargetRegion:
	var regions := sim.target_regions()
	assert_int(regions.size()).is_equal(1)
	return regions[0]


func _go_quiet(sim: DiveSimulation) -> void:
	sim.set_quiet_ship(true)
	for i in 600:
		sim.advance(0.1)
		if sim.speed() == 0.0 and sim.noise() == 0.0:
			return


func _goal_id() -> StringName:
	return Scenario.identify_target(&"A").id


func _target_feature(sim: DiveSimulation) -> ColumnFeature:
	for feature in sim.found_features():
		if feature.target == &"A":
			return feature
	return null


## Dives straight down at half power until the Head is this far below the
## start, observing the target as soon as it is in the Column when `observe`.
func _dive_on(sim: DiveSimulation, metres_below: float, observe: bool) -> void:
	sim.set_power(0.5)
	while sim.depth() < START_M + metres_below:
		sim.advance(0.25)
		var feature := _target_feature(sim)
		if observe and feature != null and sim.observed_feature() != feature.id:
			sim.set_observed_feature(feature.id)
			# Halted, it stays in the Bore for as long as recording takes.
			sim.set_power(0.0)
			for i in 2000:
				sim.advance(0.25)
				if sim.identified_targets().has(&"A"):
					break
			sim.set_power(0.5)


## Brings the crew home through the open tunnel and returns the &"paid" event.
func _paid(sim: DiveSimulation) -> Dictionary:
	sim.take_events()
	DiveTestKit.lose_plasma(sim)
	for event in sim.take_events():
		if event.type == &"paid":
			return event
	fail("The dive was never paid")
	return {}


# --- The Orders' place -------------------------------------------------------

func test_the_orders_give_the_targets_place_with_an_error_far_wider_than_the_body() -> void:
	var sim := _dive()
	var region := _region(sim)
	var body := _body(Vector3(0.0, -(START_M + BELOW_M), 0.0))
	assert_str(region.label).is_equal(&"A")
	assert_bool(region.holds(body.centre)).is_true()
	assert_float(region.volume()).is_greater(4.0 * TargetRegion.new(&"", body.centre, body.half_size).volume())


func test_without_the_survey_the_orders_have_no_place_to_give() -> void:
	assert_array(_dive(Vector3.ZERO, false).target_regions()).is_empty()


func test_the_orders_name_the_target() -> void:
	var goal := Scenario.identify_target(&"A")
	assert_str(goal.target).is_equal(&"A")
	assert_str(goal.text).contains("target A")


# --- Prospecting narrows the region -------------------------------------------

func test_a_pulse_that_reaches_the_target_narrows_its_region_round_the_body() -> void:
	var sim := _dive()
	var before := _region(sim)
	_go_quiet(sim)
	sim.pulse()
	sim.advance(0.1)
	var after := _region(sim)
	assert_float(after.volume()).is_less(before.volume())
	assert_float(after.support).is_greater(0.0)
	# Honestly so: it still holds the body.
	assert_bool(after.holds(Vector3(0.0, -(START_M + BELOW_M), 0.0))).is_true()
	assert_array(sim.narrowed_targets()).contains_exactly([&"A"])


func test_a_sweep_that_reaches_a_target_off_to_the_side_narrows_its_region() -> void:
	# Some 55 degrees off the Head's line: outside the Beam's cone, inside the
	# Sweep's spiral.
	var off := Vector3(BELOW_M * 1.4, BELOW_M * 0.0, 0.0)
	var sim := _dive(off)
	_go_quiet(sim)
	var before := _region(sim)
	sim.pulse()
	sim.advance(0.1)
	assert_float(_region(sim).volume()).override_failure_message("the Beam's cone reaches it").is_equal_approx(before.volume(), 0.001)
	sim.set_sweep_range(DiveSimulation.SWEEP_RANGES[0])
	sim.start_sweep()
	DiveTestKit.run_until(sim, &"sweep_ended", 600.0)
	assert_float(_region(sim).volume()).is_less(before.volume())


func test_an_aimed_pulse_narrows_a_target_off_the_beams_axis_and_a_pulse_dead_ahead_does_not() -> void:
	var off := Vector3(BELOW_M * 1.2, 0.0, 0.0)
	var sim := _dive(off)
	_go_quiet(sim)
	var before := _region(sim)
	sim.set_beam_width(DiveSimulation.BEAM_NARROW)
	sim.pulse()
	sim.advance(0.1)
	assert_float(_region(sim).volume()).is_equal_approx(before.volume(), 0.001)
	# Diving straight down with heading 0, the vessel's right is +X.
	var toward := (Vector3(0.0, -(START_M + BELOW_M), 0.0) + off - sim.head_position()).normalized()
	sim.set_beam_aim(rad_to_deg(acos(toward.dot(Vector3.DOWN))), 0.0)
	assert_float(sim.beam_axis().dot(toward)).is_greater(0.99)
	sim.pulse()
	sim.advance(0.1)
	assert_float(_region(sim).volume()).is_less(before.volume())


func test_a_scan_that_reaches_nothing_leaves_the_region_as_the_orders_gave_it() -> void:
	# Far off to the side, and the Beam's cone only straight down.
	var sim := _dive(Vector3(0.0, BELOW_M * 0.5, 120.0))
	_go_quiet(sim)
	var before := _region(sim)
	sim.pulse()
	sim.advance(0.1)
	assert_float(_region(sim).volume()).is_equal_approx(before.volume(), 0.001)
	assert_array(sim.narrowed_targets()).is_empty()


# --- Identified in the Column ------------------------------------------------

func test_crawling_through_the_target_puts_it_in_the_column_as_a_feature_of_its_own_kind() -> void:
	var sim := _dive()
	_dive_on(sim, BELOW_M, false)
	var feature := _target_feature(sim)
	assert_object(feature).is_not_null()
	assert_str(feature.kind).is_equal(_body(Vector3.ZERO).kind)
	# As long as the cut through it, which here is its whole height.
	assert_float(feature.size_m).is_greater(_body(Vector3.ZERO).half_size.y)


func test_crawling_through_and_observing_it_identifies_it_achieves_the_goal_and_pays_its_own_line() -> void:
	var sim := _dive()
	_dive_on(sim, BELOW_M + 20.0, true)
	assert_array(sim.identified_targets()).contains_exactly([&"A"])
	assert_bool(DiveTestKit.achieved(sim, _goal_id())).is_true()
	var paid := _paid(sim)
	assert_array(paid.targets).contains_exactly([&"A"])
	assert_float(paid.target_worth).is_greater(0.0)
	# Its own line, not among the features.
	assert_int(paid.features).is_equal(0)


func test_passing_the_target_by_neither_identifies_it_nor_pays_for_it() -> void:
	var sim := _dive(Vector3(30.0, 0.0, 0.0))
	_dive_on(sim, BELOW_M + 20.0, true)
	assert_object(_target_feature(sim)).is_null()
	assert_array(sim.identified_targets()).is_empty()
	assert_bool(DiveTestKit.achieved(sim, _goal_id())).is_false()
	assert_float(_paid(sim).target_worth).is_equal(0.0)


func test_crawling_through_it_unobserved_neither_identifies_it_nor_pays_for_it() -> void:
	var sim := _dive()
	_dive_on(sim, BELOW_M + 20.0, false)
	assert_object(_target_feature(sim)).is_not_null()
	assert_array(sim.identified_targets()).is_empty()
	assert_bool(DiveTestKit.achieved(sim, _goal_id())).is_false()
	var paid := _paid(sim)
	assert_float(paid.target_worth).is_equal(0.0)
	assert_array(paid.targets).is_empty()
