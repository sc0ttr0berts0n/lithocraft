# Layout

- `sim/`: the simulation.
  Every class is `RefCounted` with a `class_name`; nothing here touches the scene tree, `Input` or rendering.
  `DiveSimulation` is the one seam; `Medium`, `MediumLayout`, `SurveyStretch`, `ColumnFeature` and `ScanPoint` are data it reads or hands out.
  `Heat`, `Plasma`, `Stranding`, `LookAhead`, `ProjectedPath` and `RingSlide` are subsystems it owns (see Subsystems).
  `Scenario` is the data of a Scenario and `Checklist` the dive's progress through it (see Scenarios).
- `view/`: scenes and view logic.
  `view/start_menu.tscn` (`StartMenu`) is the main scene; it starts `view/habitat.tscn` with the chosen Scenario.
  `Arm` (`view/arm.gd`), `HullGroans` (`view/hull_groans.gd`), `KeyMap` (`view/key_map.gd`), `PowerLine` (`view/power_line.gd`), `ChecklistPanel` (`view/checklist_panel.gd`; `ChecklistPanel.text_of()` is the Tab panel's text, tested directly), `KeyPrompt` (`view/key_prompt.gd`;
  `KeyPrompt.rect()` builds a screen-space prompt for the F1 controls and the debug menu) `OutcomeScreen` (`view/outcome_screen.gd`), `FlightTape` (`view/flight_tape.gd`, a tape or pitch ladder of the Drive's flight display) and `Pointing` (`view/pointing.gd`, what lies under the centre dot) are view logic as plain `RefCounted`s, tested directly (plain transforms; a seeded RNG;
  plain data).
  `StationTheme` (`view/station_theme.gd`, the Station screens' one Theme and colours) `CautionLamps` (`view/caution_lamps.gd`, each Station's lamps from the simulation) and `ScreenPace` (`view/screen_pace.gd`, how often an instrument draws) are plain `RefCounted`s too.
  `StationScreen` and `KeyList` are the `SubViewport`s a Station's screen and key list are composed in (see The view's Station screens).
  A view node can be tested outside the tree when its logic needs no `Input` or physics (`crew_look_test.gd` drives `CrewMember.look()` / `hold()`); a node it makes in `_init` must be its child from then, or the test leaks orphans.
- `assets/`: vendored assets, each folder with a note of its source and licence.
  `assets/prompts/keyboard/` holds the key prompt images (Xelu's CC0 pack, the light keyboard set).
- `test/`: GdUnit4 suites, `*_test.gd`, `extends GdUnitTestSuite`, `func test_...`.
  Shared helpers in `test/support/dive_test_kit.gd`.
- `tools/`: what the developer and agents run beside the game, none of it loaded by the game.
  `tools/screenshot/` is GDScript and reads `view/` and `sim/` (`ShotPlan`, tested in `test/screenshot_test.gd`); `tools/docs/` and `tools/playtest/` are Python.
  `tools/cost/` is GDScript too, the cost budget (`CostBudget`, `CostProbe`, tested in `test/cost_budget_test.gd`; see `cost-budget.md`).
- Names and comments in `sim/` and `view/` use `GLOSSARY.md`'s terms and none of the words it says to avoid.
  A test enforces it: `test_no_avoided_glossary_term_is_used_in_the_simulation_or_the_view` (`test/convention_test.gd`) reads the glossary's `_Avoid_` lines and fails on an avoided word in an identifier, a comment or a string, whole words only (identifiers split at underscores and capitals, a final "s" dropped).
  It leaves out the avoided words that are plain English or Godot's own (`LEFT_OUT`: "path", "next", "error", "window" and the like) and allows a word in a file where it has another sense (`OTHER_SENSES`: an attitude indicator, a fulgurite's glass tube), each entry with its reason.
  A word the glossary qualifies ("warning (for a caution)") is not found by the word alone (`QUALIFIED`): the test fails on a name that says warning given a caution's value, or the other way, and the rest stay the reviewer's to judge.
  A word newly avoided in the glossary is checked from then on with no change to the test.
- Commit the `*.gd.uid` files Godot generates beside each script.
- Files are LF.
  On Windows, write files from Python with `newline=''`, or they come back CRLF.
