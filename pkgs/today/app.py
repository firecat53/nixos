"""Today — quick-entry companion for the Gollum-rendered wiki."""

import fcntl
import os
import re
from contextlib import contextmanager
from datetime import date
from pathlib import Path

from flask import Flask, redirect, render_template, request, send_from_directory, url_for

WIKI_DIR = Path(os.environ.get("WIKI_DIR", str(Path.home() / "docs/family/scott/wiki")))
PORT = int(os.environ.get("PORT", "4568"))

app = Flask(__name__)


@contextmanager
def locked(path: Path, mode: str):
    path.parent.mkdir(parents=True, exist_ok=True)
    if mode.startswith("r") and not path.exists():
        path.write_text("")
    with open(path, mode) as f:
        fcntl.flock(f.fileno(), fcntl.LOCK_EX)
        try:
            yield f
        finally:
            fcntl.flock(f.fileno(), fcntl.LOCK_UN)


def diary_path(d: date) -> Path:
    return WIKI_DIR / "diary" / f"{d.year}" / f"{d.isoformat()}.md"


def gollum_base() -> str:
    """Return the Gollum URL whose 'lan' status matches this request's host.

    today.lan.firecat53.net -> https://gollum.lan.firecat53.net
    today.firecat53.me      -> https://gollum.firecat53.me
    Anything else (local dev) falls back to the .lan URL.
    """
    host = request.host.split(":")[0]
    if host.startswith("today."):
        return f"https://gollum.{host[len('today.'):]}"
    return "https://gollum.lan.firecat53.net"


# --- Books.md parsing ---------------------------------------------------------

SECTION_RE = re.compile(r"^##\s+(.+?)\s*$")
TABLE_ROW_RE = re.compile(r"^\|(.*)\|\s*$")


def split_row(line: str) -> list[str]:
    inner = line.strip()
    assert inner.startswith("|") and inner.endswith("|")
    return [c.strip() for c in inner[1:-1].split("|")]


def is_separator(line: str) -> bool:
    return bool(re.match(r"^\|[\s\-:|]+\|\s*$", line))


def find_book_tables(lines: list[str]) -> dict[str, dict]:
    """Return {section_name: {"header_idx": int, "rows": [(line_idx, cells)]}}."""
    out: dict[str, dict] = {}
    current_section: str | None = None
    i = 0
    while i < len(lines):
        m = SECTION_RE.match(lines[i])
        if m:
            current_section = m.group(1).strip()
            i += 1
            continue
        if current_section in ("Audiobooks", "Books") and TABLE_ROW_RE.match(lines[i]):
            header_idx = i
            if i + 1 < len(lines) and is_separator(lines[i + 1]):
                rows = []
                j = i + 2
                while j < len(lines) and TABLE_ROW_RE.match(lines[j]):
                    rows.append((j, split_row(lines[j])))
                    j += 1
                out[current_section] = {"header_idx": header_idx, "rows": rows}
                i = j
                # only the first table after each heading
                current_section = None
                continue
        i += 1
    return out


def incomplete_books() -> list[dict]:
    path = WIKI_DIR / "Books.md"
    if not path.exists():
        return []
    text = path.read_text()
    lines = text.splitlines()
    tables = find_book_tables(lines)
    items = []
    for section in ("Audiobooks", "Books"):
        t = tables.get(section)
        if not t:
            continue
        headers = split_row(lines[t["header_idx"]])
        for idx, (_line_idx, cells) in enumerate(t["rows"]):
            row = dict(zip(headers, cells))
            if not row.get("Date", "").strip():
                items.append(
                    {
                        "section": section,
                        "row": idx,
                        "author": row.get("Author", ""),
                        "title": row.get("Title", ""),
                        "series": row.get("Series", ""),
                    }
                )
    return items


# --- WorkoutLog.md insertion --------------------------------------------------

WORKOUT_HEADER = "|            | Time | Exercises                          | Intensity     |"
WORKOUT_SEP    = "|------------|------|------------------------------------|---------------|"


def format_workout_row(d: date, time: str, exercises: str, intensity: str) -> str:
    return f"| {d.isoformat()} | {time:<4} | {exercises:<34} | {intensity:<13} |"


def insert_workout(text: str, d: date, time: str, exercises: str, intensity: str) -> str:
    row = format_workout_row(d, time, exercises, intensity)
    lines = text.splitlines()
    today_ym = d.strftime("%Y-%m")

    # Locate the top-most table and check whether its newest row is this month
    for i, line in enumerate(lines):
        if TABLE_ROW_RE.match(line) and i + 1 < len(lines) and is_separator(lines[i + 1]):
            header_idx = i
            first_data_idx = i + 2
            same_month = False
            if first_data_idx < len(lines) and TABLE_ROW_RE.match(lines[first_data_idx]):
                first_cells = split_row(lines[first_data_idx])
                if first_cells and first_cells[0].startswith(today_ym):
                    same_month = True
            if same_month:
                out = lines[: first_data_idx] + [row] + lines[first_data_idx:]
                return "\n".join(out) + ("\n" if text.endswith("\n") else "")
            # New month: prepend a fresh table above this one
            new_block = [WORKOUT_HEADER, WORKOUT_SEP, row, ""]
            out = lines[:header_idx] + new_block + lines[header_idx:]
            return "\n".join(out) + ("\n" if text.endswith("\n") else "")

    # No existing table — create one at the top
    new_block = [WORKOUT_HEADER, WORKOUT_SEP, row, ""]
    return "\n".join(new_block + lines) + ("\n" if text.endswith("\n") else "")


# --- Routes -------------------------------------------------------------------

@app.route("/sw.js")
def service_worker():
    # Serve from root so the SW scope is "/" and covers start_url.
    resp = send_from_directory(app.static_folder, "sw.js", mimetype="application/javascript")
    resp.headers["Service-Worker-Allowed"] = "/"
    resp.headers["Cache-Control"] = "no-cache"
    return resp


@app.route("/manifest.webmanifest")
def manifest():
    return send_from_directory(
        app.static_folder, "manifest.webmanifest", mimetype="application/manifest+json"
    )


@app.route("/")
def index():
    today = date.today()
    dp = diary_path(today)
    diary_text = dp.read_text() if dp.exists() else ""
    rel = f"diary/{today.year}/{today.isoformat()}"
    return render_template(
        "index.html",
        today=today,
        day_label=today.strftime("%a %b %d %Y"),
        gollum_base=gollum_base(),
        diary_relpath=rel,
        diary_text=diary_text,
        books=incomplete_books(),
    )


@app.post("/diary")
def post_diary():
    entry = (request.form.get("entry") or "").strip()
    if not entry:
        return redirect(url_for("index"))
    path = diary_path(date.today())
    with locked(path, "r+") as f:
        existing = f.read()
        if existing and not existing.endswith("\n"):
            existing += "\n"
        # Normalize entry: collapse internal CRLF, strip trailing whitespace
        entry_norm = "\n".join(line.rstrip() for line in entry.replace("\r\n", "\n").splitlines())
        f.seek(0)
        f.truncate()
        f.write(existing + f"* {entry_norm}\n")
    return redirect(url_for("index"))


@app.post("/workout")
def post_workout():
    time = (request.form.get("time") or "").strip()
    exercises = (request.form.get("exercises") or "").strip()
    intensity = (request.form.get("intensity") or "").strip()
    if not (time and exercises and intensity):
        return redirect(url_for("index"))
    path = WIKI_DIR / "workouts" / "WorkoutLog.md"
    with locked(path, "r+") as f:
        text = f.read()
        new_text = insert_workout(text, date.today(), time, exercises, intensity)
        f.seek(0)
        f.truncate()
        f.write(new_text)
    return redirect(url_for("index"))


@app.post("/book")
def post_book():
    section = request.form.get("section", "")
    try:
        row_idx = int(request.form.get("row", ""))
    except ValueError:
        return redirect(url_for("index"))
    if section not in ("Audiobooks", "Books"):
        return redirect(url_for("index"))

    path = WIKI_DIR / "Books.md"
    today = date.today()
    stamp = today.strftime("%Y-%m")
    with locked(path, "r+") as f:
        text = f.read()
        lines = text.splitlines()
        tables = find_book_tables(lines)
        t = tables.get(section)
        if t and 0 <= row_idx < len(t["rows"]):
            line_idx, cells = t["rows"][row_idx]
            headers = split_row(lines[t["header_idx"]])
            # Determine the column widths used in this table's header row
            raw_header = lines[t["header_idx"]]
            # Re-split keeping widths
            parts = raw_header.strip()[1:-1].split("|")
            widths = [len(p) for p in parts]
            # Update Date cell
            try:
                date_col = headers.index("Date")
            except ValueError:
                date_col = len(headers) - 1
            cells[date_col] = stamp
            new_parts = [f" {c.ljust(widths[i] - 2)} " if i < len(widths) else f" {c} " for i, c in enumerate(cells)]
            lines[line_idx] = "|" + "|".join(new_parts) + "|"
            new_text = "\n".join(lines) + ("\n" if text.endswith("\n") else "")
            f.seek(0)
            f.truncate()
            f.write(new_text)
    return redirect(url_for("index"))


if __name__ == "__main__":
    app.run(host="127.0.0.1", port=PORT)
