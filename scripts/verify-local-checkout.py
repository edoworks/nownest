#!/usr/bin/env python3
"""Verify the canonical NowNest checkout before release operations."""

import argparse
import json
import pathlib
import subprocess
import sys


def git(root, *args):
    result = subprocess.run(
        ["git", *args], cwd=root, capture_output=True, text=True, check=False
    )
    if result.returncode != 0:
        raise RuntimeError(result.stderr.strip() or f"git {' '.join(args)} failed")
    return result.stdout.strip()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--require-clean", action="store_true")
    parser.add_argument("--require-main-sync", action="store_true")
    args = parser.parse_args()

    root = pathlib.Path(git(pathlib.Path.cwd(), "rev-parse", "--show-toplevel"))
    errors = []
    if root.name != "NowNest":
        errors.append(f"checkout directory must be named NowNest, observed {root.name}")

    for legacy_name in ("FocusGate", "focusgate-repo"):
        if (root.parent / legacy_name).exists():
            errors.append(f"legacy sibling checkout exists: {legacy_name}")

    status = git(root, "status", "--porcelain=v1")
    if args.require_clean and status:
        errors.append("checkout is dirty")

    branch = git(root, "branch", "--show-current")
    head = git(root, "rev-parse", "HEAD")
    remote = git(root, "rev-parse", "refs/remotes/origin/main")
    if args.require_main_sync:
        if branch != "main":
            errors.append(f"branch must be main, observed {branch or 'detached'}")
        if head != remote:
            errors.append("HEAD does not equal fetched origin/main")

    result = {
        "decision": "PASS" if not errors else "BLOCKED",
        "root": str(root),
        "branch": branch,
        "head": head,
        "origin_main": remote,
        "clean": not bool(status),
        "errors": errors,
    }
    print(json.dumps(result, indent=2, sort_keys=True))
    return 0 if not errors else 1


if __name__ == "__main__":
    sys.exit(main())
