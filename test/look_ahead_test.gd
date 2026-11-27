# The look-ahead, tested on patches alone, as the fit is tested on points
# alone: BoundaryPatches, where the Head is and how fast it goes in, the
# countdown and the guess's confidence out. No simulation and no layout: a
# patch here is wherever the test puts it, so the scan can be made to show a
# Boundary where none is. Assert relationships, never tuned constants (ADR
# 0001).
extends GdUnitTestSuite

## Test values only: a Wobble beyond, and a speed straight down.
const BEYOND := Vector2(1.5, 0.7)
const SPEED := 0.5


## A level patch of ground `depth` metres down, centred under the origin.
func _level_patch(depth: float, confidence: float) -> BoundaryPatch:
	return BoundaryPatch.new(Vector3(0.0, -depth, 0.0), Vector3.UP, Vector2(12.0, 12.0), 10,
			confidence, 0.0)


## Looks straight down from `depth` metres down, having come straight down.
func _look_from(look: LookAhead, patches: Array[BoundaryPatch], depth: float) -> void:
	look.look(patches, Vector3(0.0, -depth, 0.0), Vector3.DOWN, depth, BEYOND, 1)


## Runs straight down from one depth to another in half-metre steps, looking
## after each. Returns the countdown's doubt at each look that had a countdown.
func _run(look: LookAhead, patches: Array[BoundaryPatch], from: float, to: float) -> Array[float]:
	var doubts: Array[float] = []
	var depth := from
	while depth <= to:
		_look_from(look, patches, depth)
		if not is_inf(look.countdown(SPEED)):
			doubts.append(look.countdown_doubt(SPEED))
		depth += 0.5
	return doubts


func test_a_patch_where_the_scan_put_it_is_counted_down_to_and_guessed_as_surely_as_it_is_resolved() -> void:
	# Nothing here says whether a Boundary really lies there: the scan can mislead.
	var poor := LookAhead.new()
	var well := LookAhead.new()

	_look_from(poor, [_level_patch(60.0, 0.2)], 10.0)
	_look_from(well, [_level_patch(60.0, 0.9)], 10.0)

	assert_float(poor.countdown(SPEED)).is_equal_approx(50.0 / SPEED, 1e-3)
	assert_float(well.countdown(SPEED)).is_equal(poor.countdown(SPEED))
	assert_float(well.countdown_doubt(SPEED)).is_less(poor.countdown_doubt(SPEED))
	assert_float(poor.guess().confidence).is_equal_approx(0.2, 1e-6)
	assert_float(well.guess().confidence).is_equal_approx(0.9, 1e-6)
	assert_bool(poor.guess().has_wobble()).is_true()


func test_with_no_patch_ahead_there_is_no_countdown_and_no_true_component() -> void:
	var look := LookAhead.new()

	_look_from(look, [] as Array[BoundaryPatch], 10.0)

	assert_bool(is_inf(look.countdown(SPEED))).is_true()
	assert_bool(is_inf(look.countdown_doubt(SPEED))).is_true()
	assert_float(look.guess().confidence).is_equal(0.0)
	assert_bool(look.guess().has_wobble()).is_false()


func test_stopped_or_too_far_off_the_countdown_says_no_more_than_beyond_its_cap() -> void:
	var look := LookAhead.new()
	_look_from(look, [_level_patch(60.0, 0.8)], 10.0)

	assert_bool(is_inf(look.countdown(0.0))).is_true()
	assert_bool(is_inf(look.countdown(50.0 / (look.countdown_cap() * 2.0)))).is_true()
	# The guess does not wait on the speed.
	assert_bool(look.guess().has_wobble()).is_true()


func test_run_past_where_the_scan_put_a_boundary_it_is_due_with_a_growing_doubt_and_then_given_up() -> void:
	var look := LookAhead.new()
	var patches: Array[BoundaryPatch] = [_level_patch(60.0, 0.6)]
	_run(look, patches, 10.0, 59.5)
	var sure := look.guess().confidence
	var doubt_before := look.countdown_doubt(SPEED)

	# No crossing is felt: the Head runs on past it.
	_look_from(look, patches, 61.0)
	var due := look.countdown(SPEED)
	var doubt_just_past := look.countdown_doubt(SPEED)
	_look_from(look, patches, 64.0)
	var doubt_further := look.countdown_doubt(SPEED)

	assert_float(due).is_equal(0.0)
	assert_float(look.countdown(SPEED)).is_equal(0.0)
	assert_float(doubt_just_past).is_greater(doubt_before)
	assert_float(doubt_further).is_greater(doubt_just_past)
	# The guess of what lies beyond is as sure as it was while it is due.
	assert_float(look.guess().confidence).is_equal(sure)
	# Far enough past with nothing felt, the scan was wrong: it shows nothing.
	_run(look, patches, 64.0, 400.0)
	assert_bool(is_inf(look.countdown(SPEED))).is_true()
	assert_float(look.guess().confidence).is_equal(0.0)


func test_past_one_patch_it_falls_back_to_what_the_patches_beyond_say() -> void:
	var look := LookAhead.new()
	var patches: Array[BoundaryPatch] = [_level_patch(60.0, 0.6), _level_patch(150.0, 0.3)]
	_run(look, patches, 10.0, 59.5)

	_look_from(look, patches, 61.0)

	assert_float(look.countdown(SPEED)).is_equal_approx(89.0 / SPEED, 1e-3)
	assert_float(look.guess().confidence).is_equal_approx(0.3, 1e-6)


func test_a_patch_the_line_no_longer_meets_is_not_due() -> void:
	var look := LookAhead.new()
	var patches: Array[BoundaryPatch] = [_level_patch(60.0, 0.6)]
	_look_from(look, patches, 10.0)

	# The Head turns to climb: the patch is behind it now, never reached.
	look.look(patches, Vector3(0.0, -10.5, 0.0), Vector3.UP, 10.5, BEYOND, 1)

	assert_bool(is_inf(look.countdown(SPEED))).is_true()
	assert_float(look.guess().confidence).is_equal(0.0)


func test_a_crossing_felt_holds_the_guess_until_settled_and_spends_the_patch_just_beyond_it() -> void:
	var look := LookAhead.new()
	# The scan put the Boundary a little deeper than the crossing is felt.
	var patches: Array[BoundaryPatch] = [_level_patch(60.0, 0.6), _level_patch(200.0, 0.4)]
	_run(look, patches, 10.0, 57.0)
	var wobble := look.guess().wobble

	look.felt_crossing(57.0)
	look.look(patches, Vector3(0.0, -57.5, 0.0), Vector3.DOWN, 57.5, Vector2(3.0, 0.2), 2)

	assert_bool(look.holding()).is_true()
	assert_vector(look.guess().wobble).is_equal(wobble)
	# Settled: the patch just ahead was that Boundary; the next is the one beyond.
	look.settle()
	_look_from(look, patches, 58.0)
	assert_bool(look.holding()).is_false()
	assert_float(look.countdown(SPEED)).is_equal_approx(142.0 / SPEED, 1e-3)
	assert_float(look.guess().confidence).is_equal_approx(0.4, 1e-6)


func test_the_guess_is_of_the_wobble_handed_in_and_never_of_nothing() -> void:
	var look := LookAhead.new()

	_look_from(look, [_level_patch(60.0, 0.9)], 10.0)

	var guess := look.guess()
	assert_float(guess.wobble.x).is_greater(0.0)
	assert_float(absf(guess.wobble.x - BEYOND.x)).is_less(absf(BEYOND.x) * 0.5)


func test_the_look_ahead_never_reads_the_layout() -> void:
	# The countdown and the guess's confidence come from the patches and the
	# Head's own movement: no Medium, no layout and no simulation is named
	# anywhere in the look-ahead, the fit it reads or the guess it makes.
	for path in ["res://sim/look_ahead.gd", "res://sim/wobble_guess.gd"]:
		var source: String = (load(path) as GDScript).source_code
		for word in ["MediumLayout", "Medium", "DiveSimulation", "_layout", "medium_at", "boundary_depths"]:
			assert_bool(source.contains(word)) \
					.override_failure_message("%s names %s" % [path, word]) \
					.is_false()
