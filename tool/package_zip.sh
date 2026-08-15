#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")/.."
version="$(sed -nE 's/^version: ([0-9]+\.[0-9]+\.[0-9]+).*/\1/p' pubspec.yaml)"
output="abzarfile-v${version}-source.zip"
rm -f "$output"
git ls-files -c -o --exclude-standard -z | sort -z | xargs -0 zip -q "$output"
unzip -tq "$output" >/dev/null
listing="$(mktemp)"
trap 'rm -f "$listing"' EXIT
unzip -Z1 "$output" > "$listing"
grep -Fxq '.github/workflows/ci.yml' "$listing"
echo "$output"
