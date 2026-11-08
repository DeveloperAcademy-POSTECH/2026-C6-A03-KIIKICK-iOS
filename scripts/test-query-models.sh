#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")/.."
output_dir=$(mktemp -d)
trap 'rm -rf "$output_dir"' EXIT
domain=KIIKICK/KIIKICK/Domain
xcrun swiftc -swift-version 6 -parse-as-library \
  "$domain/Friend.swift" "$domain/FriendRequestStatus.swift" \
  "$domain/FriendSearchRequest.swift" "$domain/FriendSearchModel.swift" \
  "$domain/NotificationItem.swift" "$domain/NotificationRowModel.swift" \
  "$domain/NotificationSection.swift" "$domain/NotificationListModel.swift" \
  Tests/QueryModels/QueryModelsTests.swift -o "$output_dir/query-model-tests"
"$output_dir/query-model-tests"
