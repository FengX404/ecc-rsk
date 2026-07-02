#!/usr/bin/env python3
"""
Random criteria sampler for multi-angle-review.
Reads a CSV file of review criteria, optionally filters by category,
randomly samples N entries, and outputs JSON for sub-agent consumption.

Usage:
    python sample_criteria.py <csv_path> <count> [--filter category=<value>] [--seed <n>] [--all]

Examples:
    # Sample 3 random criteria from universal_criteria.csv
    python sample_criteria.py references/universal_criteria.csv 3

    # Sample 4 criteria from '性能' category only
    python sample_criteria.py references/quality_criteria.csv 4 --filter category=性能

    # Reproducible sampling with seed
    python sample_criteria.py references/ux_criteria.csv 3 --seed 42

    # Return all criteria (no random sampling)
    python sample_criteria.py references/universal_criteria.csv 0 --all
"""
import csv
import json
import random
import sys
from pathlib import Path


def parse_args():
    args = {"filter": None, "seed": None, "all": False}
    positional = []
    i = 1
    while i < len(sys.argv):
        arg = sys.argv[i]
        if arg == "--filter":
            i += 1
            args["filter"] = sys.argv[i]
        elif arg == "--seed":
            i += 1
            args["seed"] = int(sys.argv[i])
        elif arg == "--all":
            args["all"] = True
        else:
            positional.append(arg)
        i += 1
    if len(positional) < 2:
        print("Usage: sample_criteria.py <csv_path> <count> [--filter category=value] [--seed n] [--all]", file=sys.stderr)
        sys.exit(1)
    csv_path = positional[0]
    try:
        count = int(positional[1])
    except ValueError:
        print("Error: count must be an integer", file=sys.stderr)
        sys.exit(1)
    return csv_path, count, args


def load_criteria(csv_path: str) -> list[dict]:
    path = Path(csv_path)
    if not path.exists():
        print(f"Error: file not found: {csv_path}", file=sys.stderr)
        sys.exit(1)
    with open(path, "r", encoding="utf-8") as f:
        reader = csv.DictReader(f)
        rows = [row for row in reader]
    for row in rows:
        for key in row:
            row[key] = row[key].strip()
    return rows


def apply_filter(rows: list[dict], filter_str: str | None) -> list[dict]:
    if not filter_str:
        return rows
    if "=" not in filter_str:
        print(f"Error: filter format must be 'field=value', got: {filter_str}", file=sys.stderr)
        sys.exit(1)
    field, value = filter_str.split("=", 1)
    field, value = field.strip(), value.strip()
    return [row for row in rows if row.get(field, "") == value]


def sample(rows: list[dict], count: int, seed: int | None) -> list[dict]:
    if count <= 0 or count >= len(rows):
        return rows
    rng = random.Random(seed)
    return rng.sample(rows, count)


def main():
    csv_path, count, args = parse_args()
    script_dir = Path(__file__).parent.parent
    full_path = script_dir / csv_path
    rows = load_criteria(str(full_path))
    total = len(rows)
    filtered = apply_filter(rows, args["filter"])
    filtered_count = len(filtered)
    if args["all"]:
        sampled = filtered
    else:
        if count > filtered_count:
            print(
                f"Warning: requested {count} samples but only {filtered_count} available. "
                f"Returning all {filtered_count}.",
                file=sys.stderr,
            )
            sampled = filtered
        else:
            sampled = sample(filtered, count, args["seed"])
    result = {
        "csv_path": csv_path,
        "total_available": total,
        "filtered_count": filtered_count,
        "sampled_count": len(sampled),
        "filter_applied": args["filter"],
        "seed": args["seed"],
        "criteria": sampled,
    }
    print(json.dumps(result, ensure_ascii=False, indent=2))


if __name__ == "__main__":
    main()
