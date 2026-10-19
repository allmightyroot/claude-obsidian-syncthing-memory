#!/usr/bin/env python3
"""Formatting lint for a markdown memory vault.

Usage: python3 -I vault-lint.py [--fix] [PATH ...]

PATH may be files or directories (default: the memory/ folder next to this
script's parent directory, so copy it to <vault>/scripts/). Exits 1 if any
issue is found (after fixing, if --fix).

Rules (the same ones templates/vault-conventions.md asks for):
  hard-wrap    paragraph or bullet continued on a following line instead of
               one long line (renders as stair-stepping in narrow panes)
  loose-list   blank line between two bullets of the same list
  trailing-ws  trailing whitespace
  frontmatter  note missing a leading --- frontmatter block
  tabs         tab characters outside code fences
  index-size   memory/index.md over 6000 bytes (the SessionStart hook output is
               capped at ~10K chars; past that a session sees only a short preview)

--fix repairs hard-wrap, loose-list and trailing-ws. Frontmatter, tabs and
index-size are reported only. Code fences, tables, HTML comments, frontmatter,
block quotes, and nested/indented list items are never touched.
"""
import re
import sys
from pathlib import Path

LIST_RE = re.compile(r'^(\s*)([-*+]|\d+[.)])\s')
INDEX_MAX_BYTES = 6000
SKIP_DIRS = {'.git', '.obsidian', '.trash', 'node_modules'}


def structural(line):
    """True if the line starts its own block (not a paragraph continuation)."""
    s = line.lstrip()
    return (not s or LIST_RE.match(line) or s.startswith(('#', '|', '>', '```', '~~~', '<!--', '---', '===', '[^'))
            or re.match(r'^\[[^\]]+\]:\s', s))


def scan(text, fix):
    """Return (issues, fixed_text). Issues are (lineno, rule, message)."""
    lines = text.split('\n')
    issues = []
    out = []
    in_fence = in_comment = in_fm = False
    # kinds of the last emitted line: 'para' (joinable), 'bullet' (top-level, joinable), None
    prev_kind = None
    prev_blank_after_bullet = False
    in_bullet = False

    if not (lines and lines[0] == '---'):
        issues.append((1, 'frontmatter', 'missing leading --- frontmatter block'))

    for n, line in enumerate(lines, 1):
        # --- protected regions -------------------------------------------
        if n == 1 and line == '---':
            in_fm = True
            out.append(line); prev_kind = None
            continue
        if in_fm:
            out.append(line)
            if line == '---':
                in_fm = False
            prev_kind = None
            continue
        if line.lstrip().startswith(('```', '~~~')):
            in_fence = not in_fence
            out.append(line); prev_kind = None
            continue
        if in_fence:
            out.append(line); prev_kind = None
            continue
        if in_comment or '<!--' in line:
            in_comment = '-->' not in line
            out.append(line); prev_kind = None
            continue

        # --- per-line checks ---------------------------------------------
        if '\t' in line:
            issues.append((n, 'tabs', 'tab character'))
        if line != line.rstrip():
            issues.append((n, 'trailing-ws', 'trailing whitespace'))
            line = line.rstrip()

        m = LIST_RE.match(line)
        top_bullet = bool(m) and m.group(1) == ''

        # loose list: blank line between two top-level bullets
        if top_bullet and prev_blank_after_bullet and out and out[-1] == '':
            issues.append((n - 1, 'loose-list', 'blank line between bullets'))
            if fix:
                out.pop()
        prev_blank_after_bullet = False

        # hard-wrap: plain continuation of the previous paragraph/bullet
        if line.strip() and not structural(line) and prev_kind in ('para', 'bullet'):
            issues.append((n, 'hard-wrap', 'continuation line (should be joined to previous line)'))
            if fix:
                # word-hyphen ("business-" + "confidential") joins with no space;
                # a spaced dash (" -") still gets one
                sep = '' if re.search(r'\w-$', out[-1].rstrip()) else ' '
                out[-1] = out[-1].rstrip() + sep + line.strip()
                continue

        out.append(line)
        if not line.strip():
            prev_kind = None
            prev_blank_after_bullet = in_bullet
        else:
            if top_bullet:
                in_bullet = True
            elif not line.startswith((' ', '\t')):
                in_bullet = False
            if top_bullet:
                prev_kind = 'bullet'
            elif m or structural(line):   # nested list item / heading / table: leave alone
                prev_kind = None
            else:
                prev_kind = 'para'

    return issues, '\n'.join(out)


def files_under(paths):
    for p in paths:
        p = Path(p)
        if p.is_dir():
            for f in sorted(p.rglob('*.md')):
                if not SKIP_DIRS & set(f.parts):
                    yield f
        elif p.suffix == '.md':
            yield p


def main(argv):
    fix = '--fix' in argv
    args = [a for a in argv if a != '--fix']
    root = Path(__file__).resolve().parent.parent
    paths = args or [root / 'memory']
    total = 0
    for f in files_under(paths):
        text = f.read_text(encoding='utf-8')
        issues, fixed = scan(text, fix)
        while fix and fixed != text and scan(fixed, True)[1] != fixed:   # repeat until stable
            fixed = scan(fixed, True)[1]
        if fix and fixed != text:
            f.write_text(fixed, encoding='utf-8')
        # after --fix, rescan so only unfixable issues are reported
        if fix:
            issues, _ = scan(fixed, False)
        if f.name == 'index.md' and f.parent.name == 'memory':
            size = len(f.read_bytes())
            if size > INDEX_MAX_BYTES:
                issues.append((1, 'index-size', f'{size} bytes, over the {INDEX_MAX_BYTES}-byte budget'))
        for n, rule, msg in issues:
            print(f'{f}:{n}: {rule}: {msg}')
        total += len(issues)
    print(f'{total} issue(s)' + (' remaining after fix' if fix else ''), file=sys.stderr)
    return 1 if total else 0


if __name__ == '__main__':
    sys.exit(main(sys.argv[1:]))
