#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/../.."
check_dir=$(mktemp -d /tmp/kiikick-routing.XXXXXX)
trap 'rm -rf "$check_dir"' EXIT
xcrun swiftc -parse-as-library \
  'KIIKICK/KIIKICK Global/Data/TrackPoint.swift' \
  'KIIKICK/KIIKICK Global/Data/HeartRateSample.swift' \
  'KIIKICK/KIIKICK Global/Data/MatchEvent.swift' \
  'KIIKICK/KIIKICK Global/Data/WorkoutPayload.swift' \
  'KIIKICK/KIIKICK Global/Data/Position.swift' \
  KIIKICK/KIIKICK/Data/{Field,WorkoutRecord,FieldCoordinateMapper}.swift \
  KIIKICK/KIIKICK/Domain/{AnalysisEntry,AnalysisEntry+WorkoutRecord,AnalysisRoute}.swift \
  KIIKICK/KIIKICK/App/{AppRouter,AppRouter+Analysis}.swift \
  Tests/NotificationRoutingChecks.swift -o "$check_dir/checks"
"$check_dir/checks" write "$check_dir/records.store"
"$check_dir/checks" read "$check_dir/records.store"
"$check_dir/checks" verify "$check_dir/records.store"
