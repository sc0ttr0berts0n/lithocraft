# How features of interest look in the Column (view/feature_look.gd), read
# against the layouts the Scenarios dive through. Plain data, no scene.
extends GdUnitTestSuite


## Every kind of feature any Scenario's layout holds.
func _kinds_in_the_layouts() -> Array[StringName]:
	var kinds: Array[StringName] = []
	for scenario in Scenario.all():
		for entry in scenario.layout.features():
			var kind: StringName = entry[1].kind
			if not kind in kinds:
				kinds.append(kind)
	return kinds


func test_every_feature_kind_in_the_layouts_has_a_look_in_the_column() -> void:
	var kinds := _kinds_in_the_layouts()

	assert_array(kinds).is_not_empty()
	for kind in kinds:
		assert_bool(FeatureLook.has_look(kind)) \
				.override_failure_message("A %s has no look in the Column: add it to FeatureLook.LOOKS" % kind) \
				.is_true()


func test_a_kind_nobody_drew_has_no_look() -> void:
	assert_bool(FeatureLook.has_look(&"curiosity")).is_false()


func test_every_look_is_its_own() -> void:
	var painters := {}
	for kind in FeatureLook.LOOKS:
		painters[FeatureLook.LOOKS[kind].paint] = true

	assert_int(painters.size()).is_equal(FeatureLook.LOOKS.size())
