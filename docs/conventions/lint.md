# The lint

`python tools/lint/lint.py` checks every script of ours and every file's line endings, without Godot, in a few seconds (ticket #79).
Exit 0 is clean, 1 a finding (each printed as `path:line: what`), 2 a missing or wrong gdtoolkit.
`python tools/lint/lint.py <file>...` checks only the files named.

## What it checks

- Every `.gd` under `sim/`, `view/`, `test/` and `tools/`, tracked or new and not ignored; `addons/` is not ours and is left out.
- gdlint, from gdtoolkit at the version pinned in `tools/lint/requirements.txt`, with the settings in `.gdlintrc` at the repo root; each setting there says why it differs from gdlint's default.
- Lines up to 170 columns, a tab counting four: the longest lines are one-line lambdas in tests, kept on one line on purpose (`running-and-testing.md`, Testing).
- No tab after the start of a line (`stray-tab`): a shell heredoc that eats a backslash continuation joins the two lines and keeps the second one's tabs, so the code still parses and only this catches it.
- No CRLF in any tracked or new text file; `.gitattributes` keeps text LF in the repository and the working tree, the `.cmd` and `.bat` files CRLF in the working tree only.
  A file saved with CRLF is fixed by saving it with LF, or by `git add --renormalize <file>` and checking it out again.

## What it does not check

- Formatting: `gdformat` is not used.
  Its one style (each argument on its own line, conditions in brackets) is not how the code is written, and `gdformat --check` would rewrite 98 of the 123 scripts; it has no setting for the Godot style guide's double-indented continuations used here.
- Types, names that do not resolve, and anything else only Godot's parser knows; the suite's parse of every script still catches those (exit 105).
- gdtoolkit 4.5.0 cannot parse two things Godot 4.7 accepts, so neither is written here: a plain `"` string spanning lines (use `"""`), and a one-line lambda whose body is an `if` (give it its own lines).
  A file gdlint cannot parse is a finding, printed with the line and column it stopped at.

## Installing

- Once: `python -m pip install -r tools/lint/requirements.txt`; on Linux, as in CI, the same.
- The developer's PC: its `python` is 3.11.0a7, an alpha whose PyYAML crashes gdlint (`gdlint itself failed (exit 3221225477)`).
  Use the released Python 3.12 there, for the install and for the run: `C:/Users/Scott/AppData/Local/Programs/Python/Python312/python.exe tools/lint/lint.py`.
- A new gdtoolkit is taken by changing the pin and running the lint over the whole tree; the lint refuses any other installed version, so everyone checks alike.
