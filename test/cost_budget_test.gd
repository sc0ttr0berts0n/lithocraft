# Tests of the cost budget (tools/cost): the tally and its verdict
# (CostBudget), given costs made up here in baselines, never timed, and the
# probe (CostProbe) on a staged Habitat, read for what it names and never for
# how long anything took. The measurement itself is run by tools/cost/cost.sh
# (docs/conventions/cost-budget.md).
extends GdUnitTestSuite

const QUIET := "quiet"
const TURNING := "turning"


## A budget on a machine whose baseline takes `baseline` milliseconds, with
## `frames` frames tallied under each of two conditions, every part costing
## `part` baselines.
func _budget(baseline := 1.0, part := 1.0, frames := 10) -> CostBudget:
	var budget := CostBudget.new()
	budget.baseline_ms = baseline
	for condition: String in [QUIET, TURNING]:
		for frame in frames:
			budget.add_frame(condition, _frame(baseline * part))
		budget.add_query(condition, "depth", 0.01 * baseline)
		budget.add_query(condition, "projected_path", 0.5 * baseline)
	return budget


func _frame(ms: float) -> Dictionary:
	return {"Simulation / step": ms, "Reactor / PlasmaDisplay": ms, "Navigation / ScanDisplay": ms,
			"Navigation / MovingMap": ms}


func test_a_run_well_inside_the_budget_passes() -> void:
	var budget := _budget()

	assert_array(budget.over()).is_empty()
	assert_str(budget.report()[-1]).is_equal("COST OK")


func test_the_slowest_station_is_the_one_whose_parts_sum_to_most() -> void:
	var budget := _budget()

	# No one part of Navigation costs more than the Reactor's, but its two do.
	assert_str(budget.slowest_station()).is_equal("Navigation")
	assert_str("\n".join(budget.report())).contains("slowest Station: Navigation")


func test_the_slowest_query_is_the_one_with_the_dearest_call() -> void:
	var budget := _budget()

	assert_str(budget.slowest_query()).is_equal("projected_path")
	assert_str("\n".join(budget.report())).contains("slowest query: projected_path()")


func test_one_frame_past_the_worst_budget_fails_and_names_what_took_longest_in_it() -> void:
	var budget := _budget()
	var hitch := _frame(1.0)
	hitch["Navigation / MovingMap"] = CostBudget.WORST_FRAME_BASELINES * 1.5
	budget.add_frame(TURNING, hitch)

	var over := budget.over()
	assert_int(over.size()).is_equal(1)
	assert_str(over[0]).contains("worst frame").contains(TURNING).contains("Navigation").contains("MovingMap")
	assert_str(budget.report()[-1]).is_equal("COST OVER BUDGET")


func test_a_condition_whose_mean_frame_is_past_the_budget_fails_though_the_run_s_mean_is_not() -> void:
	var budget := _budget(1.0, 1.0, 100)
	for frame in 10:
		var slow := _frame(1.0)
		slow["Reactor / PlasmaDisplay"] = CostBudget.MEAN_FRAME_BASELINES * 1.5
		budget.add_frame("slow", slow)

	assert_float(budget.mean_frame_ms()).is_less(CostBudget.MEAN_FRAME_BASELINES)
	var over := budget.over()
	assert_int(over.size()).is_equal(1)
	assert_str(over[0]).contains("mean frame").contains("\"slow\"").contains("Reactor").contains("PlasmaDisplay")


func test_a_query_whose_one_call_is_past_the_budget_fails_and_is_named() -> void:
	var budget := _budget()
	budget.add_query(TURNING, "projected_path", CostBudget.QUERY_BASELINES * 1.5)

	var over := budget.over()
	assert_int(over.size()).is_equal(1)
	assert_str(over[0]).contains("projected_path()").contains(TURNING)


func test_a_slower_machine_gets_the_same_verdict() -> void:
	# Everything, the baseline with it, three times as long: inside as before.
	assert_array(_budget(3.0).over()).is_empty()
	# And a frame that is over stays over on a machine three times as quick.
	var quick := _budget(1.0 / 3.0)
	var hitch := _frame(1.0 / 3.0)
	hitch["Navigation / ScanDisplay"] = CostBudget.WORST_FRAME_BASELINES * 1.5 / 3.0
	quick.add_frame(QUIET, hitch)
	assert_int(quick.over().size()).is_equal(1)
	# The same milliseconds against the slower machine's baseline are inside.
	var slow := _budget(3.0)
	slow.add_frame(QUIET, hitch)
	assert_array(slow.over()).is_empty()


func test_a_frame_of_the_probe_charges_the_simulation_and_every_station_s_screen() -> void:
	var habitat := DiveTestKit.staged_habitat(self, Scenario.shift_drill())
	var probe := CostProbe.new(habitat)
	await probe.frame()
	await get_tree().process_frame

	var cost: Dictionary = await probe.frame()

	var groups := {}
	for part: String in cost:
		groups[part.get_slice(CostBudget.JOIN, 0)] = true
		assert_float(cost[part]).is_greater(0.0)
	assert_bool(cost.has(CostProbe.SIMULATION_STEP)).is_true()
	for station in DiveTestKit.stations(habitat):
		assert_bool(groups.has(station.station_name)).override_failure_message(
				"no cost charged to %s" % station.station_name).is_true()
	# The displays that hang off the Habitat are charged to their Stations.
	assert_bool(cost.has("Navigation / ScanDisplay") or cost.has("Navigation / MovingMap")).is_true()
	assert_bool(cost.has("Drive / FlightDisplay")).is_true()


func test_the_probe_steps_the_habitat_one_game_step_a_frame_and_its_twin_beside_it() -> void:
	var habitat := DiveTestKit.staged_habitat(self, Scenario.shift_drill())
	var probe := CostProbe.new(habitat)
	var sim: DiveSimulation = habitat.simulation()
	probe.send(&"set_power", [1.0])

	for frame in 5:
		await probe.frame()
		await get_tree().process_frame

	assert_float(sim.dive_time()).is_equal_approx(5.0 * CostProbe.STEP, CostProbe.STEP / 10.0)
	assert_float(sim.power()).is_equal(1.0)
	assert_float(probe.twin_drift()).is_equal(0.0)


func test_the_queries_timed_are_the_simulation_s_readings_and_none_of_its_commands() -> void:
	var queries := CostProbe.queries()

	for polled: String in ["projected_path", "points", "inferred_boundaries", "depth", "plasma_stability"]:
		assert_bool(polled in queries).override_failure_message("%s is not timed" % polled).is_true()
	for command: String in ["pulse", "shift", "relight", "new_dive", "take_events", "advance"]:
		assert_bool(command in queries).override_failure_message("%s would be called" % command).is_false()
	# Nor a debug command, which answers too.
	for query in queries:
		assert_bool(query.begins_with("debug")).override_failure_message("%s would be called" % query).is_false()

	var habitat := DiveTestKit.staged_habitat(self, Scenario.shift_drill())
	var probe := CostProbe.new(habitat)
	await probe.frame()
	var before: float = habitat.simulation().dive_time()
	assert_array(probe.time_queries().keys()).contains_exactly_in_any_order(Array(queries))
	assert_float(habitat.simulation().dive_time()).is_equal(before)
	assert_float(probe.twin_drift()).is_equal(0.0)
