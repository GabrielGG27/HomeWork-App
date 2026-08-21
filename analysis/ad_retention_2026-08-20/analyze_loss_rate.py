from __future__ import annotations

import csv
import hashlib
import json
import sqlite3
import statistics
from collections import deque
from datetime import date, datetime
from pathlib import Path


ROOT = Path(__file__).resolve().parent
SOURCE = ROOT / "play_console_user_loss_rate.csv"
RESULTS = ROOT / "analysis_results.json"
DAILY_OUTPUT = ROOT / "daily_series.csv"
SQLITE_OUTPUT = ROOT / "loss_rate_analysis.sqlite"


def parse_date(value: str) -> date:
    return datetime.strptime(value, "%b %d, %Y").date()


def phase_for(day: date) -> str:
    if day <= date(2026, 6, 29):
        return "Pre real ads"
    if day <= date(2026, 7, 3):
        return "Transition"
    if day <= date(2026, 7, 15):
        return "July spike"
    if day <= date(2026, 7, 31):
        return "July decline"
    return "August"


def summarize(values: list[float]) -> dict[str, float | int]:
    return {
        "observed_days": len(values),
        "mean_percent": round(statistics.fmean(values), 4),
        "median_percent": round(statistics.median(values), 4),
        "minimum_percent": round(min(values), 4),
        "maximum_percent": round(max(values), 4),
        "days_above_5_percent": sum(value > 5 for value in values),
        "share_days_above_5_percent": round(
            sum(value > 5 for value in values) / len(values), 4
        ),
    }


rows: list[dict[str, object]] = []
with SOURCE.open(encoding="utf-8-sig", newline="") as handle:
    reader = csv.DictReader(handle)
    rate_column = "User loss rate (Daily): All countries / regions"
    for source_row in reader:
        raw_rate = source_row[rate_column]
        parsed_rate = None if raw_rate == "-" else float(raw_rate.rstrip("%"))
        parsed_date = parse_date(source_row["Date"])
        rows.append(
            {
                "date": parsed_date,
                "loss_rate_percent": parsed_rate,
                "note": source_row["Notes"],
                "phase": phase_for(parsed_date),
            }
        )


all_dates = [row["date"] for row in rows]
observed_rates = [
    row["loss_rate_percent"]
    for row in rows
    if row["loss_rate_percent"] is not None
]
expected_calendar_days = (all_dates[-1] - all_dates[0]).days + 1


rolling_window: deque[float | None] = deque(maxlen=7)
for row in rows:
    rolling_window.append(row["loss_rate_percent"])
    observed = [value for value in rolling_window if value is not None]
    row["rolling_7d_percent"] = (
        round(statistics.fmean(observed), 4) if len(observed) >= 4 else None
    )


phase_order = [
    "Pre real ads",
    "Transition",
    "July spike",
    "July decline",
    "August",
]
phase_summary = {}
for phase in phase_order:
    values = [
        row["loss_rate_percent"]
        for row in rows
        if row["phase"] == phase and row["loss_rate_percent"] is not None
    ]
    phase_summary[phase] = summarize(values)


release_windows = [
    ("1.0.30", date(2026, 7, 2), date(2026, 7, 19)),
    ("1.0.31", date(2026, 7, 20), date(2026, 7, 23)),
    ("1.0.32", date(2026, 7, 24), date(2026, 7, 28)),
    ("1.0.34", date(2026, 7, 29), date(2026, 7, 29)),
    ("1.0.35", date(2026, 7, 30), date(2026, 8, 16)),
]
release_summary = {}
for version, start, end in release_windows:
    values = [
        row["loss_rate_percent"]
        for row in rows
        if start <= row["date"] <= end and row["loss_rate_percent"] is not None
    ]
    release_summary[version] = {
        "start": start.isoformat(),
        "end": end.isoformat(),
        **summarize(values),
    }


pre_values = [
    row["loss_rate_percent"]
    for row in rows
    if row["date"] < date(2026, 6, 30) and row["loss_rate_percent"] is not None
]
post_spike_values = [
    row["loss_rate_percent"]
    for row in rows
    if row["date"] >= date(2026, 7, 4) and row["loss_rate_percent"] is not None
]

results = {
    "source": {
        "file": SOURCE.name,
        "sha256": hashlib.sha256(SOURCE.read_bytes()).hexdigest(),
        "row_count": len(rows),
        "date_start": rows[0]["date"].isoformat(),
        "date_end": rows[-1]["date"].isoformat(),
        "missing_rate_days": [
            row["date"].isoformat()
            for row in rows
            if row["loss_rate_percent"] is None
        ],
        "unique_date_count": len(set(all_dates)),
        "expected_calendar_days": expected_calendar_days,
        "duplicate_date_count": len(all_dates) - len(set(all_dates)),
        "invalid_rate_count": sum(
            not 0 <= value <= 100 for value in observed_rates
        ),
    },
    "known_changes": {
        "real_ad_ids_commit_date": "2026-06-30",
        "release_1_0_30_and_campaign_start": "2026-07-02",
        "peak_date": "2026-07-08",
        "peak_percent": 39.01,
    },
    "phase_summary": phase_summary,
    "release_summary": release_summary,
    "pre_vs_post_spike": {
        "pre_mean_percent": round(statistics.fmean(pre_values), 4),
        "post_mean_percent": round(statistics.fmean(post_spike_values), 4),
        "mean_difference_points": round(
            statistics.fmean(post_spike_values) - statistics.fmean(pre_values), 4
        ),
        "mean_ratio": round(
            statistics.fmean(post_spike_values) / statistics.fmean(pre_values), 4
        ),
        "pre_median_percent": round(statistics.median(pre_values), 4),
        "post_median_percent": round(statistics.median(post_spike_values), 4),
    },
    "limitations": [
        "The export contains daily rates but not user-loss numerators or installed-audience denominators.",
        "Daily averages are unweighted descriptive summaries, not recomputed aggregate loss rates.",
        "Real ads and paid acquisition changed within two days, so the export cannot identify their separate causal effects.",
        "The file is aggregated across all countries and cannot compare India with organic or other markets.",
        "Play installation statistics use Pacific Time, which can shift day-level alignment against the Google Ads account timezone.",
    ],
}

RESULTS.write_text(json.dumps(results, ensure_ascii=False, indent=2), encoding="utf-8")

with DAILY_OUTPUT.open("w", encoding="utf-8", newline="") as handle:
    writer = csv.DictWriter(
        handle,
        fieldnames=[
            "date",
            "loss_rate_percent",
            "rolling_7d_percent",
            "phase",
            "note",
        ],
    )
    writer.writeheader()
    for row in rows:
        writer.writerow(
            {
                "date": row["date"].isoformat(),
                "loss_rate_percent": row["loss_rate_percent"],
                "rolling_7d_percent": row["rolling_7d_percent"],
                "phase": row["phase"],
                "note": row["note"],
            }
        )

with sqlite3.connect(SQLITE_OUTPUT) as connection:
    connection.execute("DROP TABLE IF EXISTS daily_loss_rate")
    connection.execute(
        """
        CREATE TABLE daily_loss_rate (
            date TEXT PRIMARY KEY,
            loss_rate_percent REAL,
            rolling_7d_percent REAL,
            phase TEXT NOT NULL,
            note TEXT
        )
        """
    )
    connection.executemany(
        """
        INSERT INTO daily_loss_rate (
            date, loss_rate_percent, rolling_7d_percent, phase, note
        ) VALUES (?, ?, ?, ?, ?)
        """,
        [
            (
                row["date"].isoformat(),
                row["loss_rate_percent"],
                row["rolling_7d_percent"],
                row["phase"],
                row["note"],
            )
            for row in rows
        ],
    )

print(json.dumps(results, ensure_ascii=False, indent=2))
