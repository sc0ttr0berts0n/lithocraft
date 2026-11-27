# The Reactor's screen

- The Reactor's screen (`PlasmaDisplay`, `view/plasma_display.gd`, a Control in the body) is the Shift dial as two lanes, ACTIVE over STANDBY, each read left to right as a sum: its names, its Wobble and Counter-wave drawn together, then its Residual alone against the Band.
  Every line carries its name in its colour: WOBBLE white (STANDBY's is WOBBLE GUESS), COUNTER-WAVE cyan, RESIDUAL bold (white inside the Band, amber outside), BAND a green strip; the lane the controls tune is cyan and marked TUNING.
  The Band drawn is the Band that wears the Head: `band_edges()` is `band()` at the Residual's own scale (`value_y()`), and the waves are the simulation's, so the line leaves the drawn Band exactly when `out_of_band()` (`plasma_display_test.gd`); the dashed lines are `band_widest()`.
  Each lane's verdict is in words (`verdict()`).
  STANDBY's is a prediction: its number is beside a plus-or-minus, `wobble_ahead_spurious()`, the ripple the drawn line keeps, and while that could reach outside the Band the verdict is "IN BAND IF THE SCAN IS RIGHT".
  Under the lanes: the Boundary countdown on a track toward NOW, giving way to "BOUNDARY CROSSED" and the swap's key while `settling_in()`; the Band beside its widest; the Head's wear.
  It keeps no state but its pace (`ScreenPace`); its writing is `Label`s, never drawn strings, tested not to overlap, and its waves run on the dive's clock.
  Its six waves come from one `waves(channel, span, steps)` call a lane, which looks the Wobble and the guess up once; never draw them from `wobble_wave()` point by point, which cost the quiet frame half its time (#96).
