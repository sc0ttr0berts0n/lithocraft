"""Play-test video toolkit: a timestamped transcript of the narration, and frames on demand.

Run with the venv that has faster-whisper (see docs/playtests/README.md):

    PY=~/.venvs/playtest/Scripts/python.exe
    $PY tools/playtest/playtest.py transcribe VIDEO            # transcript.json + transcript.md
    $PY tools/playtest/playtest.py frame VIDEO 12:34.5 [--width 1600]
    $PY tools/playtest/playtest.py burst VIDEO 12:30 --dur 5 --step 0.5   # one frame every step
    $PY tools/playtest/playtest.py sheet VIDEO 12:30 --dur 20 --step 2     # one tiled contact sheet
    $PY tools/playtest/playtest.py crop VIDEO 12:34 --box x,y,w,h          # full-res crop (4K pixels)

Frames go to "<video folder>/<video name>.analysis/", next to the video and out of the repo.
Times are seconds (754.5) or m:ss(.s) or h:mm:ss.
"""

import argparse
import json
import os
import subprocess
import sys
from pathlib import Path


def parse_time(text):
    parts = [float(p) for p in str(text).split(":")]
    seconds = 0.0
    for p in parts:
        seconds = seconds * 60 + p
    return seconds


def stamp(seconds, sep=":"):
    m, s = divmod(seconds, 60)
    return f"{int(m):02d}{sep}{s:04.1f}"


def out_dir(video):
    video = Path(video)
    d = video.parent / (video.stem + ".analysis")
    d.mkdir(exist_ok=True)
    return d


def ffmpeg(*args):
    cmd = ["ffmpeg", "-hide_banner", "-loglevel", "error", "-y", *args]
    subprocess.run(cmd, check=True)


def add_cuda_dlls():
    # pip's nvidia-cublas / nvidia-cudnn wheels put their DLLs under site-packages/nvidia/*/bin.
    if os.name != "nt":
        return
    import site
    for sp in site.getsitepackages():
        root = Path(sp) / "nvidia"
        if root.is_dir():
            for b in root.glob("*/bin"):
                os.add_dll_directory(str(b))
                os.environ["PATH"] = str(b) + os.pathsep + os.environ["PATH"]


def cmd_transcribe(a):
    add_cuda_dlls()
    from faster_whisper import WhisperModel

    d = out_dir(a.video)
    wav = d / "audio.wav"
    if not wav.exists():
        ffmpeg("-i", str(a.video), "-vn", "-ac", "1", "-ar", "16000", str(wav))
    model = WhisperModel(a.model, device=a.device, compute_type="float16" if a.device == "cuda" else "int8")
    # Read the 16 kHz mono wav ourselves: faster-whisper's PyAV decode breaks across PyAV versions.
    import wave
    import numpy as np
    with wave.open(str(wav), "rb") as w:
        audio = np.frombuffer(w.readframes(w.getnframes()), dtype=np.int16).astype(np.float32) / 32768.0
    segments, info = model.transcribe(
        audio, language="en", word_timestamps=True, vad_filter=True,
        initial_prompt=a.prompt,
    )
    rows = []
    for s in segments:
        rows.append({
            "start": round(s.start, 2), "end": round(s.end, 2), "text": s.text.strip(),
            "words": [{"t": round(w.start, 2), "w": w.word} for w in (s.words or [])],
        })
        print(f"[{stamp(s.start)}] {s.text.strip()}", flush=True)
    dest = Path(a.out) if a.out else d
    dest.mkdir(parents=True, exist_ok=True)
    (dest / "transcript.json").write_text(json.dumps(rows, indent=1), encoding="utf-8")
    lines = [f"# Transcript: {Path(a.video).name}", "",
             f"Narration, machine-transcribed (faster-whisper {a.model}); timestamps are mm:ss into the video.", ""]
    lines += [f"- **{stamp(r['start'])}** {r['text']}" for r in rows]
    (dest / "transcript.md").write_text("\n".join(lines) + "\n", encoding="utf-8")
    print(f"wrote {dest / 'transcript.md'}", file=sys.stderr)


def frame_at(video, t, width, name=None):
    d = out_dir(video)
    path = d / (name or f"f_{stamp(t, '-')}_w{width}.jpg")
    scale = [] if width <= 0 else ["-vf", f"scale={width}:-1"]
    ffmpeg("-ss", f"{t:.3f}", "-i", str(video), "-frames:v", "1", *scale, "-q:v", "3", str(path))
    return path


def cmd_frame(a):
    print(frame_at(a.video, parse_time(a.time), a.width))


def cmd_burst(a):
    t0, n = parse_time(a.time), int(round(a.dur / a.step))
    for i in range(n + 1):
        print(frame_at(a.video, t0 + i * a.step, a.width))


def cmd_sheet(a):
    # One seek, then fps-select frames and tile them: cheap to read as one image.
    t0 = parse_time(a.time)
    n = int(round(a.dur / a.step)) + 1
    cols = a.cols or min(n, 4)
    rows = -(-n // cols)
    d = out_dir(a.video)
    path = d / f"sheet_{stamp(t0, '-')}_{a.dur:g}s_every{a.step:g}s.jpg"
    vf = (f"fps=1/{a.step},scale={a.width}:-1,"
          f"drawtext=text='%{{pts\\:hms\\:{t0}}}':x=8:y=8:fontsize=28:fontcolor=yellow:box=1:boxcolor=black@0.6,"
          f"tile={cols}x{rows}")
    ffmpeg("-ss", f"{t0:.3f}", "-t", f"{a.dur + 0.01:.3f}", "-i", str(a.video), "-vf", vf,
           "-frames:v", "1", "-q:v", "3", str(path))
    print(path)


def cmd_crop(a):
    t = parse_time(a.time)
    x, y, w, h = a.box.split(",")
    d = out_dir(a.video)
    path = d / f"crop_{stamp(t, '-')}_{x}_{y}_{w}x{h}.png"
    ffmpeg("-ss", f"{t:.3f}", "-i", str(a.video), "-frames:v", "1", "-vf", f"crop={w}:{h}:{x}:{y}", str(path))
    print(path)


def main():
    p = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    sub = p.add_subparsers(dest="cmd", required=True)

    t = sub.add_parser("transcribe")
    t.add_argument("video")
    t.add_argument("--model", default="large-v3")
    t.add_argument("--device", default="cuda")
    t.add_argument("--out", help="folder for transcript.md/json (default: the .analysis folder)")
    t.add_argument("--prompt", default="Lithocraft, Habitat, Bore, Station, Reactor, Drive, Thermal, Navigation, "
                   "Fabricator, Shift, Shift dial, standby, active, Quiet Ship, Course, Checklist, Orders, "
                   "autopilot, explainer, point cloud, granite, sandstone, plasma.")
    t.set_defaults(fn=cmd_transcribe)

    f = sub.add_parser("frame")
    f.add_argument("video"); f.add_argument("time")
    f.add_argument("--width", type=int, default=1600, help="0 for full 4K")
    f.set_defaults(fn=cmd_frame)

    b = sub.add_parser("burst")
    b.add_argument("video"); b.add_argument("time")
    b.add_argument("--dur", type=float, default=5); b.add_argument("--step", type=float, default=0.5)
    b.add_argument("--width", type=int, default=1280)
    b.set_defaults(fn=cmd_burst)

    s = sub.add_parser("sheet")
    s.add_argument("video"); s.add_argument("time")
    s.add_argument("--dur", type=float, default=20); s.add_argument("--step", type=float, default=2)
    s.add_argument("--width", type=int, default=800); s.add_argument("--cols", type=int, default=0)
    s.set_defaults(fn=cmd_sheet)

    c = sub.add_parser("crop")
    c.add_argument("video"); c.add_argument("time")
    c.add_argument("--box", required=True, help="x,y,w,h in source pixels")
    c.set_defaults(fn=cmd_crop)

    a = p.parse_args()
    a.fn(a)


if __name__ == "__main__":
    main()
