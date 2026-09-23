#!/bin/sh

set -eu

if [ "$#" -ne 1 ]; then
  printf 'usage: %s <device-identifier>\n' "$0" >&2
  exit 64
fi

result_file="$(mktemp -t nownest-device-ready.XXXXXX)"
trap 'rm -f "$result_file"' EXIT

xcrun devicectl device info lockState \
  --device "$1" \
  --json-output "$result_file" \
  --quiet

if ! jq -e '
  .info.outcome == "success" and
  .result.passcodeRequired == false and
  .result.unlockedSinceBoot == true
' "$result_file" >/dev/null; then
  printf 'Physical device is locked or not ready for UI automation. Unlock it, keep it awake, and retry.\n' >&2
  exit 1
fi

printf 'Physical device is unlocked. Keep it awake while UI automation starts.\n'
