## The checklist panel (Tab): the Orders' goals, achieved or not yet; the
## phase now running with its steps, the next one highlighted with its
## Station named and the key that does it; surface control's
## messages at its foot. The only overlay the crew uses in play. It reads the
## simulation and sends nothing; the Habitat sends read_orders() as it opens.
class_name ChecklistPanel
extends PanelContainer

const FONT_SIZE := 15
const WIDTH := 460.0
## How many of surface control's latest messages are shown.
const MESSAGES_SHOWN := 3

## Every colour is the Station colour language's (StationTheme): a reading, so
## no Station's tint. Done is engaged green; the next step's Station is where
## the crew aims, so cyan; the rest is white or legend grey.
const _DONE_COLOUR := StationTheme.ENGAGED_COLOUR
const _MISSED_COLOUR := StationTheme.LEGEND_COLOUR
const _PENDING_COLOUR := StationTheme.NOW_COLOUR
const _NEXT_COLOUR := StationTheme.NOW_COLOUR
const _HEADING_COLOUR := StationTheme.NOW_COLOUR
const _STATION_COLOUR := StationTheme.LEGEND_COLOUR
const _NEXT_STATION_COLOUR := StationTheme.SELECTED_COLOUR

## The simulation read. Set before _ready.
var sim: DiveSimulation
## Each Station's name, by the simulation's name.
var stations := {}

var _text := RichTextLabel.new()


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	var backing := StyleBoxFlat.new()
	backing.bg_color = StationTheme.faded(StationTheme.SCREEN_COLOUR, 0.88)
	backing.set_content_margin_all(14)
	add_theme_stylebox_override(&"panel", backing)
	_text.bbcode_enabled = true
	_text.fit_content = true
	_text.scroll_active = false
	_text.custom_minimum_size.x = WIDTH
	_text.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_text.add_theme_font_size_override(&"normal_font_size", FONT_SIZE)
	_text.add_theme_font_size_override(&"bold_font_size", FONT_SIZE)
	add_child(_text)


func _process(_delta: float) -> void:
	if visible and sim != null:
		_text.text = text_of(sim, stations)


## The panel's text, in BBCode, for this simulation.
static func text_of(dive: DiveSimulation, station_names: Dictionary) -> String:
	var lines := PackedStringArray()
	lines.append(_heading("%s: orders from surface control" % dive.scenario_title()))
	for goal in dive.orders():
		var mark := "[x]" if goal.achieved else "[ ]"
		var colour := _DONE_COLOUR if goal.achieved else _PENDING_COLOUR
		lines.append(_coloured("%s %s" % [mark, goal.text], colour))
	var phases := dive.checklist()
	if not phases.is_empty():
		var at := dive.checklist_phase()
		var next := dive.next_step()
		lines.append("")
		lines.append(_heading("Checklist: %s (%d of %d)" % [phases[at].title, at + 1, phases.size()]))
		for s in phases[at].steps.size():
			lines.append(_step_line(phases[at].steps[s], next.get("step", -1) == s, station_names))
	lines.append("")
	lines.append(_heading("Surface control"))
	var messages := dive.surface_messages()
	for text in messages.slice(maxi(0, messages.size() - MESSAGES_SHOWN)):
		lines.append(_coloured(text, _PENDING_COLOUR))
	if dive.messages_on_the_way() > 0:
		lines.append(_coloured("... coming down the link", _MISSED_COLOUR))
	elif messages.is_empty():
		lines.append(_coloured("Nothing yet", _MISSED_COLOUR))
	return "\n".join(lines)


static func _step_line(step: Dictionary, is_next: bool, station_names: Dictionary) -> String:
	var where := ""
	if station_names.has(step.station):
		where = "  " + _coloured(station_names[step.station], _NEXT_STATION_COLOUR if is_next else _STATION_COLOUR)
	var key := ""
	for action: StringName in [step.action, step.also]:
		if action != &"":
			key += "  %s" % _escaped(KeyMap.label(action))
	match step.state:
		DiveSimulation.STEP_DONE:
			return _coloured("[x] %s" % step.text, _DONE_COLOUR)
		DiveSimulation.STEP_MISSED:
			return _coloured("[-] %s (missed)" % step.text, _MISSED_COLOUR)
	if is_next:
		return "[b]%s[/b]%s%s" % [_coloured("> %s" % step.text, _NEXT_COLOUR), where, key]
	return _coloured("[ ] %s" % step.text, _PENDING_COLOUR) + where


static func _heading(text: String) -> String:
	return "[b]%s[/b]" % _coloured(text, _HEADING_COLOUR)


static func _coloured(text: String, colour: Color) -> String:
	return "[color=#%s]%s[/color]" % [colour.to_html(false), _escaped(text)]


## Text with its brackets shown, not read as BBCode.
static func _escaped(text: String) -> String:
	return text.replace("[", "[lb]")
