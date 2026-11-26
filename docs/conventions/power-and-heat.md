# Power and heat

**A new power-drawing system.**
Add its request in `_share_power()`, slotted into the shortfall order (Navigation, then Thermal, then the Drive: each gets all it asks while power lasts), and add its draw to `power_drawn()`.
Heat follows, since `Heat.step()` makes heat from `power_drawn()`.
Starvation is `<station>_supplied() < 1`; decide what a starved system does.
Its screen shows `habitat.gd::_power_line(request, draw)` (the Drive's flight display draws the same from `PowerLine.percent()` and `PowerLine.starved()`): `PowerLine` reads set point against actual as shares of `reactor_full_output()` (the Reactor screen uses the same scale), with "starved" only when the actual as shown is below the set point.

**Reactor output.**
`reactor_output()` scales with `Plasma.stability()`; anything that unsteadies the plasma lowers that (in `Plasma.tend()`), and it flows through the budget with no other change.

**Heat** (`sim/heat.gd`, `Heat`): heat made, the split into the Column and outward, hull temperature, hull wear (creep), the heat warning, how much of the Column's record survives the heat.
`Heat.step()` runs once a step from `_step()` after the power is shared, with the depth.
Creep is the one wear rule: none at or below the rated temperature (`hull_damage_temperature()`), above it the overheat times a stress that grows with depth; `hull_integrity()` is `1 - vessel_wear()`, `hull_creep_rate()` the wear per second, `hull_taking_damage()` whether it is wearing now (false once the dive has stopped:
dead or surfaced, since the last creep rate would otherwise freeze; true while stranded, when heat soaking in creeps it), and `hull_stress()` the depth stress (1 at the surface) that multiplies creep.
The hull settles toward the surrounding rock's temperature plus what it sheds, so hot rock heats it at any power.
`hull_warming_rate()` is which way the hull's temperature is going, in kelvin per second over the last step (0 once the dive has stopped); `DiveSimulation` works it out from `vessel_temperature()` either side of `Heat.step()` or `Heat.soak()`, so `Heat` has no query for it.
`Heat.failed()` (wear at 1) is read by `Stranding.check()`.
With the Head dark, `Heat.soak()` replaces `step()`: the hull settles toward `soak_temperature()` (the surroundings plus the heat of the melt round the vessel), less what the pumps carry into the Column at the cooling share, and creeps by the same rule.
`time_to_fail()` is the stranding clock worked out from that same model: the wear by any time is exact (`_soaked_wear()`: the hull's exponential settling with the creep rule summed over it, cooled while the store lasts, then not), and the time that wear reaches failure is found by bisection up to `_LONGEST_CLOCK_S` (a search limit, not tuned;
longer reads as INF), so the clock and the death it predicts agree; change the soak or creep rule and the clock follows.
New heat and hull behaviour goes here.
The Thermal Station's setting (`_heat_split`) and its autopilot's rule stay on `DiveSimulation`, which hands the split in; while stranded the split is how hard the pumps run on the store (set to 0 at the stranding, since the pumps stop with the Head; Thermal's autopilot does not raise it).
