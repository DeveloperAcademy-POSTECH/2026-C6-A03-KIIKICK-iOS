#!/bin/sh
set -eu

project_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
check_dir=$(mktemp -d)
trap 'rm -rf "$check_dir"' EXIT

swiftc -DDEBUG \
  "$project_root/KIIKICK/KIIKICK/Domain/OverallCalculator.swift" \
  "$project_root/KIIKICK/KIIKICK/Domain/OverallMockData.swift" \
  "$project_root/Tests/OverallCalculatorChecks.swift" \
  -o "$check_dir/check-overall"
"$check_dir/check-overall"
