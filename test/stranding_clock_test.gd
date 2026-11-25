# The stranding clock and rescue, tested at the simulation's interface.
# Assert relationships, never tuned constants (ADR 0001).
extends GdUnitTestSuite


## Test values only. Dense rock the melt fills behind the Tail, so the tunnel
## seals at once; hot, as near a buried magma body, so with the Head dark its
## heat soaks into the hull. It carries no sound: nothing goes up once sealed.
func _hot_dense(temperature := 450.0) -> Medium:
	return Medium.new(&"hot_dense", 1.0, 3.0, 0.0, temperature, 1.0, {&"quartz": 1.0}, 0.0)


## Test values only. Porous rock of the same hardness the melt lines, so the
## tunnel through it stays open.
func _hot_open(temperature := 450.0) -> Medium:
	return Medium.new(&"hot_open", 1.0, 3.0, 0.5, temperature, 1.0, {&"quartz": 1.0}, 0.0)


## A dive straight down for `seconds` at full power, its heat all sent into the
## Column so the hull stays whole, then stranded where it stands.
func _stranded(layout: MediumLayout, seconds: float) -> DiveSimulation:
	var sim := DiveSimulation.new(layout)
	sim.set_attended(DiveSimulation.STATION_THERMAL, true)
	sim.set_heat_split(1.0)
	sim.set_power(1.0)
	DiveTestKit.run(sim, seconds, 0.5)
	DiveTestKit.lose_plasma(sim)
	sim.take_events()
	assert_bool(sim.stranded()).is_true()
	return sim


func test_the_clock_is_shorter_deeper() -> void:
	var shallow := _stranded(MediumLayout.uniform(_hot_dense()), 60.0)
	var deep := _stranded(MediumLayout.uniform(_hot_dense()), 300.0)
	assert_float(deep.depth()).is_greater(shallow.depth())
	assert_float(deep.hull_integrity()).is_equal(shallow.hull_integrity())

	assert_float(deep.stranding_clock()).is_less(shallow.stranding_clock())
	assert_float(deep.stranding_clock()).is_greater(0.0)


func test_the_clock_is_shorter_for_a_more_worn_hull() -> void:
	# Soft rock down to a face the Head can barely cut: both vessels stop
	# there at full power, one sending its heat outward until the hull creeps.
	var face := Medium.new(&"face", 1.0e6, 3.0, 0.0, 450.0, 1.0, {&"quartz": 1.0}, 0.0)
	var layout := MediumLayout.layered([[0.0, _hot_dense()], [100.0, face]])
	var worn := DiveSimulation.new(layout)
	var whole := DiveSimulation.new(layout)
	for sim in [worn, whole]:
		sim.set_autopilot(DiveSimulation.STATION_REACTOR, true)  # It makes the Shift at the face.
		sim.set_heat_split(1.0)
		sim.set_power(1.0)
		DiveTestKit.run(sim, 120.0, 0.5)
	worn.set_heat_split(0.0)
	DiveTestKit.run(worn, 150.0, 0.5)
	DiveTestKit.run(whole, 150.0, 0.5)
	assert_bool(worn.dead()).is_false()
	for sim in [worn, whole]:
		DiveTestKit.lose_plasma(sim)
		assert_bool(sim.stranded()).is_true()
	assert_float(worn.hull_integrity()).is_less(whole.hull_integrity())
	assert_float(worn.depth()).is_equal_approx(whole.depth(), 0.01)

	assert_float(worn.stranding_clock()).is_less(whole.stranding_clock())


## Runs a stranded `sim` until the hull fails and returns how long that took,
## in simulated seconds, or INF if it outlasted `seconds`.
func _time_to_death(sim: DiveSimulation, seconds: float) -> float:
	var t := 0.0
	while t < seconds:
		sim.advance(1.0)
		t += 1.0
		if sim.dead():
			return t
	return INF


func test_spending_the_store_on_cooling_lengthens_the_clock() -> void:
	var cooled := _stranded(MediumLayout.uniform(_hot_dense()), 300.0)
	var left := _stranded(MediumLayout.uniform(_hot_dense()), 300.0)
	cooled.set_attended(DiveSimulation.STATION_THERMAL, true)
	cooled.set_heat_split(1.0)

	assert_float(cooled.stranding_clock()).is_greater(left.stranding_clock())
	var store := cooled.emergency_store()
	cooled.advance(1.0)
	left.advance(1.0)
	assert_float(cooled.emergency_store()).is_less(store)
	assert_float(left.emergency_store()).is_equal(store)
	assert_float(_time_to_death(cooled, 100000.0)).is_greater(_time_to_death(left, 100000.0))


func test_a_longer_sealed_length_is_slower_to_rescue() -> void:
	# The same rock but for its porosity, so both reach the same depth: one
	# sealed behind from 40 m, the other open down to 200 m.
	var long_sealed := _stranded(MediumLayout.layered(
			[[0.0, _hot_open(300.0)], [40.0, _hot_dense(300.0)]]), 200.0)
	var short_sealed := _stranded(MediumLayout.layered(
			[[0.0, _hot_open(300.0)], [200.0, _hot_dense(300.0)]]), 200.0)
	assert_float(long_sealed.depth()).is_equal_approx(short_sealed.depth(), 0.5)
	assert_float(long_sealed.depth()).is_greater(250.0)

	assert_float(long_sealed.rescue_time()).is_greater(short_sealed.rescue_time())
	assert_float(short_sealed.rescue_time()).is_greater(0.0)


func test_rescue_time_counts_down_while_stranded() -> void:
	var sim := _stranded(MediumLayout.uniform(_hot_dense(300.0)), 60.0)
	var before := sim.rescue_time()

	DiveTestKit.run(sim, 10.0)

	assert_float(sim.rescue_time()).is_equal_approx(before - 10.0, 0.01)


func test_rescue_first_brings_the_crew_home_with_the_data_and_bills_the_rescue() -> void:
	var sim := _stranded(MediumLayout.uniform(_hot_dense(300.0)), 60.0)
	assert_float(sim.rescue_time()).is_less(sim.stranding_clock())
	var aboard := sim.unsold_value()
	var paid := sim.paid()
	assert_float(aboard).is_greater(0.0)
	var seen := []

	var rescued := DiveTestKit.run_until(sim, &"rescued", 100000.0, seen, 1.0)
	var paid_event: Array = seen.filter(func(e: Dictionary) -> bool: return e.type == &"paid")

	assert_dict(rescued).is_not_empty()
	assert_bool(sim.dead()).is_false()
	assert_bool(sim.stranded()).is_false()
	assert_bool(sim.surfaced()).is_true()
	assert_float(sim.depth()).is_less_equal(0.0)
	# The data aboard came home and was sold...
	assert_float(sim.unsold_value()).is_equal(0.0)
	assert_int(paid_event.size()).is_equal(1)
	assert_float(paid_event[0].carried_home).is_greater_equal(aboard)
	# ...less the rescue and the repairs, each a line in the breakdown, any of
	# the bill beyond what the dive earned covered.
	assert_float(paid_event[0].rescue).is_greater(0.0)
	assert_float(sim.paid()).is_equal_approx(paid + paid_event[0].carried_home
			- paid_event[0].rescue - paid_event[0].hull_repair - paid_event[0].head_repair
			+ paid_event[0].covered, 0.001)
	assert_float(paid_event[0].head_repair).is_greater(0.0)


func test_a_longer_rescue_costs_more() -> void:
	var quick := _stranded(MediumLayout.uniform(_hot_dense(300.0)), 60.0)
	var slow := _stranded(MediumLayout.uniform(_hot_dense(300.0)), 120.0)
	assert_float(slow.rescue_time()).is_greater(quick.rescue_time())
	var quick_seen := []
	var slow_seen := []

	var quick_rescue := DiveTestKit.run_until(quick, &"rescued", 100000.0, quick_seen, 1.0)
	var slow_rescue := DiveTestKit.run_until(slow, &"rescued", 100000.0, slow_seen, 1.0)

	assert_float(slow_rescue.rescue_time).is_greater(quick_rescue.rescue_time)
	assert_float(slow_seen.back().rescue).is_greater(quick_seen.back().rescue)


func test_a_rescue_billed_beyond_what_the_dive_earned_pays_nothing_and_covers_the_rest() -> void:
	# Deep down sealed rock, with every bit of heat sent into the Column so
	# little of the record survives: the long rescue costs more than it earned.
	var sim := _stranded(MediumLayout.uniform(_hot_dense(300.0)), 300.0)
	var paid := sim.paid()
	var seen := []

	DiveTestKit.run_until(sim, &"rescued", 100000.0, seen, 1.0)
	var bill: Dictionary = seen.back()

	assert_str(bill.type).is_equal(&"paid")
	var earned: float = bill.by_link + bill.carried_home
	var repairs: float = bill.rescue + bill.hull_repair + bill.head_repair
	assert_float(repairs).is_greater(earned)
	# The dive pays exactly nothing, never less: what was paid before is kept.
	assert_float(bill.amount).is_equal(0.0)
	assert_float(sim.paid()).is_equal_approx(paid, 0.001)
	# The breakdown still bills every line, and says what was covered.
	assert_float(bill.rescue).is_greater(0.0)
	assert_float(bill.covered).is_equal_approx(repairs - earned, 0.001)


func test_clock_first_is_death_losing_what_was_not_uploaded() -> void:
	var sim := _stranded(MediumLayout.uniform(_hot_dense()), 300.0)
	var clock := sim.stranding_clock()
	assert_float(clock).is_less(sim.rescue_time())
	var aboard := sim.unsold_value()
	var paid := sim.paid()
	assert_float(aboard).is_greater(0.0)
	var seen := []
	var waited := [0.0]

	var failed := DiveTestKit.run_until(sim, &"hull_failed", 100000.0, seen, 1.0,
			func() -> void: waited[0] += 1.0)

	assert_dict(failed).is_not_empty()
	assert_array(DiveTestKit.types(seen)).not_contains([&"rescued", &"paid"])
	assert_bool(sim.dead()).is_true()
	assert_bool(sim.stranded()).is_false()
	assert_float(failed.lost).is_equal(aboard)
	assert_float(sim.paid()).is_equal(paid)
	assert_float(failed.rebuy).is_greater(0.0)
	# The clock read at the stranding was true to the hull.
	assert_float(waited[0]).is_between(clock * 0.95, clock * 1.05 + 1.0)
	assert_float(sim.stranding_clock()).is_equal(0.0)


func test_the_hull_is_felt_taking_damage_while_heat_soaks_in_stranded() -> void:
	var sim := _stranded(MediumLayout.uniform(_hot_dense()), 300.0)
	assert_bool(sim.hull_taking_damage()).is_false()

	DiveTestKit.run(sim, 120.0)

	assert_bool(sim.stranded()).is_true()
	assert_bool(sim.hull_taking_damage()).is_true()
	assert_float(sim.hull_creep_rate()).is_greater(0.0)
