#!/usr/bin/env python
"""Lints every GDScript of ours and checks line endings (ticket #79).

    python tools/lint/lint.py
        Every .gd file under sim/, view/, test/ and tools/ (tracked, or new
        and not ignored; addons/ is not ours): gdlint with the repo's
        .gdlintrc, and no tab after the start of a line, which is what a
        lost backslash continuation leaves behind. Every tracked text file,
        and every new one: no CRLF line ending, except where .gitattributes
        asks for one (the .cmd and .bat files, in the working tree only).

    python tools/lint/lint.py <file>...
        The same checks on the files named.

Exit 0 when clean, 1 on a finding, 2 when gdtoolkit is missing or at the
wrong version. Install the pinned version once:

    python -m pip install -r tools/lint/requirements.txt

No Godot needed; the whole run takes a few seconds.
"""

import importlib.metadata
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
REQUIREMENTS = ROOT / "tools" / "lint" / "requirements.txt"
OURS = ("sim/", "view/", "test/", "tools/")

# A tab after anything but a tab. Indentation is tabs only (gdlint checks
# mixed tabs and spaces), so a tab further in is a joined line: a shell
# heredoc that eats `\` and the newline keeps the next line's indentation.
_STRAY_TAB = re.compile(r"[^\t]\t+")


def main(argv: list[str]) -> int:
    wanted = _pinned_version()
    try:
        installed = importlib.metadata.version("gdtoolkit")
    except importlib.metadata.PackageNotFoundError:
        installed = None
    if installed != wanted:
        print(
            f"gdtoolkit {wanted} is needed (found {installed or 'none'}); install it with\n"
            f"    {Path(sys.executable).name} -m pip install -r tools/lint/requirements.txt",
            file=sys.stderr,
        )
        return 2

    named = [Path(a).resolve().relative_to(ROOT).as_posix() for a in argv]
    files = named or _repo_files()
    scripts = [f for f in files if f.endswith(".gd") and (named or f.startswith(OURS))]

    findings = _line_endings(files) + _stray_tabs(scripts)
    for finding in findings:
        print(finding)

    gdlint_failed, gdlint_out = _gdlint(scripts) if scripts else (False, [])
    for line in gdlint_out:
        print(line)

    if findings or gdlint_failed:
        problems = len(findings) + sum(1 for line in gdlint_out if re.match(r"\S+:\d+: ", line))
        print(f"lint: {max(problems, 1)} finding(s) in {len(scripts)} scripts and {len(files)} files")
        return 1
    print(f"lint: clean, {len(scripts)} scripts and {len(files)} files")
    return 0


def _gdlint(scripts: list[str]) -> tuple[bool, list[str]]:
    """gdlint's verdict and its lines, less its own summary; it reads .gdlintrc from ROOT."""
    linted = subprocess.run(
        [sys.executable, "-m", "gdtoolkit.linter", *scripts],
        cwd=ROOT,
        capture_output=True,
        text=True,
        encoding="utf-8",
    )
    lines = [
        line for line in (linted.stdout + linted.stderr).splitlines()
        if line and not line.startswith(("Success:", "Failure:"))
    ]
    if linted.returncode not in (0, 1):
        lines.append(f"gdlint itself failed (exit {linted.returncode}); see the Python note in docs/conventions/lint.md")
    return linted.returncode != 0, lines


def _pinned_version() -> str:
    for line in REQUIREMENTS.read_text(encoding="utf-8").splitlines():
        match = re.match(r"gdtoolkit==(\S+)", line.strip())
        if match:
            return match.group(1)
    raise SystemExit(f"no gdtoolkit==<version> line in {REQUIREMENTS}")


def _git(*args: str) -> str:
    return subprocess.run(
        ["git", *args], cwd=ROOT, check=True, capture_output=True, text=True, encoding="utf-8"
    ).stdout


def _repo_files() -> list[str]:
    listed = _git("ls-files", "-z", "--cached", "--others", "--exclude-standard")
    return sorted({f for f in listed.split("\0") if f and (ROOT / f).is_file()})


def _line_endings(files: list[str]) -> list[str]:
    """A CRLF in the index, or in the working tree where .gitattributes wants LF."""
    findings = []
    wanted = set(files)
    listed = _git("ls-files", "-z", "--eol", "--cached", "--others", "--exclude-standard")
    for entry in listed.split("\0"):
        if not entry:
            continue
        info, path = entry.split("\t", 1)
        if path not in wanted:
            continue
        index, tree, *attr = info.split()  # i/lf w/crlf attr/text eol=crlf
        if index in ("i/crlf", "i/mixed"):
            findings.append(f"{path}:1: CRLF line endings in the repository (git add --renormalize {path})")
        elif tree in ("w/crlf", "w/mixed") and "eol=crlf" not in attr:
            findings.append(f"{path}:1: CRLF line endings in the working tree; save it with LF")
    return findings


def _stray_tabs(scripts: list[str]) -> list[str]:
    findings = []
    for path in scripts:
        text = (ROOT / path).read_text(encoding="utf-8")
        for number, line in enumerate(text.split("\n"), start=1):
            if _STRAY_TAB.search(line.rstrip("\r")):
                findings.append(
                    f"{path}:{number}: a tab after the start of the line, as a lost "
                    f"backslash continuation leaves it (stray-tab)"
                )
    return findings


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
