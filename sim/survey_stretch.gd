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
## Set on a record of a feature of interest instead of a stretch of Column:
## the feature's kind and what its record is worth. &"" and 0 on a stretch.
var feature_kind: StringName = &""
var feature_worth := 0.0
## Set on the record of a target's feature (ColumnFeature.target): the
## target's label, so it is paid as its own line. &"" otherwise.
var target: StringName = &""


func _init(p_start: float, p_length: float, p_quality: float,
		p_composition: Dictionary, p_medium_name: StringName,
		p_shuttered := false) -> void:
	start = p_start
	length = p_length
	quality = p_quality
	composition = p_composition
	medium_name = p_medium_name
	shuttered = p_shuttered


## The Bore Station's record of a feature of interest recorded in full: survey
## data in its own right, sent up the link like a stretch and paid for once it
## reaches the surface. It covers the feature's own length along the path, at
## the quality it was recorded (all of it), and is worth what the feature is.
static func feature_record(feature: ColumnFeature, p_medium_name: StringName) -> SurveyStretch:
	var record := SurveyStretch.new(feature.at - feature.size_m / 2.0, feature.size_m,
			1.0, {}, p_medium_name)
	record.feature_kind = feature.kind
	record.feature_worth = feature.worth
	record.target = feature.target
	return record


## True for a record of a feature of interest rather than a stretch of Column.
func is_feature_record() -> bool:
	return feature_kind != &""


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
## longer record, a better one, and one of more valuable minerals; a feature
## record is worth what its feature is. In arbitrary units.
func value() -> float:
	return length * quality * _mineral_worth() + feature_worth


## What this stretch would sell for had its record been pristine (quality 1):
## the difference from value() is what heat and shuttering cost it.
func pristine_value() -> float:
	return length * _mineral_worth() + feature_worth


func _mineral_worth() -> float:
	var worth := 0.0
	for mineral in composition:
		worth += composition[mineral] * _MINERAL_WORTH.get(mineral, 1.0)
	return worth
