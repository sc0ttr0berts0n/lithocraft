# The Thermal Station's screen

- `head_wear()` (the Head, from its Residual outside the Band) and `vessel_wear()` (the hull, from heat) are different things.
  The Thermal screen's status lines show the hull as `hull_integrity()` and `hull_creep_rate()`, and once sealed in `stranding_clock()` beside `rescue_time()` ("if stranded" estimates under way, the race itself while stranded).
- Thermal's instrument (`ThermalGauge`, `view/thermal_gauge.gd`, a Control in the body) is a gauge of the hull against what it bears, over the heat split drawn as one divided bar.
  The gauge is a bar along a kelvin scale filled to `vessel_temperature()`; its amber range starts at `hull_warning_temperature()` and its red at `hull_damage_temperature()`, read from the simulation, never written in the view, and the bar and the number take the colour of the range the hull is in (`range_of()`).
  The trend mark is an airliner's speed trend arrow: from the hull's place to where it will be `TREND_AHEAD_S` on at `hull_warming_rate()`, in the colour of the range its tip reaches, with a triangle up or down and RISING or FALLING beside the number (a bar and STEADY under `STEADY_K_PER_S`).
  The split bar divides at the heat's own division (`heat_to_column()` over `heat_produced()`), out through the hull on the left; the crew's setting (`heat_split()`) is the cyan mark under it, so starved pumps show as the division standing short of the mark.
  It keeps no state and no clock: what it shows is in its queries (`needle()`, `trend()`, `trend_place()`, `column_share()`, `parts()`), tested in `thermal_gauge_test.gd`, so the hull's numbers are no longer repeated as status lines.
