# Changelog

## 0.3.0

- Add `JevFailureClassifier` returning provider-independent failure categories without retry or fallback policy.
- Integrate the SwiftDecision shared-budget API with the released SwiftDecision 0.6.0 dependency.

## 0.2.0

### Changed

- Raise the minimum iOS deployment target from iOS 13 to iOS 15. Apps that still support iOS 13 or 14 should remain on SwiftJev 0.1.x.

### Added

- Add an iOS Simulator build to CI.
- Add an iOS Keychain runbook for storing a user-provided TypeSafe API key locally.
