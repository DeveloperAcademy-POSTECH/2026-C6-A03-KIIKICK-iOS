#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/../.."
check_dir=$(mktemp -d /tmp/kiikick-venues.XXXXXX)
trap 'rm -rf "$check_dir"' EXIT
app=KIIKICK/KIIKICK
network="$app/Respository/Network"
xcrun swiftc -parse-as-library \
  "$app"/Data/Field.swift \
  "$app"/Core/Encodable+.swift \
  "$network"/Endpoint/*.swift \
  "$network"/Common/{HTTPMethod,NetworkError,AuthHeader,MultipartFormData}.swift \
  "$network"/Provider/{Provider,ProviderImpl,URLSessionable}.swift \
  "$network"/API/VenueEndpoints.swift \
  "$network"/DTO/{ResponseEnvelope,VenueDTO}.swift \
  "$app"/Respository/VenueStore.swift \
  Tests/VenueChecks.swift -o "$check_dir/checks"
"$check_dir/checks"
