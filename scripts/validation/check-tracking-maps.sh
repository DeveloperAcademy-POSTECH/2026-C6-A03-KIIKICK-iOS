#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/../.."
tracking_check_dir=$(mktemp -d)
trap 'rm -rf "$tracking_check_dir"' EXIT
xcrun swiftc \
  'KIIKICK/KIIKICK Global/Data/TrackPoint.swift' \
  KIIKICK/KIIKICK/Data/SprintDetector.swift \
  KIIKICK/KIIKICK/Data/Field.swift \
  KIIKICK/KIIKICK/Data/FieldCoordinateMapper.swift \
  KIIKICK/KIIKICK/Data/HeatmapDensity.swift \
  KIIKICK/KIIKICK/Data/AttackDirectionTransform.swift \
  KIIKICK/KIIKICK/Data/FieldArtworkLayout.swift \
  KIIKICK/KIIKICK/Data/SprintArrowGeometry.swift \
  scripts/validation/TrackingMapsChecks.swift \
  -o "$tracking_check_dir/checks"
"$tracking_check_dir/checks"
xcrun swiftc \
  'KIIKICK/KIIKICK Global/Data/TrackPoint.swift' \
  'KIIKICK/KIIKICK Global/Data/HeartRateSample.swift' \
  'KIIKICK/KIIKICK Global/Data/MatchEvent.swift' \
  'KIIKICK/KIIKICK Global/Data/WorkoutPayload.swift' \
  'KIIKICK/KIIKICK Global/Data/Position.swift' \
  KIIKICK/KIIKICK/Data/Field.swift \
  KIIKICK/KIIKICK/Data/WorkoutRecord.swift \
  scripts/validation/TrackingSettingsChecks.swift \
  -o "$tracking_check_dir/settings-checks"
"$tracking_check_dir/settings-checks" write "$tracking_check_dir/settings.store"
"$tracking_check_dir/settings-checks" read "$tracking_check_dir/settings.store"
