"""Tests for playtest.py's sheet grid and regions, on a generated ffmpeg test video (no recording needed).

Run: python -m unittest tools/playtest/test_playtest.py   (needs ffmpeg and ffprobe on PATH)
"""

import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
import playtest  # noqa: E402

TILE_W = 160


def size(path):
    out = subprocess.run(["ffprobe", "-v", "error", "-show_entries", "stream=width,height", "-of", "csv=p=0", str(path)],
                         capture_output=True, text=True, check=True).stdout.strip()
    return tuple(int(v) for v in out.split(","))


class Args:
    def __init__(self, **kw):
        self.__dict__.update(dict(dur=20, step=2, width=None, cols=0, region=None, box=None), **kw)


class PlaytestTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.tmp = tempfile.TemporaryDirectory()
        cls.video = Path(cls.tmp.name) / "t.mp4"
        # 4K, so the 4K region boxes are valid. Low frame rate keeps it quick.
        subprocess.run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-f", "lavfi", "-i",
                        "testsrc=size=3840x2160:rate=5", "-t", "70", "-pix_fmt", "yuv420p", str(cls.video)], check=True)

    @classmethod
    def tearDownClass(cls):
        cls.tmp.cleanup()

    def sheet(self, **kw):
        import io
        from contextlib import redirect_stdout
        buf = io.StringIO()
        with redirect_stdout(buf):
            playtest.cmd_sheet(Args(video=str(self.video), time="10", **kw))
        return Path(buf.getvalue().strip())

    def test_no_empty_tile_beyond_last_row_remainder(self):
        for dur, step, cols in [(54, 6, 3), (20, 2, 0), (12, 3, 0), (10, 2.5, 2), (20, 5, 4), (30, 10, 3)]:
            n = playtest.sheet_frame_count(dur, step)
            path = self.sheet(dur=dur, step=step, cols=cols, width=TILE_W)
            w, h = size(path)
            c = cols or min(n, 4)
            tile_h = round(TILE_W * 9 / 16)
            self.assertEqual(w, TILE_W * c)
            self.assertEqual(h // tile_h, -(-n // c), f"rows for {dur=} {step=} {cols=}")
            # ffmpeg really yields n frames for the same cut: no phantom frame, none missing.
            out = subprocess.run(["ffmpeg", "-hide_banner", "-loglevel", "error", "-ss", "10", "-t", str(dur + step / 2),
                                  "-i", str(self.video), "-vf", f"fps=1/{step}", "-f", "image2pipe", "-c:v", "mjpeg", "-"],
                                 capture_output=True, check=True).stdout
            self.assertEqual(out.count(b"\xff\xd8\xff"), n)

    def test_region_sheet_tiles_only_the_region_at_its_native_width(self):
        x, y, w, h = playtest.REGIONS["checklist"]
        path = self.sheet(dur=10, step=5, cols=3, region="checklist")
        self.assertEqual(size(path), (w * 3, h * 1))

    def test_region_table_and_box(self):
        self.assertEqual(playtest.REGIONS["checklist"], (0, 30, 560, 330))
        self.assertIn("screen", playtest.REGIONS)
        self.assertEqual(playtest.region_box(box="1,2,3,4"), (1, 2, 3, 4))
        self.assertIsNone(playtest.region_box())
        with self.assertRaises(SystemExit):
            playtest.region_box(name="nope")
        with self.assertRaises(SystemExit):
            playtest.region_box(name="screen", box="1,2,3,4")

    def test_frame_crops_to_region(self):
        path = playtest.frame_at(self.video, 3.0, None, playtest.REGIONS["checklist"], "_checklist")
        self.assertEqual(size(path), (560, 330))
        path = playtest.frame_at(self.video, 3.0, 280, playtest.REGIONS["checklist"], "_checklist")
        self.assertEqual(size(path), (280, 166))


if __name__ == "__main__":
    unittest.main()
