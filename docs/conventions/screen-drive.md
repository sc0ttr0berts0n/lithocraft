# The Drive's screen

- The Drive's screen is a primary flight display (`FlightDisplay`, `view/flight_display.gd`), a picture drawn in its own `SubViewport`: attitude (pitch ladder), speed and depth tapes, heading tape, power, grip and steering, each read from the simulation's queries every frame;
  its status lines are the Course, written as Navigation's screen writes it (`habitat.gd::_course_line()`), then whether the Drive follows it or how far off it steers (or how the dive ended).
  A tape's scale is a `FlightTape`: the reading stays at its middle, a value's place is `place(value, reading)` (the short way round on the compass), and a bug off the tape is `pinned()` to its nearer end.
  On the attitude indicator a mark lies aside by `FlightTape.sideways()`, the true angle off the vessel's vertical plane, not the bare heading difference, which means nothing in a steep dive.
  The Course is always cyan (`StationTheme.SELECTED_COLOUR`), what the Drive steers for off it hollow in the same cyan (both are what the crew has selected), and where the Head points white.
- The deviation is stated in one set of words on every screen that states it (`CourseDeviation`, `view/course_deviation.gd`: "30 deg up, 15 deg right", from `deviation_pitch()` and `deviation_heading()`):
  at the foot of the Drive's attitude indicator beside the hollow mark ("OFF COURSE 30 deg up"), in the Drive's status line ("off Course: 30 deg up") and in Navigation's second status line ("Drive is off the Course by 30 deg up", else "Drive follows the Course" in green).
  `course_deviation_test.gd` stages a Habitat and fails if the two screens differ on the Course or the deviation; a new screen that shows either uses `_course_line()` and `CourseDeviation`.
  Pitch follows the simulation's sign (+ diving), so diving rungs lie below the horizon, as nose-down ones do on an airliner's.
