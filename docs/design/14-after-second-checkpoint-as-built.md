# After the second checkpoint: as built

Agent's choices within round 3's design (spec #71), one bullet per ticket.

- **Features of interest in the Column (ticket #70, agent's choices within the design).**
  The play test's iron concretions were drawn, but as marbles two to four centimetres across, the size of the grain speckle round them, at a place round the Column picked per feature, so often on the far side from the Bore Station.
  Every feature is now turned to the Bore Station's side of the Column: the crew turn round from its screen and it is there.
  Where a feature lies along the Bore is the simulation's alone (its distance behind the Head); which way it faces is the view's, since a Column is cut all the way round and the simulation says nothing of it.
  It passes the Bore Station (the height its gimbal hangs at) when the simulation's distance behind the Head equals the Station's, a little below the seated crew's eyes with the Tail up, and reaches eye height a moment later.
  Each kind has its own look, sized to be seen from across the Habitat (tuned for play, ADR 0001: real concretions and fulgurites are mostly smaller).
    - Iron concretions: rusty marbles in a patch of sandstone bleached pale.
      Real ones (the Navajo Sandstone's "Moqui marbles") grew where groundwater stripped the iron from the red rock, bleaching it, and dropped it again as balls of hematite and goethite; the pale patch is that bleached rock and is what makes them findable against red sandstone.
    - Petrified wood: a trunk cut across at a slant, so a tall oval of growth rings in agate reds and creams inside a rind of bark, with quartz in the drying cracks that run out from the heart.
      Silica replaces wood cell by cell, so the rings survive; iron colours it red and orange.
    - Fulgurite: a dark glass tube with a branch or two inside a pale sleeve of sintered sand, as lightning leaves in dune sand.
    - Quartz vein and pegmatite keep the looks they had: a white sheet right round the Column (a slanted plane unwrapped is a sine wave), and a pale pocket of giant crystals with tourmaline and garnet.
  A feature is still in the Habitat's stretch of the Bore for only a few seconds at speed, and the Bore Station's list gives it in metres behind the Head, which the crew cannot turn into "look now"; the taller Habitat (#68) lengthens the pass, and the screen's wording is left to the screens' rebuild (#62).
- **The point cloud's three candidate views (ticket #67): awaiting the developer's pick.**
  Navigation's scan display draws one of three views of the same scan, flipped with the debug key F4 during a dive; the caption over the picture names the one shown.
  The developer picks one in the next play test; until then none is the design, and the other two go when one is picked.
  Each draws the vessel, the Course, the projected path, the points and the Inferred Boundaries; the moving map beside it is unchanged.
    - **1. Forward scope** (shown when a dive starts, the agent's pick).
      The vessel sits low on the screen with ahead straight up, range rings every 50 m about the Head, as a forward-looking sonar's fan.
      What it shows is the vessel's own vertical plane; in a dive it is the moving map flipped top to bottom, so a turn bends the same way on both.
      A return off that plane is drawn where it meets the plane square on, so a level Boundary is one line at any pitch, and its range ahead is read off the rings.
      A plumb line with a tick on each ring shows where down is: up the screen in a dive, swinging to the left as the vessel levels.
      Real basis: a forward-looking sonar's sector display, and a ship radar's head-up mode.
      Its cost is the play test's complaint in a milder form: in a dive, down is still up the screen, though now labelled.
    - **2. Plan and section pair.**
      A top-down plan beside a side-on section, at one scale, both with ahead (the compass heading) to the right, as the moving map has it, and nothing in 3D.
      The section has deeper lower, with a line and its depth every 50 m; the plan shows what lies left and right of the track, which the section cannot.
      Real basis: the plan and profile sheets of a drilled well or a tunnel drive.
      Its cost: the plan says little in a dive straight down, where the vessel is a ring seen end-on, and each view is half the width.
      The pair is side by side, not stacked: the screen is wide and short, and a stacked section had no room to show what lies below.
    - **3. World-up 3D.**
      The cloud seen from above the vessel's right side and a little behind, with no perspective, deeper always lower, the eye going round only with the compass heading; ahead is to the right, as on the moving map.
      A level ring with north marked and a plumb line with a tick every 50 m give the eye its bearings.
      Its cost: a flat picture of 3D cannot tell further from higher without those marks.
  Agent's choices: the candidate shown is held by the simulation (`scan_view()`), though it is nothing of the dive, so that the screenshot tool and a test can set it with the one debug command.
  All three are flat drawings through one function each from a place in the world to a place on the screen, so none can turn on its own, and the points stream past at the simulation's speed.
  The scope's range is fixed (rings to 250 m), so a Boundary a few tens of metres ahead sits close to the vessel's marker; a range that follows the nearest return is left for whichever view is picked.
  Points are white as they are certain and grey as they are a guess (the colour language's "now"), larger the surer, and never fade out altogether: #62 had left them faint.
