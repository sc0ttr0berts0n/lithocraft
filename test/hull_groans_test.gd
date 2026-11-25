# The hull's groans as it creeps: when they come, how loud, and where round
# the ring. View logic (HullGroans), tested directly as Arm is. Assert
# relationships, never tuned constants (ADR 0001).
extends GdUnitTestSuite

const MINUTES := 600.0
const STEP := 1.0 / 30.0


## Every groan heard over `seconds` of a hull creeping (or not) with this wear
## and stress.
func _listen(creeping: bool, wear: float, stress: float, seconds := MINUTES) -> Array:
	var groans := HullGroans.new(7)
	var heard := []
	var t := 0.0
	while t < seconds:
		heard.append_array(groans.step(STEP, creeping, wear, stress))
		t += STEP
	return heard


func _mean_loudness(heard: Array) -> float:
	var total := 0.0
	for groan in heard:
		total += groan.loudness
	return total / heard.size()


func test_a_hull_that_is_not_creeping_does_not_groan() -> void:
	assert_array(_listen(false, 0.6, 2.0)).is_empty()


func test_a_creeping_hull_groans() -> void:
	assert_array(_listen(true, 0.0, 1.0)).is_not_empty()


func test_a_more_worn_hull_groans_more_often_and_louder() -> void:
	var fresh := _listen(true, 0.1, 1.0)
	var worn := _listen(true, 0.8, 1.0)

	assert_int(worn.size()).is_greater(fresh.size())
	assert_float(_mean_loudness(worn)).is_greater(_mean_loudness(fresh))


func test_a_more_stressed_hull_groans_more_often_and_louder() -> void:
	var shallow := _listen(true, 0.3, 1.0)
	var deep := _listen(true, 0.3, 2.5)

	assert_int(deep.size()).is_greater(shallow.size())
	assert_float(_mean_loudness(deep)).is_greater(_mean_loudness(shallow))


func test_groans_are_never_silent_and_never_past_full() -> void:
	for groan in _listen(true, 1.0, 10.0) + _listen(true, 0.0, 1.0):
		assert_float(groan.loudness).is_greater(0.0)
		assert_float(groan.loudness).is_less_equal(1.0)


func test_groans_come_from_all_round_the_ring() -> void:
	var quarters := [0, 0, 0, 0]
	for groan in _listen(true, 0.5, 1.5):
		var quarter := int(fposmod(groan.angle, TAU) / (TAU / 4.0))
		quarters[mini(quarter, 3)] += 1

	for count in quarters:
		assert_int(count).is_greater(0)
