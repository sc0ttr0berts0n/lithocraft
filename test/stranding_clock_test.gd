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
		sim.set_attended(DiveSimulation.STATION_THERMAL, true)
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
