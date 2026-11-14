#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/../.."
check_dir=$(mktemp -d /tmp/kiikick-field-server-sync.XXXXXX)
trap 'rm -rf "$check_dir"' EXIT
app=KIIKICK/KIIKICK
global="KIIKICK/KIIKICK Global"
network="$app/Respository/Network"
xcrun swiftc -parse-as-library \
  "$global"/Data/{TrackPoint,HeartRateSample,MatchEvent,WorkoutPayload,Position}.swift \
  "$app"/Data/{Field,WorkoutRecord}.swift \
  "$app"/Core/Encodable+.swift \
  "$network"/Endpoint/*.swift \
  "$network"/Common/{HTTPMethod,NetworkError,AuthHeader,MultipartFormData,IdempotencyKey}.swift \
  "$network"/Provider/{Provider,ProviderImpl,URLSessionable}.swift \
  "$network"/API/{VenueEndpoints,MatchEndpoints,QuarterWorkoutEndpoints}.swift \
  "$network"/DTO/{ResponseEnvelope,VenueDTO,MatchDTO,QuarterDTO,MatchResultDTO,ResultWorkoutEvent,QuarterWorkoutDTO}.swift \
  "$app"/Respository/{VenueStore,WorkoutSubmissionStore,FieldServerSync}.swift \
  Tests/FieldServerSyncChecks.swift -o "$check_dir/checks"
"$check_dir/checks"
