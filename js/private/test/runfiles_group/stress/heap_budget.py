#!/usr/bin/env python3
"""Asserts that per-target retained heap does not grow with closure size.

Reads two `bazel dump --memory=shallow,summary,...` outputs — one for the last
library of a small synthetic closure, one for the last library of a closure twice
the size — and fails when the larger one retains disproportionately more.

`shallow` measures only what is *not* reachable from a node's direct deps, which is
close enough to "what that target's own providers add". A design whose per-target
cost is independent of the transitive group count keeps that number flat, so the
ratio is ~1.0. The flat bottom-up copy makes it grow linearly with the closure, so
doubling the closure gives a ratio of ~2.0.

Only the ratio is meaningful, not the absolute figure: the dumper re-bills interned
values (String, Label) to every node that reaches them, and bills a String a flat 24
bytes without traversing its backing array.

The check is deliberately shape-based rather than an absolute byte budget: it
survives Bazel version bumps, which move the constants but not the asymptote.

Usage:
    heap_budget.py small.txt large.txt [--max-growth 1.3]
"""

import argparse
import re
import sys

_SUMMARY = re.compile(r"(\d+)\s+objects,\s+(\d+)\s+bytes\s+retained")


def parse(path):
    """Returns (objects, bytes) from a `dump --memory=...,summary` output file."""
    with open(path, encoding="utf-8") as f:
        text = f.read()
    matches = _SUMMARY.findall(text)
    if not matches:
        sys.exit(
            "{}: no '<n> objects, <n> bytes retained' line found. Was this "
            "produced by `bazel dump --memory=shallow,summary,...`?\n"
            "--- content ---\n{}".format(path, text)
        )
    # Take the last match: bazel may print progress before the payload.
    objects, num_bytes = matches[-1]
    return int(objects), int(num_bytes)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("small", help="dump output for the smaller closure")
    parser.add_argument("large", help="dump output for the larger closure")
    parser.add_argument(
        "--max-growth",
        type=float,
        default=1.3,
        help="maximum tolerated bytes(large)/bytes(small) ratio (default: 1.3)",
    )
    args = parser.parse_args()

    small_objects, small_bytes = parse(args.small)
    large_objects, large_bytes = parse(args.large)

    if small_bytes == 0:
        sys.exit("{}: 0 bytes retained; the measurement is not meaningful".format(args.small))

    ratio = large_bytes / small_bytes
    print(
        "small: {:>9,} bytes ({:,} objects)\n"
        "large: {:>9,} bytes ({:,} objects)\n"
        "ratio: {:.2f} (limit {:.2f})".format(
            small_bytes, small_objects, large_bytes, large_objects, ratio, args.max_growth
        )
    )

    if ratio > args.max_growth:
        sys.exit(
            "FAIL: per-target retained heap grows with closure size "
            "({:.2f}x > {:.2f}x). The providers are holding something whose size "
            "is O(transitive group count).".format(ratio, args.max_growth)
        )
    print("OK: per-target retained heap is flat in closure size.")


if __name__ == "__main__":
    main()
