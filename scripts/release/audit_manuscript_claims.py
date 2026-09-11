#!/usr/bin/env python3
"""Audit numerical claims in the rc-dates submission against accepted evidence.

The claim specification is deliberately declarative: every row names the
manuscript location, evidence file, selection/filter, expected rounded value,
and tolerance.  The audit reads aggregate CSV/JSON evidence only; it does not
modify data or rerun the R analysis.
"""

from __future__ import annotations

import argparse
import csv
import json
import math
import re
import sys
from pathlib import Path
from typing import Any


def load_csv(path: Path) -> list[dict[str, str]]:
    with path.open(newline="", encoding="utf-8") as handle:
        return list(csv.DictReader(handle))


def parse_scalar(value: str) -> Any:
    value = value.strip()
    if value == "":
        return ""
    if value.lower() in {"true", "false"}:
        return value.lower() == "true"
    try:
        return float(value)
    except ValueError:
        return value


def parse_expected(value: str) -> Any:
    value = value.strip()
    if value.startswith("[") or value.startswith("{"):
        return json.loads(value)
    return parse_scalar(value)


def parse_filters(spec: str) -> dict[str, str]:
    if not spec.strip():
        return {}
    result: dict[str, str] = {}
    for item in spec.split(";"):
        key, separator, value = item.partition("=")
        if not separator:
            raise ValueError(f"invalid filter {item!r}; expected key=value")
        result[key.strip()] = value.strip()
    return result


def select(rows: list[dict[str, str]], filters: dict[str, str]) -> list[dict[str, str]]:
    def matches(actual: str | None, wanted: str) -> bool:
        if wanted.startswith("!"):
            return actual != wanted[1:]
        return actual in wanted.split("|")

    return [row for row in rows if all(matches(row.get(k), v) for k, v in filters.items())]


def numeric(row: dict[str, str], field: str) -> float:
    try:
        value = float(row[field])
    except (KeyError, TypeError, ValueError) as exc:
        raise ValueError(f"field {field!r} is not numeric in row {row}") from exc
    if not math.isfinite(value):
        raise ValueError(f"field {field!r} is not finite in row {row}")
    return value


def validate_location(location: str, root: Path) -> None:
    """Require each evidence claim to point to a real manuscript line.

    The registry is an evidence-value index rather than a prose parser.  This
    check keeps its manuscript anchors live without asserting that every
    evidence value must be printed verbatim in the prose.
    """
    path_text, separator, line_text = location.rpartition(":")
    if not separator or not path_text or not line_text:
        raise ValueError(f"invalid manuscript location {location!r}")
    try:
        line_number = int(line_text)
    except ValueError as exc:
        raise ValueError(f"invalid manuscript line in location {location!r}") from exc
    path = Path(path_text)
    if not path.is_absolute():
        path = root / path
    if not path.is_file():
        raise ValueError(f"missing manuscript location file: {path_text}")
    lines = path.read_text(encoding="utf-8").splitlines()
    if line_number < 1 or line_number > len(lines):
        raise ValueError(f"manuscript location line is out of range: {location!r}")
    if not lines[line_number - 1].strip():
        raise ValueError(f"manuscript location line is blank: {location!r}")


def compare(actual: Any, expected: Any, tolerance: float) -> bool:
    if isinstance(expected, list):
        return (
            isinstance(actual, list)
            and len(actual) == len(expected)
            and all(compare(a, e, tolerance) for a, e in zip(actual, expected))
        )
    if isinstance(expected, bool):
        return actual is expected
    if isinstance(expected, (int, float)) and isinstance(actual, (int, float)):
        return math.isclose(float(actual), float(expected), rel_tol=0.0, abs_tol=tolerance)
    return str(actual) == str(expected)


def run_claim(claim: dict[str, str], root: Path) -> tuple[str, Any, str]:
    validate_location(claim["location"], root)
    path = root / claim["input_path"]
    if not path.exists():
        return "UNVERIFIED", None, f"missing evidence: {claim['input_path']}"
    operation = claim["operation"]
    expected = parse_expected(claim["expected"])
    tolerance = float(claim.get("tolerance") or 0)

    if operation == "text_float":
        text = path.read_text(encoding="utf-8")
        pattern = claim["field"]
        matches = re.findall(pattern, text, flags=re.MULTILINE)
        if len(matches) != 1:
            return "FAIL", None, f"expected one regex match, found {len(matches)}"
        actual = float(matches[0])
        return ("PASS" if compare(actual, expected, tolerance) else "FAIL", actual, "")

    rows = load_csv(path)
    filters = parse_filters(claim.get("filters", ""))
    selected = select(rows, filters)
    field = claim.get("field", "")
    if operation == "count_rows":
        actual = len(selected)
    elif operation == "sum_field":
        actual = sum(numeric(row, field) for row in selected)
    elif operation == "count_unique":
        actual = len({row[field] for row in selected})
    elif operation == "field_equals":
        if len(selected) != 1:
            return "FAIL", None, f"expected one selected row, found {len(selected)}"
        actual = parse_scalar(selected[0][field])
    elif operation == "all_field_equals":
        actual = all(parse_scalar(row[field]) == expected for row in selected)
    elif operation == "range":
        if not selected:
            return "FAIL", None, "no rows selected"
        values = [numeric(row, field) for row in selected]
        actual = [min(values), max(values)]
    elif operation == "interval":
        if len(selected) != 1:
            return "FAIL", None, f"expected one selected row, found {len(selected)}"
        actual = [numeric(selected[0], "q025"), numeric(selected[0], "q975")]
    elif operation == "abs_range":
        if not selected:
            return "FAIL", None, "no rows selected"
        values = [abs(numeric(row, field)) for row in selected]
        actual = [min(values), max(values)]
    elif operation == "count_field_equals":
        condition = parse_scalar(claim.get("condition") or claim["expected"])
        actual = sum(parse_scalar(row[field]) == condition for row in selected)
    elif operation == "count_field_nonzero":
        actual = sum(not math.isclose(numeric(row, field), 0.0, abs_tol=tolerance) for row in selected)
    elif operation == "count_positive":
        actual = sum(numeric(row, field) > 0 for row in selected)
    else:
        return "FAIL", None, f"unknown operation {operation!r}"

    status = "PASS" if compare(actual, expected, tolerance) else "FAIL"
    detail = "" if status == "PASS" else f"selected {len(selected)} row(s)"
    return status, actual, detail


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__)
    script_path = Path(__file__).resolve()
    # This script lives under scripts/release; keep --root relocatable for
    # direct execution while allowing an explicit root for CI or review.
    default_root = script_path.parents[2] if script_path.parent.name == "release" else script_path.parents[1]
    parser.add_argument("--root", type=Path, default=default_root)
    parser.add_argument("--claims", type=Path, default=Path("release/claims.csv"))
    parser.add_argument("--json", action="store_true", help="emit machine-readable results")
    args = parser.parse_args()

    root = args.root.resolve()
    claims_path = args.claims if args.claims.is_absolute() else root / args.claims
    claims = load_csv(claims_path)
    required = {"id", "location", "input_path", "operation", "field", "expected", "tolerance"}
    missing = required - set(claims[0]) if claims else required
    if missing:
        raise SystemExit(f"claims specification missing columns: {', '.join(sorted(missing))}")

    results = []
    for claim in claims:
        try:
            status, actual, detail = run_claim(claim, root)
        except (OSError, ValueError, KeyError, json.JSONDecodeError) as exc:
            status, actual, detail = "FAIL", None, str(exc)
        results.append({
            "id": claim["id"],
            "location": claim["location"],
            "status": status,
            "actual": actual,
            "expected": parse_expected(claim["expected"]),
            "input_path": claim["input_path"],
            "detail": detail,
        })

    if args.json:
        print(json.dumps(results, indent=2, sort_keys=True))
    else:
        for result in results:
            suffix = f" ({result['detail']})" if result["detail"] else ""
            print(f"{result['status']:10s} {result['id']}: {result['actual']!r} == {result['expected']!r}{suffix}")
        counts = {status: sum(row["status"] == status for row in results) for status in ("PASS", "FAIL", "UNVERIFIED")}
        print(f"\n{len(results)} claims: {counts['PASS']} passed, {counts['FAIL']} failed, {counts['UNVERIFIED']} unverified")

    # Missing evidence is an incomplete audit: callers should not mistake an
    # unverified release claim for a clean result.
    return 1 if any(row["status"] != "PASS" for row in results) else 0


if __name__ == "__main__":
    sys.exit(main())
