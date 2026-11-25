## One entry in the Bore Station's survey: what the Column held over one
## stretch of the path. Plain data; the simulation makes these, views read them.
class_name SurveyStretch
extends RefCounted

## Distance along the path, in metres from the start of the dive, at which the
## stretch begins.
var start: float
## Length of the stretch along the path, in metres.
var length: float
## How good the record is, 0 (worthless) to 1 (pristine).
var quality: float
## Mineral name -> fraction of the Column over this stretch, as recorded.
var composition: Dictionary
## Name of the Medium that made up most of the stretch.
var medium_name: StringName


func _init(p_start: float, p_length: float, p_quality: float,
		p_composition: Dictionary, p_medium_name: StringName) -> void:
	start = p_start
	length = p_length
	quality = p_quality
	composition = p_composition
	medium_name = p_medium_name


## Distance along the path, in metres, at which the stretch ends.
func end() -> float:
	return start + length


## What this stretch sells for once its data reaches the surface: more for a
## longer and better record. In arbitrary units.
func value() -> float:
	return length * quality
