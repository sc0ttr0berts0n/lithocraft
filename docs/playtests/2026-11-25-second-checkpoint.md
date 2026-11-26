# Play test: the second checkpoint (25 November 2026)

The developer's First dive on the second checkpoint build (`dev` at b6fa3cf: round 2, #31 to #43, the Shift dial #56), recorded and narrated, 18 minutes. Video: `Godot 2026.11.25 - 23.00.20.16.mp4`. Transcript: [`2026-11-25-second-checkpoint/transcript.md`](2026-11-25-second-checkpoint/transcript.md). Timestamps below are mm:ss into the video.

**Headline:** the dive ended in the sandstone with the plasma lost: "Yep, killed the ship" (18:03). Two causes, both silent: the Checklist jumped to "Turn and climb" at 04:17, so the player followed the wrong phase for the rest of the dive; and the Head was worn from 41% to 89% in one moment at 08:49, nine minutes before the Shift that lost it. "I have no earthly idea, but I'm happy to be playing" (12:00).

## What worked

- The Drive's flight display: "glad to see a drive interface that looks a little bit like a craft" (02:20); "I do love the autopilot-inspired interface" (13:49). Grip (02:36), T/G for throttle (02:37).
- Thermal's text fits (01:37). Navigation beside the Drive: "How nice" (03:56).
- The Checklist was found and read; the Orders understood (06:07 to 06:34).
- The moving map showed the pulses' returns: "I kind of feel like I know what I'm getting into there" (04:54).
- Mouse look in the Arm, and the Arm wrapping round the ring (05:25 to 05:36): "I might just get used to being held by the arm."
- Grip slip and "ease off with G": "I like that. That's fun" (06:53).
- The F3 debug overlay and its Column strip: "a cute bit of interface … I like it, maybe, all the time" (03:03 to 03:18).
- Seeing the vessel in fast time and being forced into the Arm "because the world is getting weird around me" (15:17); the petrified wood seen in the Column (15:42); the path on the moving map (16:16).

## Findings

### The Checklist jumped to the end

1. **Plotting a climb at the surface began "Turn and climb" (6 of 7).** Hunting for the dive key at Navigation (04:07 to 04:17), the player pressed 3 (climb) before 1. A climbing Course plotted is one of #34's early triggers for that phase, so startup's last step ("Engage the Drive's autopilot") and phases 2 to 5 were left behind. From then the Checklist read "Climb: the Drive follows the Course round" (05:08, 06:34), the Drive's autopilot was never engaged, and the player drove by hand all dive.

### How the plasma was lost

2. **Pretuning failed.** At the first Boundary (07:55) STANDBY's MATCH reached 15% at best: "this really makes me nervous, because I still don't quite know how to do it" (08:02).
3. **The swap at 08:29 was a poor, late Shift:** Head wear 0% to 41%, the Reactor's autopilot disengaged by R.
4. **Engaging the autopilot made an overdue Shift at once, wearing the Head from 41% to 89%** (between 08:45 and 08:52). The player said "I'm going to turn off autopilot" (08:49) but it was already off, so E turned it on, and the autopilot, long past its moment, swapped straight away. Nothing marked the jump.
5. **A worn Head stays unsteady whatever the tuning.** From 08:52 the plasma read "UNSTEADY 73%" with ACTIVE at MATCH 100% (wear's own unsteadiness), which looks like a tuning fault.
6. **The second Boundary (17:00) was fatal.** STANDBY sat at MATCH 0% for a minute. "The colours to me on this just aren't clear" (17:08). "I don't see, like, a timing for this reactor jump" (17:24). "I hit shift and nothing happened" (17:58): the key line "swap STANDBY in: the Shift" was read as the Shift key. Then R, and on an 89% Head the plasma was lost (17:59).

### Tuning the dial

7. **What N/M change was unclear.** "I think the gray is the resultant wave … it's awfully confusing" (09:27). The player took it for cancelling a signal with its opposite (09:46) and expected "phase, frequency, and amplitude" (09:52). Wants tuning on the scroll wheel or a mouse drag (09:21).

### Turning for home

8. **The Course and the Drive's override disagreed.** Navigation's Course stayed dive (+90) while the Drive overrode to climb (−90): "I'm getting confused about the dissonance between these" (11:29).
9. **The turn from straight down is slow and still deepens.** "If I hit one, I go down, and if I hit three, I think I also go down" (11:10). "I really want to climb. I don't want to tilt" (13:09). The throttle has no reverse (12:27). "How do I get home?" (12:31). The player expected to back out the hole they came down (16:02).
10. **Developer's idea: project the turn.** "I'd like to see it project the circle I'm spinning … so I can decide if it's safe to do the turn, based on what we know about the area" (16:30 to 16:43).

### Screens and the Habitat

11. **A Station's floating status text is huge up close** and runs off the top of the view; a Station cannot be taken in at once (00:42, frames at 02:03 and 04:52). Key panels overflow ("override: dive / level / clim", 02:25). In the Arm the screen is "a little further than I want" (05:43).
12. **Keys feel scattered; still wants to click** (00:01, 01:37). A quick way to tell Stations apart (03:41).
13. **The autopilot tone is shrill** (00:30).
14. **The head-up point cloud's yellow dot "doesn't jive"** (02:08); "if we're drilling down, I'd expect the UI to be down, but it's up above" (01:59). Pulses appeared "above me" rather than ahead (15:04).
15. **Thermal is text only:** a HEAT WARNING (hull 551 K against 600 K) came and went at 14:08 to 14:14 with no sense of how bad it was (14:18).
16. **The Bore Station's science is unreadable** (07:31), and observed features do not show in the Column (12:05, 14:34), though the petrified wood did (15:42).
17. **Plotting felt too immediate:** "I thought it would be more of a planning phase where we'd look more" (04:29).
18. **Developer's idea: the debug readings all the time, in a helmet HUD** (03:11 to 03:18).

## Not reached

The granite, a seal, uploads under a sealed link, the stranding and rescue, surfacing and payment, the explainer (not yet built), and the drills.
