#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/../.."
check_dir=$(mktemp -d /tmp/kiikick-field-assignment.XXXXXX)
trap 'rm -rf "$check_dir"' EXIT
app=KIIKICK/KIIKICK
global="KIIKICK/KIIKICK Global"
xcrun swiftc -parse-as-library \
  "$global"/Data/{TrackPoint,HeartRateSample,MatchEvent,WorkoutPayload,Position}.swift \
  "$app"/Data/{Field,WorkoutRecord}.swift \
  "$app"/Domain/{AnalysisEntry,FieldAssignment}.swift \
  Tests/FieldAssignmentChecks.swift -o "$check_dir/checks"
"$check_dir/checks"
