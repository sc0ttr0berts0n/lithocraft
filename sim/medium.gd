## A Medium the Lithocraft can travel through, described by its seven properties.
## Plain data: a new Medium is a new set of values, not new code.
##
## Every Station reads these same properties (issue #1, Implementation Decisions):
## hardness sets cutting cost, strength sets available grip, porosity sets
## whether the tunnel stays open, temperature and pressure rise with depth,
## composition sets the Column's look and survey value, sound-carrying sets scan
## range and the slow link's rate. Values are relative and tuned for play
## (ADR 0001); only their ordering between Media needs to be physically true.
class_name Medium
extends RefCounted

## Human-readable name, e.g. &"sand". Used by views and logs, not by physics.
var name: StringName
## How hard the Medium is to cut. Higher is slower to advance through.
var hardness: float
## How well the tunnel wall holds against the grip waves. Higher allows more grip.
var strength: float
## Fraction of open space, 0 to 1. High porosity leaves the tunnel open.
var porosity: float
## Representative temperature of the Medium, in kelvin.
var temperature: float
## Representative pressure of the Medium, in megapascals.
var pressure: float
## Mineral name -> fraction of the Medium, fractions summing to about 1.
var composition: Dictionary
## How well the Medium carries sound, 0 to 1. Higher reaches further.
var sound_carrying: float


func _init(
		p_name: StringName,
		p_hardness: float,
		p_strength: float,
		p_porosity: float,
		p_temperature: float,
		p_pressure: float,
		p_composition: Dictionary,
		p_sound_carrying: float) -> void:
	name = p_name
	hardness = p_hardness
	strength = p_strength
	porosity = p_porosity
	temperature = p_temperature
	pressure = p_pressure
	composition = p_composition
	sound_carrying = p_sound_carrying


# --- The Media of the first dive -------------------------------------------
# Sand is easy to cut but hard to push against; granite is the reverse.

static func sand() -> Medium:
	return Medium.new(&"sand", 1.0, 0.25, 0.4, 300.0, 0.5,
			{&"quartz": 0.9, &"feldspar": 0.1}, 0.2)


static func sandstone() -> Medium:
	return Medium.new(&"sandstone", 2.5, 0.6, 0.2, 310.0, 5.0,
			{&"quartz": 0.8, &"feldspar": 0.1, &"calcite": 0.1}, 0.6)


static func granite() -> Medium:
	return Medium.new(&"granite", 5.0, 1.0, 0.01, 340.0, 40.0,
			{&"feldspar": 0.6, &"quartz": 0.3, &"mica": 0.1}, 0.9)
