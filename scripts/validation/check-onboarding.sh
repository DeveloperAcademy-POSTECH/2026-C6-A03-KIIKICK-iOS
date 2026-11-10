#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/../.."
output_dir=$(mktemp -d /tmp/kiikick-onboarding.XXXXXX)
trap 'rm -rf "$output_dir"' EXIT
app=KIIKICK/KIIKICK
network="$app/Respository/Network"
xcrun swiftc -parse-as-library -default-isolation MainActor \
  "$network"/Endpoint/*.swift \
  "$network"/Common/{HTTPMethod,NetworkError,AuthHeader,IdempotencyKey,MultipartFormData}.swift \
  "$network"/Provider/Provider.swift \
  "$network"/API/{AuthEndpoints,AvatarEndpoints}.swift \
  "$network"/DTO/{AuthDTO,OnboardingRequest,OnboardingConsent,ResponseEnvelope}.swift \
  "$app/Core/Encodable+.swift" \
  "$app/Features/View/Auth/SignUpCompletionModel.swift" \
  "$app/App/AppRouter.swift" \
  scripts/validation/OnboardingChecks.swift \
  -o "$output_dir/checks"
"$output_dir/checks"
