## How the Column looks, worked out from the Medium's own properties so a new
## Medium needs no new art: composition gives the grain colours, porosity the
## dark pores between them. View-side only; the simulation never calls this.
## Shared by the dive view's Column strip and, later, the Habitat's Bore.
class_name ColumnLook
extends RefCounted

## Colour of each mineral's grains. Placeholder palette, not final art.
const MINERAL_COLOURS := {
	&"quartz": Color(0.88, 0.84, 0.72),
	&"feldspar": Color(0.86, 0.55, 0.48),
	&"calcite": Color(0.96, 0.95, 0.9),
	&"mica": Color(0.12, 0.1, 0.1),
	&"hematite": Color(0.55, 0.12, 0.06),
}
## Minerals that stain far beyond their share, as iron oxide reddens a
## sandstone at a few percent. Weight on the blended background colour.
const PIGMENT_STRENGTH := {
	&"hematite": 15.0,
}
const UNKNOWN_MINERAL_COLOUR := Color(0.5, 0.5, 0.5)
const PORE_COLOUR := Color(0.05, 0.04, 0.03)


## The colour of one mineral's grains.
static func mineral_colour(mineral: StringName) -> Color:
	return MINERAL_COLOURS.get(mineral, UNKNOWN_MINERAL_COLOUR)


## The overall colour of a composition (mineral -> fraction): its minerals
## blended by share, strong pigments counting extra.
static func blended_colour(composition: Dictionary) -> Color:
	var total := 0.0
	var colour := Color(0, 0, 0)
	for mineral in composition:
		var weight: float = composition[mineral] * PIGMENT_STRENGTH.get(mineral, 1.0)
		colour += mineral_colour(mineral) * weight
		total += weight
	if total <= 0.0:
		return UNKNOWN_MINERAL_COLOUR
	colour /= total
	colour.a = 1.0
	return colour


## The colour of the cement or matrix between grains: the blend, darkened by
## porosity because open pores read as shadow.
static func matrix_colour(medium: Medium) -> Color:
	return blended_colour(medium.composition).darkened(medium.porosity)


## Picks a grain's mineral by share of the composition, given a roll in 0..1.
static func grain_mineral(composition: Dictionary, roll: float) -> StringName:
	var total := 0.0
	for mineral in composition:
		total += composition[mineral]
	var running := 0.0
	for mineral in composition:
		running += composition[mineral] / total
		if roll <= running:
			return mineral
	return composition.keys().back()
