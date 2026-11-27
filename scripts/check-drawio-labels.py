#!/usr/bin/env python3
"""Fail when a draw.io label shows escaped markup or entities as literal text.

A label that is escaped twice, for example `&amp;lt;br&amp;gt;` in the file, renders as a literal `<br>` while
exports and `assetkit check` still pass. This decodes each label the way draw.io does and reports:

- HTML labels (`html=1` in the style): an escaped HTML tag such as `&lt;br&gt;` (or `&#60;br&#62;`, `&#x3c;br&#x3e;`),
  or an escaped entity such as `&amp;nbsp;`, left in the label's HTML. Placeholders that are not HTML element names
  (`&lt;ws&gt;`) are fine; one that is (`<title>`) is flagged, so write it another way (`{title}`).
- Plain-text labels: an HTML entity such as `&lt;` or `&amp;`, which plain text shows as typed.

Only cell labels are checked (`value` on mxCell, `label` on object and UserObject), on plain and compressed pages.
Tooltips and object properties are not.

Usage:
  python3 scripts/check-drawio-labels.py                      # every .drawio file in the repo
  python3 scripts/check-drawio-labels.py forge                # .drawio files under forge/
  python3 scripts/check-drawio-labels.py path/to/file.drawio  # one file (any extension)

Without a file argument, files come from git (tracked plus new, not ignored), so it also works under .worktrees/.
Exit status: 0 when every label is clean, 1 when one is not, 2 on a usage error or a file it cannot read.
Needs only Python 3 and git.
"""

import base64
import html.entities
import re
import subprocess
import sys
import urllib.parse
import xml.etree.ElementTree as ET
import zlib
from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parent.parent

# Every HTML element, current and obsolete. Other names are not tags: labels show placeholders such as `<ws>` or
# `<id>` as text on purpose.
HTML_TAGS = (
    "a abbr acronym address applet area article aside audio b base basefont bdi bdo big blink blockquote body br "
    "button canvas caption center cite code col colgroup data datalist dd del details dfn dialog dir div dl dt em "
    "embed fieldset figcaption figure font footer form frame frameset h1 h2 h3 h4 h5 h6 head header hgroup hr html i "
    "iframe img input ins kbd label legend li link main map mark marquee math menu meta meter nav nobr noframes "
    "noscript object ol optgroup option output p picture pre progress q rp rt ruby s samp script search section "
    "select slot small source span strike strong style sub summary sup svg table tbody td template textarea tfoot th "
    "thead time title tr track tt u ul var video wbr xmp"
).split()
# `<`, `>` and `"` written as a named or numeric (decimal or hex) character reference.
LT = r"(?:&lt;|&#0*60;|&#[xX]0*3[cC];)"
GT = r"(?:&gt;|&#0*62;|&#[xX]0*3[eE];)"
QUOT = r"(?:&quot;|&#0*34;|&#[xX]0*22;)"
# Attributes need a value, so prose such as `&lt;b or c&gt;` is not read as a tag.
ATTRIBUTE = rf"""\s+[\w:-]+\s*=\s*(?:{QUOT}.*?{QUOT}|"[^"]*"|'[^']*'|[^\s&"'>]+)"""
ESCAPED_TAG = re.compile(
    rf"{LT}/?(?:{'|'.join(sorted(HTML_TAGS, key=len, reverse=True))})(?:{ATTRIBUTE})*\s*/?{GT}", re.IGNORECASE
)
ENTITY = r"&(?P<name>[A-Za-z][A-Za-z0-9]*|#[0-9]+|#[xX][0-9A-Fa-f]+);"
ESCAPED_ENTITY = re.compile(ENTITY.replace("&", "&amp;", 1))
TEXT_ENTITY = re.compile(ENTITY)


class UsageError(Exception):
    pass


def is_entity(match):
    name = match.group("name")
    return name.startswith("#") or f"{name};" in html.entities.html5


def label_problems(label, html_label):
    """Returns (message, match) pairs for one decoded label."""
    if html_label:
        found = [("escaped tag shows as text", m.group(0)) for m in ESCAPED_TAG.finditer(label)]
        found += [("escaped entity shows as text", m.group(0)) for m in ESCAPED_ENTITY.finditer(label) if is_entity(m)]
        return found
    return [("entity in a plain-text label shows as text", m.group(0))
            for m in TEXT_ENTITY.finditer(label) if is_entity(m)]


def is_html(style):
    return "html=1" in (style or "").split(";")


def page_model(diagram):
    """The page's mxGraphModel, decoding a compressed page."""
    model = diagram.find("mxGraphModel")
    if model is not None:
        return model
    data = (diagram.text or "").strip()
    if not data:
        return None
    xml = urllib.parse.unquote(zlib.decompress(base64.b64decode(data), -15).decode("utf-8"))
    return ET.fromstring(xml)


def labelled_cells(model):
    """Yields (cell id, label, style) for every cell with a label."""
    for el in model.iter():
        if el.tag == "mxCell" and el.get("value"):
            yield el.get("id", "?"), el.get("value"), el.get("style")
        elif el.tag in ("object", "UserObject") and el.get("label"):
            cell = el.find("mxCell")
            yield el.get("id", "?"), el.get("label"), cell.get("style") if cell is not None else None


def check_file(path):
    """Returns the report lines for one file."""
    root = ET.parse(path).getroot()
    diagrams = root.findall("diagram") if root.tag == "mxfile" else []
    pages = [(d.get("name", "?"), page_model(d)) for d in diagrams] or [("?", root)]
    lines = []
    for page, model in pages:
        if model is None:
            continue
        for cell_id, label, style in labelled_cells(model):
            for message, text in label_problems(label, is_html(style)):
                lines.append(f'{path}: page "{page}", cell {cell_id}: {message}: {text}')
    return lines


def repo_diagrams(scope):
    """Tracked and new (not ignored) .drawio files under scope, a directory relative to the repo root."""
    pathspec = f"{scope}/*.drawio" if scope else "*.drawio"
    try:
        out = subprocess.run(
            ["git", "-C", str(REPO_ROOT), "ls-files", "-z", "--cached", "--others", "--exclude-standard", "--",
             pathspec],
            check=True, capture_output=True, text=True,
        ).stdout
    except FileNotFoundError:
        raise UsageError("git not found; pass .drawio files directly")
    except subprocess.CalledProcessError as err:
        raise UsageError(f"git ls-files failed: {err.stderr.strip()}; run inside a git checkout of assets, "
                         "or pass .drawio files directly")
    paths = sorted({REPO_ROOT / p for p in out.split("\0") if p})
    return [p for p in paths if p.is_file()]


def files_to_check(args):
    if not args:
        return repo_diagrams("")
    files = []
    for arg in args:
        path = Path(arg)
        if path.is_file():
            files.append(path)
        elif path.is_dir():
            try:
                scope = path.resolve().relative_to(REPO_ROOT).as_posix()
            except ValueError:
                raise UsageError(f"{arg}: not inside the assets repo ({REPO_ROOT})")
            found = repo_diagrams("" if scope == "." else scope)
            if not found:
                print(f"{arg}: no .drawio files", file=sys.stderr)
            files += found
        else:
            raise UsageError(f"{arg}: no such file or directory")
    return files


def main(args):
    sys.stdout.reconfigure(errors="backslashreplace")
    try:
        files = files_to_check(args)
    except UsageError as err:
        print(f"check-drawio-labels: {err}", file=sys.stderr)
        return 2
    problems, unreadable = [], 0
    for path in files:
        try:
            problems += check_file(path)
        except (ET.ParseError, ValueError, zlib.error, OSError) as err:
            print(f"{path}: cannot read: {err}", file=sys.stderr)
            unreadable += 1
    for line in problems:
        print(line)
    print(f"{len(files)} file(s) checked, {len(problems)} label problem(s)", file=sys.stderr)
    if unreadable:
        return 2
    return 1 if problems else 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
