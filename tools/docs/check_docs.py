#!/usr/bin/env python
"""Checks the topic docs behind their indexes (ticket #74).

    python tools/docs/check_docs.py
        The standing limits: each index is under 60 lines and names every
        topic file with the condition for reading it; no topic file is over
        12 KB; no line in one is over 400 characters; every reference to an
        index by section, in the repo, names a section the index lists.

    python tools/docs/check_docs.py --against <git-ref>
        Also the split itself: every sentence of the single-file originals
        at <git-ref> is in exactly one new file, the topic files hold no
        sentence the originals did not, and every heading of the originals
        is named in its index.

    python tools/docs/check_docs.py --issues <file.json>
        Also the section references in issue bodies, from the output of
        `gh issue list --state open --json number,body`.

Exit 0 when everything holds, 1 otherwise. Standard library only.
"""

import argparse
import collections
import json
import re
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]

# index file, the directory of its topic files
DOC_SETS = [
    ("docs/conventions.md", "docs/conventions"),
    ("docs/design-record.md", "docs/design"),
]

INDEX_MAX_LINES = 59  # "under 60 lines"
TOPIC_MAX_BYTES = 12_000
LINE_MAX_CHARS = 400

# Files searched for references to an index by section.
REFERENCE_GLOBS = ["*.md", "docs/**/*.md", "sim/**/*.gd", "view/**/*.gd", "test/**/*.gd", "tools/**/*.py"]

HEADING = re.compile(r"^#{1,6} +(.*?)\s*$")
BLOCK_START = re.compile(r"^\s*(- |\|)")
SENTENCE_END = re.compile(r"""(?<=[.!?])["'”)\]*_]*\s+""")


def read(path: Path) -> str:
    return path.read_text(encoding="utf-8")


def blocks(text: str) -> list[str]:
    """Paragraphs, list items and table rows, each with its whitespace
    normalised. Headings are left out; an indented or unmarked line after a
    block continues it."""
    found: list[str] = []
    current: list[str] = []

    def close() -> None:
        if current:
            found.append(" ".join(" ".join(current).split()))
            current.clear()

    for line in text.splitlines():
        if not line.strip() or HEADING.match(line):
            close()
        elif BLOCK_START.match(line):
            close()
            current.append(line.strip())
        else:
            current.append(line.strip())
    close()
    return found


def sentences(text: str) -> list[str]:
    found: list[str] = []
    for block in blocks(text):
        start = 0
        for match in SENTENCE_END.finditer(block):
            found.append(block[start:match.end()].strip())
            start = match.end()
        if block[start:].strip():
            found.append(block[start:].strip())
    return found


def headings(text: str) -> list[str]:
    return [m.group(1) for m in map(HEADING.match, text.splitlines()) if m]


def original(ref: str, path: str) -> str:
    shown = subprocess.run(
        ["git", "show", f"{ref}:{path}"], cwd=ROOT, capture_output=True, check=True
    )
    return shown.stdout.decode("utf-8")


def check_limits(index: str, folder: str, problems: list[str]) -> None:
    index_path = ROOT / index
    topic_dir = ROOT / folder
    if not topic_dir.is_dir():
        problems.append(f"{folder}/ does not exist")
        return
    index_lines = read(index_path).splitlines()
    print(f"{index}: {len(index_lines)} lines (limit {INDEX_MAX_LINES})")
    if len(index_lines) > INDEX_MAX_LINES:
        problems.append(f"{index} is {len(index_lines)} lines, over {INDEX_MAX_LINES}")

    topics = sorted(topic_dir.glob("*.md"))
    if not topics:
        problems.append(f"{folder}/ holds no topic files")
    for topic in topics:
        name = f"{Path(folder).name}/{topic.name}"
        naming = [line for line in index_lines if name in line]
        if len(naming) != 1:
            problems.append(f"{index} names {name} on {len(naming)} lines, not 1")
        elif not re.search(r"\bRead\b.{20,}", naming[0]):
            problems.append(f"{index} names {name} without saying when to read it")
        size = topic.stat().st_size
        lines = read(topic).splitlines()
        longest = max((len(line) for line in lines), default=0)
        print(f"  {name}: {size} bytes, longest line {longest}")
        if size > TOPIC_MAX_BYTES:
            problems.append(f"{folder}/{topic.name} is {size} bytes, over {TOPIC_MAX_BYTES}")
        for number, line in enumerate(lines, 1):
            if len(line) > LINE_MAX_CHARS:
                problems.append(
                    f"{folder}/{topic.name}:{number} is {len(line)} characters, over {LINE_MAX_CHARS}"
                )
    for linked in re.findall(rf"\(({re.escape(Path(folder).name)}/[^)]+\.md)\)", "\n".join(index_lines)):
        if not (index_path.parent / linked).is_file():
            problems.append(f"{index} names {linked}, which does not exist")


def check_split(index: str, folder: str, ref: str, problems: list[str]) -> None:
    before_text = original(ref, index)
    before = collections.Counter(sentences(before_text))
    index_text = read(ROOT / index)
    in_index = collections.Counter(sentences(index_text))
    in_topics: collections.Counter[str] = collections.Counter()
    home: dict[str, list[str]] = collections.defaultdict(list)
    for topic in sorted((ROOT / folder).glob("*.md")):
        for sentence in sentences(read(topic)):
            in_topics[sentence] += 1
            home[sentence].append(topic.name)

    missing = doubled = 0
    for sentence, count in sorted(before.items()):
        now = in_topics[sentence] + in_index[sentence]
        if now < count:
            missing += 1
            problems.append(f"{index}: lost ({now} of {count}): {sentence[:120]}")
        elif now > count:
            doubled += 1
            problems.append(f"{index}: in {now} places, was in {count} ({home[sentence]}): {sentence[:120]}")
    added = sorted(s for s in in_topics if s not in before)
    for sentence in added:
        problems.append(f"{folder}/{home[sentence][0]}: not in the original: {sentence[:120]}")

    before_sorted = sorted(before.elements())
    kept_in_index = sorted(s for s in in_index.elements() if s in before)
    after_sorted = sorted(list(in_topics.elements()) + kept_in_index)
    print(
        f"{index} at {ref}: {len(before_sorted)} sentences; "
        f"now {sum(in_topics.values())} in {folder}/ and {len(kept_in_index)} kept in the index; "
        f"sorted lists {'identical' if before_sorted == after_sorted else 'DIFFER'} "
        f"({missing} lost, {doubled} doubled, {len(added)} added)"
    )

    unnamed = [h for h in headings(before_text)[1:] if h not in index_text]
    print(f"  headings of the original named in the index: {len(headings(before_text)) - 1 - len(unnamed)} of {len(headings(before_text)) - 1}")
    for heading in unnamed:
        problems.append(f"{index} does not name the original's section \"{heading}\"")


REFERENCE = re.compile(
    r"docs/(conventions|design-record)\.md`?,?\s+(?:its\s+)?(?:section\s+)?[\"“]([^\"”]+)[\"”]"
)
REFERENCE_REVERSED = re.compile(
    r"[\"“]([^\"”]+)[\"”] in `?docs/(conventions|design-record)\.md"
)


def section_references(text: str) -> list[tuple[str, str]]:
    found = [(m.group(1), m.group(2)) for m in REFERENCE.finditer(text)]
    found += [(m.group(2), m.group(1)) for m in REFERENCE_REVERSED.finditer(text)]
    return found


def check_references(issues: str | None, problems: list[str]) -> None:
    index_text = {
        "conventions": read(ROOT / "docs/conventions.md"),
        "design-record": read(ROOT / "docs/design-record.md"),
    }
    sources: list[tuple[str, str]] = []
    for pattern in REFERENCE_GLOBS:
        for path in sorted(ROOT.glob(pattern)):
            sources.append((path.relative_to(ROOT).as_posix(), read(path)))
    if issues:
        for issue in json.loads(Path(issues).read_text(encoding="utf-8")):
            sources.append((f"issue #{issue['number']}", issue["body"]))
    seen = set()
    resolved = 0
    for where, text in sources:
        for doc, section in section_references(text):
            if (where, doc, section) in seen:
                continue
            seen.add((where, doc, section))
            if section in index_text[doc]:
                resolved += 1
            else:
                problems.append(f"{where}: docs/{doc}.md \"{section}\" is not a section its index names")
    print(f"references by section: {resolved} of {len(seen)} resolve through an index")


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument("--against", metavar="REF", help="git ref holding the single-file originals")
    parser.add_argument("--issues", metavar="JSON", help="open issues, from gh issue list --json number,body")
    args = parser.parse_args()

    problems: list[str] = []
    for index, folder in DOC_SETS:
        check_limits(index, folder, problems)
    if args.against:
        for index, folder in DOC_SETS:
            if (ROOT / folder).is_dir():
                check_split(index, folder, args.against, problems)
    if not problems or all((ROOT / folder).is_dir() for _, folder in DOC_SETS):
        check_references(args.issues, problems)

    for problem in problems:
        print(f"FAIL {problem}")
    print("OK" if not problems else f"{len(problems)} problems")
    return 0 if not problems else 1


if __name__ == "__main__":
    sys.stdout.reconfigure(encoding="utf-8")
    sys.exit(main())
