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
## True if the Bore instruments were shuttered (Quiet Ship) for any of the
## stretch; its quality is lower for the part they missed.
var shuttered: bool


func _init(p_start: float, p_length: float, p_quality: float,
		p_composition: Dictionary, p_medium_name: StringName,
		p_shuttered := false) -> void:
	start = p_start
	length = p_length
	quality = p_quality
	composition = p_composition
	medium_name = p_medium_name
	shuttered = p_shuttered


## Distance along the path, in metres, at which the stretch ends.
func end() -> float:
	return start + length
