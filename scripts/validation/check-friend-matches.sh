#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/../.."
check_dir=$(mktemp -d /tmp/kiikick-friends.XXXXXX)
trap 'rm -rf "$check_dir"' EXIT
app=KIIKICK/KIIKICK
network="$app/Respository/Network"
xcrun swiftc -parse-as-library \
  'KIIKICK/KIIKICK Global/Data/'{TrackPoint,HeartRateSample,MatchEvent,WorkoutPayload,Position}.swift \
  "$app"/Data/{Field,WorkoutRecord}.swift \
  "$app"/Domain/{AnalysisEntry,Comment,FriendMatchAnalysis}.swift \
  "$app"/Core/Encodable+.swift \
  "$network"/Endpoint/*.swift \
  "$network"/Common/{HTTPMethod,NetworkError,AuthHeader,IdempotencyKey,MultipartFormData}.swift \
  "$network"/Provider/{Provider,ProviderImpl,URLSessionable}.swift \
  "$network"/API/{FriendEndpoints,FriendMatchEndpoints,MatchCommentEndpoints}.swift \
  "$network"/DTO/{ResponseEnvelope,FriendDTO,MatchDTO,QuarterDTO,MatchResultDTO,ResultWorkoutEvent,MatchCommentResponse,FriendHeatmapDTO,VenueDTO}.swift \
  "$app"/Respository/FriendMatchLoader.swift \
  "$app"/Features/View/Friends/FriendMatchListModel.swift \
  "$app"/Features/View/Friends/FriendHeatmapModel.swift \
  "$app"/Features/View/Analysis/MatchCommentsModel.swift \
  Tests/FriendMatchChecks.swift -o "$check_dir/checks"
"$check_dir/checks" Tests/Fixtures/FriendMatchResults.json
