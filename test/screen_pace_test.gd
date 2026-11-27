# How often a Station screen's instrument brings itself up to the simulation
# (ScreenPace): every frame while the crew is at its Station, a few times a
# second while they are not, and never later than UNWATCHED_S and a frame.
extends GdUnitTestSuite

const FRAME := 1.0 / 60.0


## The frames, of `count` played `delta` apart, that were due.
func _due_frames(pace: ScreenPace, count: int, delta: float, watched: bool) -> Array[int]:
	var due: Array[int] = []
	for frame in count:
		if pace.due(delta, watched):
			due.append(frame)
	return due


func test_a_watched_screen_is_brought_up_every_frame() -> void:
	assert_int(_due_frames(ScreenPace.new(), 120, FRAME, true).size()).is_equal(120)


func test_an_unwatched_screen_is_brought_up_first_then_less_often_but_never_later_than_its_lag() -> void:
	for delta: float in [FRAME, 1.0 / 144.0, 1.0 / 30.0, 0.07]:
		var due := _due_frames(ScreenPace.new(), 240, delta, false)
		assert_int(due[0]).is_equal(0)
		assert_int(due.size()).is_less(240 if delta < ScreenPace.UNWATCHED_S else 241)
		for i in range(1, due.size()):
			assert_float((due[i] - due[i - 1]) * delta).is_less_equal(ScreenPace.UNWATCHED_S + delta)
		assert_float((239 - due[-1]) * delta).is_less_equal(ScreenPace.UNWATCHED_S + delta)
	# At the game's own frame it does a fraction of the work.
	assert_int(_due_frames(ScreenPace.new(), 240, FRAME, false).size()).is_less(240 / 4)


func test_being_watched_brings_it_up_at_once() -> void:
	var pace := ScreenPace.new()
	pace.due(FRAME, false)
	assert_bool(pace.due(FRAME, false)).is_false()
	assert_bool(pace.due(FRAME, true)).is_true()


func test_a_hurry_makes_the_next_frame_due_unwatched() -> void:
	var pace := ScreenPace.new()
	pace.due(FRAME, false)
	pace.hurry()
	assert_bool(pace.due(FRAME, false)).is_true()
	assert_bool(pace.due(FRAME, false)).is_false()
