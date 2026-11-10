#!/bin/sh
set -eu

project_root=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
check_dir=$(mktemp -d)
trap 'rm -rf "$check_dir"' EXIT

swiftc \
  "$project_root/KIIKICK/KIIKICK/Domain/OverallCalculator.swift" \
  "$project_root/Tests/OverallCalculatorChecks.swift" \
  -o "$check_dir/check-overall"
"$check_dir/check-overall"

# 실제 SwiftData 모델과 어댑터를 별도 프로세스에서 저장·재조회한다.
xcrun swiftc \
  "$project_root/KIIKICK/KIIKICK Global/Data/TrackPoint.swift" \
  "$project_root/KIIKICK/KIIKICK Global/Data/HeartRateSample.swift" \
  "$project_root/KIIKICK/KIIKICK Global/Data/MatchEvent.swift" \
  "$project_root/KIIKICK/KIIKICK Global/Data/WorkoutPayload.swift" \
  "$project_root/KIIKICK/KIIKICK Global/Data/Position.swift" \
  "$project_root/KIIKICK/KIIKICK/Data/Field.swift" \
  "$project_root/KIIKICK/KIIKICK/Data/WorkoutRecord.swift" \
  "$project_root/KIIKICK/KIIKICK/Domain/OverallCalculator.swift" \
  "$project_root/KIIKICK/KIIKICK/Domain/OverallWorkoutInput+WorkoutRecord.swift" \
  "$project_root/Tests/OverallStoredRecordsChecks.swift" \
  -o "$check_dir/check-stored-overall"
"$check_dir/check-stored-overall" write "$check_dir/overall.store"
"$check_dir/check-stored-overall" read "$check_dir/overall.store"
