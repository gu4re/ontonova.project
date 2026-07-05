"""
Statistical campaign over the LIGHT-text quality test (scrum-3) — the twin of
scrum-6/campaign.py, so both texts report the same distribution statistics
(mean/median/std/min/max over N runs sampled across engine sessions).

Usage (from backend/, venv python, stack up):
    PYTHONPATH=. ./api/bin/python api/acceptance-tests/scrum-3/graph-quality/campaign.py --runs 9
    PYTHONPATH=. ./api/bin/python api/acceptance-tests/scrum-3/graph-quality/campaign.py --summarize
"""

import argparse
import json
import statistics
import subprocess
import sys
import time
from datetime import datetime, timezone
from pathlib import Path

sys.path.insert(0, str(Path(__file__).parent))
import main as gold  # the scrum-3 scorer/driver

RUNS_PATH = Path(__file__).parent / "runs.jsonl"
GRAPHS_DIR = Path(__file__).parent / "graphs"
SUMMARY_PATH = Path(__file__).parent / "campaign-summary.json"
BACKEND_CONTAINER = "ontonova-project-backend-1"


def _pruned_since(iso_ts: str) -> bool:
    try:
        logs = subprocess.run(
            ["docker", "logs", "--since", iso_ts, BACKEND_CONTAINER],
            capture_output=True, text=True, timeout=30,
        )
        return "degraded gracefully" in (logs.stdout + logs.stderr)
    except Exception:
        return False


def run_once(index: int) -> dict:
    started_iso = datetime.now(timezone.utc).isoformat()
    t0 = time.monotonic()
    result = gold.generate_ontology(gold.DOMAIN_TEXT)
    duration = round(time.monotonic() - t0, 1)
    payload = result["payload"]
    report = gold.evaluate(payload)
    categories = report["categories"].values()
    record = {
        "run": index,
        "started_at": started_iso,
        "duration_s": duration,
        "retries": result["retries"],
        "pruned": _pruned_since(started_iso),
        "counts": {
            "classes": len(payload["classes"]),
            "object_properties": len(payload["object_properties"]),
            "data_properties": len(payload["data_properties"]),
            "individuals": len(payload["individuals"]),
        },
        "macro_precision": round(sum(c["precision"] for c in categories) / len(report["categories"]), 3),
        "macro_recall": round(sum(c["recall"] for c in report["categories"].values()) / len(report["categories"]), 3),
        "macro_f1": report["macro_f1"],
        "categories": {k: v["f1"] for k, v in report["categories"].items()},
        "misses": report["misses"],
    }
    GRAPHS_DIR.mkdir(exist_ok=True)
    (GRAPHS_DIR / f"run-{index:02d}.json").write_text(
        json.dumps({"report": report, "payload": payload}, indent=1, ensure_ascii=False),
        encoding="utf-8",
    )
    return record


def summarize() -> dict:
    all_records = [json.loads(line) for line in RUNS_PATH.read_text().splitlines() if line.strip()]
    records = [r for r in all_records if not r.get("failed")]
    if not records:
        raise SystemExit("no successful runs recorded yet")

    def stats(values):
        return {
            "mean": round(statistics.mean(values), 3),
            "median": round(statistics.median(values), 3),
            "std": round(statistics.stdev(values), 3) if len(values) > 1 else 0.0,
            "min": round(min(values), 3),
            "max": round(max(values), 3),
        }

    summary = {
        "n_runs": len(all_records),
        "n_failed": len(all_records) - len(records),
        "macro_precision": stats([r["macro_precision"] for r in records]),
        "macro_recall": stats([r["macro_recall"] for r in records]),
        "macro_f1": stats([r["macro_f1"] for r in records]),
        "duration_s": stats([r["duration_s"] for r in records]),
        "retries": stats([r["retries"] for r in records]),
        "pruned_pct": round(100 * sum(r["pruned"] for r in records) / len(records), 1),
        "per_category_f1_mean": {
            cat: round(statistics.mean(r["categories"][cat] for r in records), 3)
            for cat in records[0]["categories"]
        },
    }
    SUMMARY_PATH.write_text(json.dumps(summary, indent=2, ensure_ascii=False), encoding="utf-8")
    print(json.dumps(summary, indent=2, ensure_ascii=False))
    return summary


def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--runs", type=int, default=0)
    parser.add_argument("--cooldown", type=int, default=10)
    parser.add_argument("--summarize", action="store_true")
    args = parser.parse_args()

    if args.runs:
        existing = len(RUNS_PATH.read_text().splitlines()) if RUNS_PATH.exists() else 0
        for offset in range(args.runs):
            index = existing + offset + 1
            t0 = time.monotonic()
            try:
                record = run_once(index)
            except AssertionError as exc:
                record = {
                    "run": index,
                    "started_at": datetime.now(timezone.utc).isoformat(),
                    "failed": True,
                    "error": str(exc)[:300],
                    "duration_s": round(time.monotonic() - t0, 1),
                }
            with RUNS_PATH.open("a", encoding="utf-8") as handle:
                handle.write(json.dumps(record, ensure_ascii=False) + "\n")
            if record.get("failed"):
                print(f"run {index}: FAILED after {record['duration_s']}s — {record['error']}")
            else:
                print(
                    f"run {index}: macro F1 {record['macro_f1']} "
                    f"(P {record['macro_precision']} R {record['macro_recall']}) "
                    f"{record['retries']} retries, {record['duration_s']}s, "
                    f"pruned={record['pruned']}"
                )
            if offset < args.runs - 1:
                time.sleep(args.cooldown)

    if args.summarize:
        summarize()


if __name__ == "__main__":
    main()
