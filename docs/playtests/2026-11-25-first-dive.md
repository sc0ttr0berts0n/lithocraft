# Play test: the first dive (25 November 2026)

The developer's first play of the first-dive build (`dev` at 8ffb67b: tickets #2 to #30), recorded and narrated. Played cold, with no explanation beyond the on-screen keys.

**Headline:** "I bet you this is fun if I knew what I was doing. This sounds like interesting shit." Every system was found and poked, but the player never knew what to do or why. Teaching the dive is the biggest gap.

## What worked

- Reading every Station's keys on its screen: "Now I'm just reading them all because I realize I can."
- The Reactor's plasma waves: "It looks cool. I'm kind of excited for the visuals to come along." Detuning with N/M and watching it drift back into phase was enjoyable even without understanding it.
- Quiet Ship's noise readout made sense: noise falls when quiet and rises under way.
- Pulsing at Navigation filled in the point cloud, and repeated pulses added detail.
- Drive power (T) got the Lithocraft moving, grip slip showed, and "that actually gave me a sensation of movement for a second there."
- The Bore Station's call (blinking) drew the player over.

## Findings

### Onboarding: the player did not know what to do

1. **No goal or first step.** "Initially I don't know what to do at all." "I don't know what the fuck I'm doing. It's so clear." There is no objective, no suggested order, and nothing says that a dive starts with power at the Drive.
2. **The Course does not move the Lithocraft by itself.** The player set the Course to dive at Navigation and expected motion; nothing moved until they found power (T) at the Drive. The split between "Navigation plots, the Drive steers" and "the Drive supplies power" was not discoverable.
3. **Readings are unexplained.**
   - What the purple points in the point cloud mean.
   - What the red and white waves at the Reactor are.
   - Why R (Shift) changes the plasma.
   - What "unsteady 91%" asks the crew to do.
   - The Bore Station: what "observe the next feature" gives, how to read "fulgurite, no features in the column", and what upload priority (newest or oldest first) means.
   - What the link is.
4. **The Shift was a surprise and failed.** "Oh, it's time for a shift. Do I just hit R to shift? Boop. Huh. I shifted and it hated it." The plasma was lost and the crew brought home through the open tunnel. The player read it as death ("we're dead").

### Controls and the Habitat

5. **No mouse look while the Arm holds you.** "That is driving me crazy when I'm in the arm. I just still want to be able to look around." Highest-priority control fix.
6. **Stations all face the same way.** They were expected to face inward to the Bore. "That's okay for now."
7. **The Drive and Navigation should be next to each other**, since steering and the Course go together.
8. **Wants to click.** Understood as later (widgets, levers, knobs), but felt strongly: "Man, I really want to click."

### Screens

9. **"Power 3 of 3%" (Thermal) and "5 of 5%" (Navigation) read as nonsense.** The draw-of-budget wording needs rethinking.
10. **Text is cut off on the Thermal screen.**
11. **The Drive has no visuals.** "I don't really confidently know what I would do here."
12. **Pitch and heading have no visuals** at Navigation or the Drive.
13. **The point cloud's rotation confuses.** The player could not tell whether the Lithocraft or the display was spinning, and the Navigation screen showed no sign of the Lithocraft moving.
14. **Pulses accumulate points without limit** (1,108 after mashing). Possible performance problem; no cap or fading.

### Feel

15. **Too much shake at the end.** It should shake and lurch, then come to rest in a still final state.

## Not reached

The player never reached the granite, a seal, a stranding with its clock, self-destruct, the debug menu, or surfacing with a payment. None of the hull wear work (#20 to #30) was seen in play.
