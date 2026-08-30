#!/usr/bin/env python3
"""Categorize a mutation_test JUnit report into caught/missed/unviable/notcovered.

Mirrors the contract of TripMind's scripts/mutants-txt.mjs:

    parse_args=(<junit.xml> <outdir>)
    python3 scripts/mutants_summary.py "work-0/mutation-test.junit.xml" "work-0"

Writes <outdir>/mutants.out/{caught,missed,unviable,notcovered}.txt where each
line is "<file>:<line>:<rule>".

Exit codes:
    0  no missed mutants (empty reports are normal for covered-only files)
    1  missed mutants present (blocking: CI fails the mutation-tests job)
    2  infrastructure failure (missing/unparseable report)
"""

import os
import sys
import xml.etree.ElementTree as ET

OUT_SUBDIR = "mutants.out"
FILES = {
    "caught": "caught.txt",
    "missed": "missed.txt",
    "unviable": "unviable.txt",
    "notcovered": "notcovered.txt",
}


def parse_testcase(tc):
    """Return (category, detail) for one <testcase>."""
    file_ = tc.get("classname", "?")
    name = tc.get("name", "")
    line = rule = "?"
    if name.startswith("Line"):
        parts = name.split("_")
        line = parts[0][len("Line"):]
        rule = parts[1] if len(parts) > 1 else "?"
    detail = f"{file_}:{line}:{rule}"
    for child in tc:
        tag = child.tag
        if tag == "failure":
            return "missed", detail
        if tag == "error":
            typ = child.get("type", "")
            if typ == "timeout":
                return "unviable", detail
            if typ.startswith("not covered"):
                return "notcovered", detail
            return "unviable", detail
    return "caught", detail


def main(argv):
    if len(argv) != 3:
        print("usage: mutants_summary.py <junit.xml> <outdir>", file=sys.stderr)
        return 2
    _, report_path, outdir = argv

    try:
        root = ET.parse(report_path).getroot()
    except Exception as exc:  # noqa: BLE001 - report infrastructure failure
        print(f"FATAL: cannot parse {report_path}: {exc}", file=sys.stderr)
        return 2

    buckets = {k: [] for k in FILES}
    for suite in root.iter("testsuite"):
        for tc in suite.iter("testcase"):
            category, detail = parse_testcase(tc)
            buckets.setdefault(category, buckets["caught"])  # unknown -> caught
            buckets[category].append(detail)

    n_total = sum(len(v) for v in buckets.values())
    if n_total == 0:
        # Legitimate for const-heavy files (0 mutation candidates); not an
        # infrastructure failure. Missing/unparseable reports are handled above.
        out_dir = f"{outdir}/{OUT_SUBDIR}"
        os.makedirs(out_dir, exist_ok=True)
        for k in FILES:
            open(f"{out_dir}/{FILES[k]}", "w").close()
        print(f"WARN: {report_path} contains no mutations")
        return 0

    parts = [f"  {k}: {len(v)}" for k, v in buckets.items()]
    print("mutants_summary:", " | ".join(parts))
    out_dir = f"{outdir}/{OUT_SUBDIR}"
    os.makedirs(out_dir, exist_ok=True)
    for k, lines in buckets.items():
        with open(f"{out_dir}/{FILES[k]}", "w") as fh:
            fh.write("".join(f"{l}\n" for l in lines))

    missed = len(buckets["missed"])
    if missed > 0:
        print(f"WARN: {missed} undetected mutant(s) — see "
              f"{outdir}/{OUT_SUBDIR}/{FILES['missed']}")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv))