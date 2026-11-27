## The Bore's glass: a tube round the Column that shows at its edges and is
## clear over the Column, so a colour painted on the Column is the colour the
## crew see.
##
## A tube of glass is seen where the eye looks along its wall, at its edges;
## looked at square on it adds next to nothing. A flat see-through tint over
## the whole tube instead lays its own lit colour over all behind it, which
## shows on anything near-black as that colour (ticket #95: pores and mica read
## dark blue-green).
class_name BoreGlass
extends RefCounted

## The glass's own colour, and how much of it covers what is behind at the
## tube's very edge.
const TINT := Color(0.62, 0.85, 1.0)
const EDGE_COVER := 0.4

## How near the Bore's axis a line of sight passes, as a share of the glass's
## radius, is the sine of the angle between the glass's normal and the sight
## line as seen along the axis. Inside clear_within the sight line meets the
## Column, and the glass covers nothing; from there the cover grows to
## edge_cover at the tube's edge. The mesh is a cylinder standing on its own Y.
const SHADER := """
shader_type spatial;
render_mode blend_mix, cull_disabled;

uniform vec3 tint : source_color;
uniform float edge_cover;
uniform float clear_within;

varying vec3 axis;

void vertex() {
	axis = normalize((MODELVIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz);
}

void fragment() {
	vec3 along = normalize(axis);
	vec3 across = VIEW - along * dot(VIEW, along);
	float square_on = dot(normalize(NORMAL), across / max(length(across), 0.0001));
	float passes_at = sqrt(max(1.0 - square_on * square_on, 0.0));
	ALBEDO = tint;
	ROUGHNESS = 1.0;
	ALPHA = edge_cover * smoothstep(clear_within, 1.0, passes_at);
}
"""


## The material of a glass tube of bore_radius round a Column of
## column_radius on the same axis.
static func material(column_radius: float, bore_radius: float) -> ShaderMaterial:
	var shader := Shader.new()
	shader.code = SHADER
	var glass := ShaderMaterial.new()
	glass.shader = shader
	glass.set_shader_parameter(&"tint", TINT)
	glass.set_shader_parameter(&"edge_cover", EDGE_COVER)
	glass.set_shader_parameter(&"clear_within", clear_within(column_radius, bore_radius))
	return glass


## The share of the glass's radius inside which every sight line meets the
## Column: the glass is clear there.
static func clear_within(column_radius: float, bore_radius: float) -> float:
	return clampf(column_radius / bore_radius, 0.0, 1.0)
