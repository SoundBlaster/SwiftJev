# Changelog

## Unreleased

### Added

- Add `maximumChoiceProbabilityGap` to `JevDecisionBackend.init`. It defaults to `nil` (accept any `choice` that names a prompt option); set it to reject Choice responses whose `choice` falls more than that amount below the highest probability, or `0` to require the strict argmax.

### Fixed

- Accept Choice responses whose `choice` label is not the most probable one, matching the TypeSafe API. The API can return a near-tie `choice` slightly below the highest probability, which previously failed with `malformedResponse`. The returned distribution is unchanged.
- Replace the MIT `LICENSE` file with the Apache License 2.0 text, matching the README and SwiftDecision.

## 0.4.0

### Changed

- Raise the minimum SwiftDecision dependency to 0.7.0.

### Added

- Support configurable HTTPS API roots for TypeSafe-compatible providers and proxies, including CoreInfra Hub. The backend appends `/systemone` to the configured API root; the default remains `https://api.typesafe.ai/v1`.

## 0.3.0

- Add `JevFailureClassifier` returning provider-independent failure categories without retry or fallback policy.
- Integrate the SwiftDecision shared-budget API with the released SwiftDecision 0.6.0 dependency.

## 0.2.0

### Changed

- Raise the minimum iOS deployment target from iOS 13 to iOS 15. Apps that still support iOS 13 or 14 should remain on SwiftJev 0.1.x.

### Added

- Add an iOS Simulator build to CI.
- Add an iOS Keychain runbook for storing a user-provided TypeSafe API key locally.
