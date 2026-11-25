## A feature of interest in the Column: something worth a close look as it
## passes through the Bore, such as a fossil or a mineral vein. Plain data.
##
## Placed in a MediumLayout as a template (kind, size, worth). When the Head
## cuts past it the simulation hands out copies that also say where it lies
## along the path and how much of it the Bore Station has recorded. Features
## are observed and recorded, never cut out: the Column keeps them and they
## leave through the Tail.
class_name ColumnFeature
extends RefCounted

## What it is, e.g. &"petrified_wood". Views pick its look from this.
var kind: StringName
## Its length along the path, in metres.
var size_m: float
## What a full record of it adds to the survey's value. Tuned for play
## (ADR 0001); only its ordering between kinds needs to mean anything.
var worth: float

## Set by the simulation once the Head has found it; -1 in a template.
var id := -1
## Distance along the path, in metres from the start of the dive, where it lies.
var at := 0.0
## How much of it the Bore Station has recorded, 0 (none) to 1 (all of it).
var recorded := 0.0


func _init(p_kind: StringName, p_size_m: float, p_worth: float) -> void:
	kind = p_kind
	size_m = p_size_m
	worth = p_worth


## True once the Bore Station has recorded all of it.
func is_recorded() -> bool:
	return recorded >= 1.0


## A copy, so what the simulation hands out can't change its record.
func copy() -> ColumnFeature:
	var c := ColumnFeature.new(kind, size_m, worth)
	c.id = id
	c.at = at
	c.recorded = recorded
	return c


# --- Features of the first dive -------------------------------------------

## Glass tube fused in sand by a lightning strike.
static func fulgurite() -> ColumnFeature:
	return ColumnFeature.new(&"fulgurite", 0.6, 40.0)


## A fossil tree trunk turned to quartz in the dune sandstone.
static func petrified_wood() -> ColumnFeature:
	return ColumnFeature.new(&"petrified_wood", 0.8, 80.0)


## A cluster of iron oxide marbles grown in the sandstone's pores.
static func iron_concretions() -> ColumnFeature:
	return ColumnFeature.new(&"iron_concretions", 0.4, 50.0)


## A sheet of white quartz cutting across the granite.
static func quartz_vein() -> ColumnFeature:
	return ColumnFeature.new(&"quartz_vein", 0.15, 60.0)


## A pocket of giant crystals in the granite, with garnet.
static func pegmatite() -> ColumnFeature:
	return ColumnFeature.new(&"pegmatite", 0.5, 120.0)
