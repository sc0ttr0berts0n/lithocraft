# Play tests

Each play test is played cold, narrated and screen-recorded (NVIDIA ShadowPlay, 4K60 AV1, into `C:/Users/Scott/Videos/NVIDIA/Godot/`). The developer points the agent at the video; the agent turns it into a write-up here.

## Layout

- `YYYY-MM-DD-<name>.md`: the write-up. What worked, findings with video timestamps (mm:ss), what was not reached.
- `YYYY-MM-DD-<name>/transcript.md` and `transcript.json`: the narration, machine-transcribed with per-word times.
- `YYYY-MM-DD-<name>/frames/`: the few frames that carry a finding, named `mm-ss-<what>.jpg` and listed in the write-up's Frames table. The developer deletes the video once the write-up lands, so commit these before then.
- Working frames (bursts, sheets, everything else) stay out of the repo, in `<video name>.analysis/` beside the video.

## The toolkit: `tools/playtest/playtest.py`

Needs `ffmpeg` (on PATH via Chocolatey) and a venv with faster-whisper at `~/.venvs/playtest` (Python 3.12, CUDA on the RTX 4090). To rebuild it:

```
~/AppData/Local/Programs/Python/Python312/python.exe -m venv ~/.venvs/playtest
~/.venvs/playtest/Scripts/python.exe -m pip install faster-whisper nvidia-cublas-cu12 "nvidia-cudnn-cu12==9.*"
```

Commands (`PY=~/.venvs/playtest/Scripts/python.exe`; times are seconds or m:ss):

| Need | Command | Cost |
|---|---|---|
| What was said, when | `$PY tools/playtest/playtest.py transcribe VIDEO --out docs/playtests/<date-name>` | ~70 s for 18 min (large-v3 on GPU) |
| One moment | `frame VIDEO 4:17 [--width 1600]` (`--width 0` for full 4K) | <1 s |
| A motion or a sequence | `burst VIDEO 8:20 --dur 5 --step 0.5` | one file per frame |
| A stretch at a glance | `sheet VIDEO 7:52 --dur 54 --step 6 --cols 3` | one tiled, time-stamped image |
| Small text (a screen, the Checklist) | `crop VIDEO 4:20 --region checklist` | full-res pixels, 4K coordinates |
| One panel over time | `sheet VIDEO 7:52 --dur 54 --step 6 --region checklist` | tiles only the region, at its own width |

`frame`, `burst`, `sheet` and `crop` all take `--region NAME` or `--box x,y,w,h` (4K pixels, for anything else); the first three crop, then scale, and a region's default width is its own. A sheet has exactly the frames the span yields, so no blank tile ends it. Regions live in one table, `REGIONS` in the script:

| Region | 4K box `x,y,w,h` | What |
|---|---|---|
| `checklist` | `0,30,560,330` | the upper-left panel |
| `screen` | `960,540,1920,1080` | the middle of the view, where a Station's screen sits |

Tests: `python -m unittest tools/playtest/test_playtest.py` (builds its own ffmpeg test video).

## Method

1. Transcribe first and read the whole narration: it is the index of complaints, surprises and praise.
2. For each complaint, pull a frame at the moment it was said, then a sheet over the stretch around it to see what led to it.
3. Crop to read text the frame is too small for (the Checklist, Reactor readings, key panels).
4. Cross-check against the simulation's code when the video shows something the design did not intend.
5. Write up, copy the frames that carry a finding into `frames/`, then grill the developer on the findings before any ticket is cut.
