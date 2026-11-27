# Navigation's screens

- Navigation's point cloud (`ScanDisplay`, `view/scan_display.gd`) is three candidate views of one scan, awaiting the developer's pick (`docs/design/14-after-second-checkpoint-as-built.md`); the simulation holds which is shown (`scan_view()`, one of `scan_views()`, the forward scope when a dive starts).
  The forward scope is the vessel's own vertical plane with ahead up the screen, range rings about the Head and a plumb line to where down is (in a dive, onward along the compass heading is to the right, so a turn bends as it does on the moving map).
  Its range steps between a few fixed ranges (`SCOPE_RANGES_M`, `scope_shown()`) to keep the nearest Inferred Boundary ahead in view, changing only on a pulse; the heading line is a share of the range, so a Boundary 30 m ahead is drawn clear of the marker. The world-up view keeps its one scale.
  The plan and section pair is a top-down view beside a side-on one, ahead to the right in both and at one scale, nothing in 3D.
  The world-up 3D view has deeper always lower and goes round only with the compass heading.
  The debug key F4 (anywhere, `debug_next_scan_view()`) flips to the next, and the display's caption names the one shown, its number and the key.
  Surface control's survey points are drawn apart from the vessel's own in all three, hollow, small and faint in the legend's grey (`ScanDisplay.SURVEY_PX`, `SURVEY_ALPHA`), since they are one branch of `_draw_scan()`; `navigation.txt`'s "survey beside own" tiles show them.
  How the views are drawn, and the rules for changing them: `docs/conventions/scan.md`, "Drawing the scan".
- The Beam shows in every view as its cone (faint cyan fans out to `beam_reach()`) and the label `beam_label()` ("BEAM NARROW 30 deg") in the display's lower left; Navigation's status lines give it a line of its own (width, cone, reach, and "pulses as it goes" or "by hand only"), so the screen has five lines (`NAVIGATION_LINES`).
- Navigation's moving map (`MovingMap`, `view/moving_map.gd`) is a 2D cross-section of the whole dive, redrawn a few times a second: across is ground distance along the unrolled track (`MovingMap.profile()` of `remembered_path()`, the simulation's perfect record of the path), down is depth, at one scale both ways.
  Its Boundaries are the Inferred Boundaries (`inferred_boundaries()`), never the layout: each patch drawn side-on between its corners, placed across by how far ahead of the Head along the heading they lie (`MovingMap.across()`), as sure as its `confidence`.
  The target depth is `target_depth()`, from the Orders (`Scenario.Goal.target_depth`, NAN for a goal with none).
- The projected path (`projected_path()`) is a solid cyan line on both of Navigation's displays, beside the Course's dashes: among the points in every candidate view, on the map unrolled onward from the Head (`MovingMap.ahead()`), and the map's scale makes room for it.
