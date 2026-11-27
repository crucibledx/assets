#!/usr/bin/env python3
"""Tests for scripts/check-drawio-labels.py against the fixtures in scripts/fixtures/drawio-labels/."""

import importlib.util
import shutil
import subprocess
import sys
import tempfile
from pathlib import Path

HERE = Path(__file__).resolve().parent
REPO_ROOT = HERE.parent
CHECK = HERE / "check-drawio-labels.py"
FIXTURES = HERE / "fixtures" / "drawio-labels"
failures = 0


def run(*args, cwd=REPO_ROOT, script=CHECK):
    proc = subprocess.run([sys.executable, str(script), *map(str, args)], capture_output=True, text=True, cwd=cwd)
    return proc.returncode, proc.stdout.splitlines(), proc.stderr


def checked(err):
    """The file count from the summary line."""
    return int(err.strip().splitlines()[-1].split()[0])


def check(name, ok):
    global failures
    print(("ok   " if ok else "FAIL ") + name)
    failures += not ok


code, out, _ = run(FIXTURES / "clean.drawio.xml")
check("clean labels pass: <br> (named and numeric), <kbd>, <wbr>, &nbsp;, &#10004;, &amp;, <ws> placeholders, "
      "prose with <, Q&A;, UserObject, "
      "compressed page", code == 0 and out == [])

bad = FIXTURES / "double-escaped.drawio.xml"
code, out, _ = run(bad)
expected = [
    f'{bad}: page "Bad", cell br: escaped tag shows as text: &lt;br&gt;',
    f'{bad}: page "Bad", cell entity: escaped entity shows as text: &amp;nbsp;',
    f'{bad}: page "Bad", cell plain: entity in a plain-text label shows as text: &lt;',
    f'{bad}: page "Bad", cell span: escaped tag shows as text: &lt;span style=&quot;color:red&quot;&gt;',
    f'{bad}: page "Bad", cell span: escaped tag shows as text: &lt;/span&gt;',
    f'{bad}: page "Bad", cell decimal: escaped tag shows as text: &#60;br&#62;',
    f'{bad}: page "Bad", cell hex: escaped tag shows as text: &#x3c;wbr&#x3E;',
    f'{bad}: page "Bad", cell kbd: escaped tag shows as text: &lt;kbd&gt;',
    f'{bad}: page "Bad", cell kbd: escaped tag shows as text: &lt;/kbd&gt;',
    f'{bad}: page "Bad", cell link: escaped tag shows as text: &lt;b&gt;',
    f'{bad}: page "Bad", cell link: escaped tag shows as text: &lt;/b&gt;',
    f'{bad}: page "Compressed", cell z1: escaped tag shows as text: &lt;br&gt;',
]
check("double-escaped labels fail with one line per problem (HTML, numeric escapes, any HTML element, "
      "attributes, plain, UserObject, compressed)",
      code == 1 and out == expected)

# Every element in MDN's HTML elements reference, current and obsolete, kept separately from the script's own list.
MDN_ELEMENTS = """
a abbr address area article aside audio b base bdi bdo blockquote body br button canvas caption cite code col colgroup
data datalist dd del details dfn dialog div dl dt em embed fencedframe fieldset figcaption figure footer form h1 h2 h3
h4 h5 h6 head header hgroup hr html i iframe img input ins kbd label legend li link main map mark math menu meta meter
nav noscript object ol optgroup option output p picture pre progress q rp rt ruby s samp script search section select
selectedcontent slot small source span strong style sub summary sup svg table tbody td template textarea tfoot th
thead time title tr track u ul var video wbr acronym big center content dir font frame frameset image marquee menuitem
nobr noembed noframes param plaintext rb rtc shadow strike tt xmp
""".split()
spec = importlib.util.spec_from_file_location("check_drawio_labels", CHECK)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
missed = [name for name in MDN_ELEMENTS
          if module.label_problems(f"x&lt;{name}&gt;y&lt;/{name}&gt;", True) != [
              ("escaped tag shows as text", f"&lt;{name}&gt;"), ("escaped tag shows as text", f"&lt;/{name}&gt;")]]
check(f"every MDN HTML element is caught when escaped (missed: {missed})", missed == [])
placeholders = [p for p in ("ws", "id", "ids", "scope", "hex", "pid", "name", "harness")
                if module.label_problems(f"&lt;{p}&gt;", True)]
check(f"placeholders used in the diagrams are not tags (flagged: {placeholders})", placeholders == [])

code, out, _ = run(FIXTURES / "clean.drawio.xml", bad)
check("several files: any problem fails the run", code == 1 and out == expected)

code, out, err = run()
check("default run: every diagram in the repo passes", code == 0 and out == [] and checked(err) > 0)

code, out, err = run("forge")
check("a directory checks its .drawio files", code == 0 and checked(err) > 0)

code, _, err_root = run("crucible/diagrams")
code_sub, _, err_sub = run("diagrams", cwd=REPO_ROOT / "crucible")
check("a directory is relative to the current directory",
      code == code_sub == 0 and checked(err_sub) == checked(err_root) > 0)

code, out, err = run("scripts")
check("fixtures (.drawio.xml) are not picked up from a directory", code == 0 and checked(err) == 0)

with tempfile.TemporaryDirectory() as tmp:
    tmp = Path(tmp)
    broken = tmp / "broken.drawio"
    broken.write_text("<mxfile><diagram>")
    code, out, err = run(broken)
    check("a file that is not XML exits 2 and says so", code == 2 and "cannot read" in err)

    code, _, err = run(tmp)
    check("a directory outside the repo exits 2 without a traceback",
          code == 2 and "not inside the assets repo" in err and "Traceback" not in err)

    repo = tmp / "repo"
    (repo / "scripts").mkdir(parents=True)
    shutil.copy(CHECK, repo / "scripts")
    script = repo / "scripts" / CHECK.name
    code, _, err = run(script=script, cwd=repo)
    check("outside a git checkout: exits 2 with a hint, no traceback",
          code == 2 and "git checkout" in err and "Traceback" not in err)

    subprocess.run(["git", "init", "-q", str(repo)], check=True)
    shutil.copy(bad, repo / "new.drawio")
    shutil.copy(FIXTURES / "clean.drawio.xml", repo / "gone.drawio")
    subprocess.run(["git", "-C", str(repo), "add", "gone.drawio"], check=True)
    (repo / "gone.drawio").unlink()
    code, out, err = run(script=script, cwd=repo)
    check("a new, unstaged diagram is checked and a deleted tracked one is skipped",
          code == 1 and len(out) == len(expected) and checked(err) == 1 and "cannot read" not in err)

code, _, err = run(FIXTURES / "missing.drawio")
check("a missing path exits 2", code == 2 and "no such file" in err)

sys.exit(1 if failures else 0)
