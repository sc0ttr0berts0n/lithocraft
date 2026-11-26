# The survey and payment

**Survey quality.**
`_recording_quality()` is the one hook: today the shutter term (Quiet Ship) times `Heat.unheated_share()` (heat into the Column).
A new effect multiplies in another term there.
Survey stretches and feature recording both read it, so nothing else changes.

**Payment.**
A stretch pays `SurveyStretch.value()` once all of it is up the link.
Death's breakdown is the `&"hull_failed"` event: `rebuy` is the cost, `rebuy_charged` what was taken (0 until a balance exists; charging it is a later ticket).
Surfacing, being brought home through the open tunnel and a rescue all end in `_come_home(arrival, rescue_seconds)`: it raises the arrival event (`&"surfaced"`, `&"brought_home"` or `&"rescued"`), sells what is aboard through `_sell_aboard()`, bills the dive's wear through `_pay_for_repairs(rescue_seconds)` (a `Repairs`, whose `total()` is the one sum of the bill),
then raises `&"paid"`, which carries the arrival event as `arrival` so the view heads the breakdown from it alone.
The bill is the hull's (`Stranding.hull_repair(vessel_wear())`) and the Head's (`Stranding.head_repair(head_wear())`), each in proportion to wear, never running hours, and a rescue's in proportion to how long it took (`Stranding.rescue_cost()`).
`&"paid"` carries `hull_repair`, `head_repair` and `rescue`, and `amount` is net of them, but never below 0: `_pay_for_repairs()` charges no more than the dive earned (`_paid - _paid_before_dive`), and the rest of the bill is `Repairs.covered`, carried as `covered` and shown as its own breakdown line ("on us"), so `amount = by_link + carried_home - repairs + covered`;
`by_link` (counted as the link pays, `_paid_by_link`, never a difference) `+ carried_home` (and the `by_medium` total) is the pay before repairs.
A new cost of a dive that reaches the surface goes in `Repairs` and `_pay_for_repairs()` and becomes another field and breakdown line.
A fully recorded feature becomes a `SurveyStretch.feature_record()` on the link queue, not an entry in `survey()`.
For "aboard" counts use `unsold_survey()` / `unsold_value()`, not `survey().size()` minus uploads: `uploaded_survey()` spans every dive.
Heat and shuttering's cost is `pristine_value() - value()`.

**New minerals.**
Add the mineral to `ColumnLook.MINERAL_COLOURS` (its look in the Bore) and to `SurveyStretch._MINERAL_WORTH` (its worth; defaults to 1).

**New features of interest.**
Add the kind's maker to `ColumnFeature` (kind, size, worth), place it in a layout with `with_features()`, and give it a look in `FeatureLook.LOOKS` (see `view.md`).
