extends GdUnitTestSuite
## Deliberately failing: shows the CI job turns red on a test failure (#72). Never merged.


func test_ci_turns_red_on_a_failing_test() -> void:
	assert_bool(false).is_true()
