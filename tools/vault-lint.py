#!/usr/bin/env python3
"""Formatting lint for the claudebrain vaults (markdown notes).

Usage: vault-lint.py [--fix] [PATH ...]
       vault-lint.py --health [--strict] [ROOT]

PATH may be files or directories (default: memory/, reflections/ and handoff/
next to this script's parent; a default directory that doesn't exist is
skipped). Exits 1 if any issue is found (after fixing, if --fix).

Rules (see [[conventions]] / [[vault-formatting]]):
  hard-wrap    paragraph or bullet continued on a following line instead of
               one long line (renders as stair-stepping in narrow panes)
  loose-list   blank line between two bullets of the same list
  trailing-ws  trailing whitespace
  frontmatter  note missing a leading --- frontmatter block
  tabs         tab characters outside code fences
  index-size   memory/index.md over 6000 bytes (the SessionStart hook output is
               capped at ~10K chars; see "Index size budget" in [[vault-formatting]])

--fix repairs hard-wrap, loose-list and trailing-ws. Frontmatter (not required
for Claude Code's MEMORY.md indexes), tabs and index-size are reported only.
Code fences, tables, HTML comments, frontmatter, block quotes, and
nested/indented list items are never touched.

--health is a separate, report-only vault audit (--fix is ignored). It scans every
note under the vault root (or ROOT) and reports:
  broken-link  [[wikilink]] matching no filename stem, frontmatter name: or
               aliases: entry anywhere in the vault (code is skipped)
  unindexed    memory/*.md or handoff/*.md not reachable from memory/index.md
               (linked from the index, or from a note the index links: hub notes)
  index-size   as above
  large-note   note over 12000 bytes (split candidate)
  stale        frontmatter updated: more than 180 days old
  stale-project-note  claude-projects/*/memory/*.md with no git commit touching
               it in over 180 days (file mtime if the vault isn't a git repo or the
               file is untracked); these notes have no updated: frontmatter
  sync-conflict  any *.sync-conflict-* file
A note can suppress health rules for itself with frontmatter `lint-skip: [large-note]`
(any of large-note, stale, stale-project-note, unindexed); use it for accepted-as-is notes.
Pointer stubs (body under ~300 bytes containing a [[link]]) are exempt from
unindexed, stale and stale-project-note: they only exist so old links resolve.
It exits 0 even with findings unless --strict is given, so a timer can log it.
"""
import datetime
import re
import subprocess
import sys
import time
from pathlib import Path

LIST_RE = re.compile(r'^(\s*)([-*+]|\d+[.)])\s')
INDEX_MAX_BYTES = 6000
LARGE_NOTE_BYTES = 12000
STALE_DAYS = 180
STUB_MAX_BYTES = 300
WIKILINK_RE = re.compile(r'\[\[([^\]\n]+?)\]\]')
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


def frontmatter(text):
    """Return (dict of name/updated/aliases, body line offset) from a leading --- block."""
    lines = text.split('\n')
    meta = {'aliases': [], 'lint-skip': []}
    if not lines or lines[0] != '---':
        return meta, 0
    key = None
    for i, line in enumerate(lines[1:], 1):
        if line == '---':
            return meta, i + 1
        m = re.match(r'^([\w-]+):\s*(.*)$', line)
        if m:
            key, val = m.group(1), m.group(2).strip().strip('\'"')
            if key in ('name', 'updated'):
                meta[key] = val
            elif key in ('aliases', 'alias', 'lint-skip'):
                key = 'aliases' if key == 'alias' else key
                if val.startswith('['):
                    meta[key] += [a.strip().strip('\'"') for a in val.strip('[]').split(',') if a.strip()]
                elif val:
                    meta[key].append(val)
        elif key in ('aliases', 'lint-skip') and re.match(r'^\s*-\s+', line):
            meta[key].append(re.sub(r'^\s*-\s+', '', line).strip().strip('\'"'))
    return meta, 0


def wikilinks(text, start=0):
    """Yield (lineno, target) for [[links]] outside code fences and inline code."""
    in_fence = False
    for n, line in enumerate(text.split('\n'), 1):
        if line.lstrip().startswith(('```', '~~~')):
            in_fence = not in_fence
            continue
        if in_fence:
            continue
        line = re.sub(r'`[^`]*`', '', line)
        for m in WIKILINK_RE.finditer(line):
            target = re.split(r'[|#^]', m.group(1), maxsplit=1)[0].strip()
            if target:
                yield n, target


def is_stub(text, body_start):
    """A pointer stub: a tiny body that links somewhere else."""
    body = '\n'.join(text.split('\n')[body_start:]).strip()
    return len(body.encode('utf-8')) < STUB_MAX_BYTES and bool(WIKILINK_RE.search(body))


def last_change(root, f):
    """Epoch seconds of the last git commit touching f, else its mtime."""
    if (root / '.git').exists():
        try:
            out = subprocess.run(['git', '-C', str(root), 'log', '-1', '--format=%ct', '--', str(f.relative_to(root))],
                                 capture_output=True, text=True, timeout=30).stdout.strip()
            if out:
                return int(out)
        except (OSError, ValueError, subprocess.SubprocessError):
            pass
    return f.stat().st_mtime


def norm(target):
    """Normalise a link target or note name for matching (case-insensitive, no .md, no folders)."""
    t = target.replace('\\', '/').rstrip('/').split('/')[-1]
    return (t[:-3] if t.lower().endswith('.md') else t).lower()


def health(root):
    """Return a list of (path, lineno, rule, message) for the vault at root."""
    notes = [f for f in sorted(root.rglob('*.md')) if not SKIP_DIRS & set(f.relative_to(root).parts)]
    findings = []
    texts, names = {}, set()
    for f in notes:
        text = f.read_text(encoding='utf-8')
        meta, _ = frontmatter(text)
        texts[f] = (text, meta)
        meta['stub'] = is_stub(text, frontmatter(text)[1])
        names.add(f.stem.lower())
        names.update(norm(x) for x in [meta.get('name', '')] + meta['aliases'] if x)
    # attachments (![[img.png]]) resolve by full filename
    for f in root.rglob('*'):
        if f.is_file() and f.suffix != '.md' and not SKIP_DIRS & set(f.relative_to(root).parts):
            names.add(f.name.lower())

    links = {}   # note -> set of normalised targets
    for f, (text, meta) in texts.items():
        links[f] = set()
        for n, target in wikilinks(text):
            links[f].add(norm(target))
            if norm(target) not in names and target.lower() not in names:
                findings.append((f, n, 'broken-link', f'[[{target}]] matches no note, name: or alias'))

    # reachability from memory/index.md: its links plus those notes' links, one level
    index = root / 'memory' / 'index.md'
    if index in texts:
        owners = {}   # normalised name -> notes it identifies
        for f, (text, meta) in texts.items():
            for nm in [f.stem] + [meta.get('name', '')] + meta['aliases']:
                if nm:
                    owners.setdefault(norm(nm), set()).add(f)
        direct = links[index]
        reach = set(direct)
        for t in direct:
            for f in owners.get(t, ()):
                reach |= links.get(f, set())
        for sub in ('memory', 'handoff'):
            for f in sorted((root / sub).glob('*.md')) if (root / sub).is_dir() else []:
                ids = {norm(x) for x in [f.stem, texts[f][1].get('name', '')] + texts[f][1]['aliases'] if x}
                if f != index and '.sync-conflict-' not in f.name and not texts[f][1]['stub'] and 'unindexed' not in texts[f][1]['lint-skip'] and not ids & reach:
                    findings.append((f, 1, 'unindexed', 'not reachable from memory/index.md'))
        size = index.stat().st_size
        if size > INDEX_MAX_BYTES:
            findings.append((index, 1, 'index-size', f'{size} bytes, over the {INDEX_MAX_BYTES}-byte budget'))

    today = datetime.date.today()
    for f, (text, meta) in texts.items():
        size = len(text.encode('utf-8'))
        if size > LARGE_NOTE_BYTES and 'large-note' not in meta['lint-skip']:
            findings.append((f, 1, 'large-note', f'{size} bytes, over {LARGE_NOTE_BYTES} (split candidate?)'))
        if 'updated' in meta and not meta['stub'] and 'stale' not in meta['lint-skip']:
            try:
                age = (today - datetime.date.fromisoformat(meta['updated'])).days
            except ValueError:
                findings.append((f, 1, 'stale', f'unparseable updated: {meta["updated"]!r}'))
            else:
                if age > STALE_DAYS:
                    findings.append((f, 1, 'stale', f'updated: {meta["updated"]} is {age} days old'))
    for f in sorted(root.glob('claude-projects/*/memory/*.md')):
        if f in texts and not texts[f][1]['stub'] and 'stale-project-note' not in texts[f][1]['lint-skip']:
            age = int((time.time() - last_change(root, f)) / 86400)
            if age > STALE_DAYS:
                findings.append((f, 1, 'stale-project-note', f'no change in {age} days'))
    for f in sorted(root.rglob('*.sync-conflict-*')):
        if not SKIP_DIRS & set(f.relative_to(root).parts):
            findings.append((f, 1, 'sync-conflict', 'Syncthing conflict copy'))
    return findings


def main(argv):
    flags = {'--fix', '--health', '--strict'}
    fix = '--fix' in argv
    args = [a for a in argv if a not in flags]
    root = Path(__file__).resolve().parent.parent
    if '--health' in argv:
        if args:
            root = Path(args[0]).resolve()
        findings = health(root)
        for f, n, rule, msg in findings:
            print(f'{f.relative_to(root)}:{n}: {rule}: {msg}')
        print(f'{len(findings)} health finding(s)', file=sys.stderr)
        return 1 if findings and '--strict' in argv else 0
    paths = args or [d for d in (root / 'memory', root / 'reflections', root / 'handoff') if d.is_dir()]
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
        if f.name == 'MEMORY.md':   # Claude Code project index: no frontmatter by design
            issues = [i for i in issues if i[1] != 'frontmatter']
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
