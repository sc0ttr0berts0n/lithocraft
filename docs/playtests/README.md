# Play tests

Each play test is played cold, narrated and screen-recorded (NVIDIA ShadowPlay, 4K60 AV1, into `C:/Users/Scott/Videos/NVIDIA/Godot/`). The developer points the agent at the video; the agent turns it into a write-up here.

## Layout

- `YYYY-MM-DD-<name>.md`: the write-up. What worked, findings with video timestamps (mm:ss), what was not reached.
- `YYYY-MM-DD-<name>/transcript.md` and `transcript.json`: the narration, machine-transcribed with per-word times.
- Frames stay out of the repo, in `<video name>.analysis/` beside the video. Quote timestamps instead; the frames can be pulled again at any time.

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
| Small text (a screen, the Checklist) | `crop VIDEO 4:20 --box 0,30,560,330` | full-res pixels, 4K coordinates |

## Method

1. Transcribe first and read the whole narration: it is the index of complaints, surprises and praise.
2. For each complaint, pull a frame at the moment it was said, then a sheet over the stretch around it to see what led to it.
3. Crop to read text the frame is too small for (the Checklist, Reactor readings, key panels).
4. Cross-check against the simulation's code when the video shows something the design did not intend.
5. Write up, then grill the developer on the findings before any ticket is cut.
