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


## What a record of each mineral is worth per metre of Column, relative to
## plain quartz. Minerals not listed are worth the same as quartz. Tuned for
## play (ADR 0001); tests compare values, never read these.
const _MINERAL_WORTH := {
	&"quartz": 1.0,
	&"feldspar": 1.2,
	&"calcite": 1.2,
	&"mica": 1.5,
	&"hematite": 4.0,
}


## What this stretch sells for once its data reaches the surface: more for a
## longer record, a better one, and one of more valuable minerals. In
## arbitrary units.
func value() -> float:
	var worth := 0.0
	for mineral in composition:
		worth += composition[mineral] * _MINERAL_WORTH.get(mineral, 1.0)
	return length * quality * worth
