# Station screen text is shrunk to fit the screen, never cut off by it.
extends GdUnitTestSuite

const BOX := Vector2(500.0, 250.0)


func _font() -> Font:
	return ThemeDB.fallback_font


func _size(text: String, font_size: int) -> Vector2:
	return _font().get_multiline_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)


func test_short_text_keeps_the_largest_size() -> void:
	assert_int(GimballedStation.fitting_font_size("Thermal\nshort", _font(), 28, BOX)).is_equal(28)


func test_long_text_shrinks_until_it_fits() -> void:
	var lines := PackedStringArray()
	for i in 14:
		lines.append("A line of a Station's reading, long enough to run wide %d" % i)
	var text := "\n".join(lines)
	assert_bool(_size(text, 28).x > BOX.x or _size(text, 28).y > BOX.y).is_true()

	var fitted := GimballedStation.fitting_font_size(text, _font(), 28, BOX)

	assert_int(fitted).is_less(28)
	assert_float(_size(text, fitted).x).is_less_equal(BOX.x)
	assert_float(_size(text, fitted).y).is_less_equal(BOX.y)


func test_more_lines_never_get_larger_text() -> void:
	var few := GimballedStation.fitting_font_size("a\nb\nc", _font(), 48, BOX)
	var many := GimballedStation.fitting_font_size("a\nb\nc\nd\ne\nf\ng\nh\ni\nj\nk\nl", _font(), 48, BOX)
	assert_int(many).is_less_equal(few)
