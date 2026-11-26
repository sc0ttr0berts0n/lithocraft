# The still outcome screen: the end-of-dive lurch that settles to still, and
# the sentence that names how the dive ended. View logic (OutcomeScreen),
# tested directly as HullGroans is. Assert relationships, never tuned
# constants (ADR 0001).
extends GdUnitTestSuite

const STEP := 1.0 / 60.0
const LONG_S := 30.0


## The shake, frame by frame, for `seconds` after the dive ends with the view
## shaking `shaking_m`.
func _lurch(shaking_m: float, seconds := LONG_S) -> Array:
	var screen := OutcomeScreen.new()
	screen.start(shaking_m)
	var shakes := []
	var t := 0.0
	while t < seconds:
		shakes.append(screen.step(STEP))
		t += STEP
	return shakes


func _outcome(ending: StringName, cause := &"", stranded_for := 0.0,
		plasma_lost_by := &"") -> Dictionary:
	return {ending = ending, cause = cause, plasma_lost_by = plasma_lost_by,
			stranded_for = stranded_for, depth = 120.0}


func test_the_end_of_a_dive_lurches_even_from_still() -> void:
	assert_float(_lurch(0.0)[0]).is_greater(0.0)


func test_the_lurch_never_grows_and_comes_to_rest_exactly_still() -> void:
	var shakes := _lurch(0.05)

	for i in range(1, shakes.size()):
		assert_float(shakes[i]).is_less_equal(shakes[i - 1])
	assert_float(shakes.back()).is_equal(0.0)


func test_a_harder_shake_at_the_end_lurches_harder_but_still_settles() -> void:
	var gentle := _lurch(0.0)
	var hard := _lurch(0.2)

	assert_float(hard[0]).is_greater(gentle[0])
	assert_float(hard.back()).is_equal(0.0)


func test_the_screen_is_still_only_once_the_lurch_has_settled() -> void:
	var screen := OutcomeScreen.new()
	screen.start(0.05)
	assert_bool(screen.still()).is_false()

	var t := 0.0
	var shake := 1.0
	while not screen.still() and t < LONG_S:
		shake = screen.step(STEP)
		t += STEP

	assert_bool(screen.still()).is_true()
	assert_float(shake).is_equal(0.0)
	assert_float(screen.step(STEP)).is_equal(0.0)


func test_before_a_dive_ends_and_after_a_reset_nothing_shakes() -> void:
	var screen := OutcomeScreen.new()
	assert_float(screen.step(STEP)).is_equal(0.0)
	assert_bool(screen.still()).is_false()

	screen.start(0.05)
	screen.reset()

	assert_float(screen.step(STEP)).is_equal(0.0)
	assert_bool(screen.still()).is_false()


func test_a_dive_under_way_has_no_sentence() -> void:
	assert_str(OutcomeScreen.sentence(_outcome(&"under_way"))).is_empty()


func test_every_ending_has_its_own_sentence() -> void:
	var sentences := [
		OutcomeScreen.sentence(_outcome(&"surfaced")),
		OutcomeScreen.sentence(_outcome(&"brought_home", &"disrupted", 0.0, &"disrupted")),
		OutcomeScreen.sentence(_outcome(&"rescued", &"disrupted", 600.0, &"disrupted")),
		OutcomeScreen.sentence(_outcome(&"dead", &"heat")),
		OutcomeScreen.sentence(_outcome(&"dead", &"self_destruct")),
	]

	for i in sentences.size():
		assert_str(sentences[i]).is_not_empty()
		for j in range(i + 1, sentences.size()):
			assert_str(sentences[i]).is_not_equal(sentences[j])
	assert_str(sentences[0].to_lower()).contains("surfaced")
	assert_str(sentences[2].to_lower()).contains("rescued")
	assert_str(sentences[3].to_lower()).contains("dead")
	assert_str(sentences[4].to_lower()).contains("self-destruct")


func test_a_rescue_says_why_the_plasma_was_lost_and_how_long_the_crew_was_stranded() -> void:
	var disrupted := OutcomeScreen.sentence(_outcome(&"rescued", &"disrupted", 600.0, &"disrupted"))
	var worn := OutcomeScreen.sentence(_outcome(&"rescued", &"worn_through", 600.0, &"worn_through"))
	var longer := OutcomeScreen.sentence(_outcome(&"rescued", &"disrupted", 5400.0, &"disrupted"))

	assert_str(disrupted).is_not_equal(worn)
	assert_str(disrupted.to_lower()).contains("residual")
	assert_str(disrupted).contains("10 min")
	assert_str(longer).contains("1 h 30 min")


func test_a_death_while_stranded_says_how_long_the_crew_waited() -> void:
	var under_way := OutcomeScreen.sentence(_outcome(&"dead", &"heat"))
	var stranded := OutcomeScreen.sentence(_outcome(&"dead", &"heat", 600.0, &"disrupted"))

	assert_str(stranded).is_not_equal(under_way)
	assert_str(stranded).contains("10 min")
	assert_str(stranded.to_lower()).contains("stranded")


func test_a_new_dive_waits_while_the_lurch_settles_but_not_before_or_after() -> void:
	var screen := OutcomeScreen.new()
	assert_bool(screen.settling()).is_false()

	screen.start(0.05)
	assert_bool(screen.settling()).is_true()

	var t := 0.0
	while not screen.still() and t < LONG_S:
		screen.step(STEP)
		t += STEP
	assert_bool(screen.settling()).is_false()
