# SwiftJev

[![CI](https://github.com/SoundBlaster/SwiftJev/actions/workflows/ci.yml/badge.svg?branch=main)](https://github.com/SoundBlaster/SwiftJev/actions/workflows/ci.yml)
[![Swift 6.3+](https://img.shields.io/badge/Swift-6.3%2B-orange?logo=swift)](https://www.swift.org)
[![Apple platforms](https://img.shields.io/badge/Apple%20platforms-macOS%2010.15%2B%20%7C%20iOS%2015%2B%20%7C%20tvOS%2013%2B%20%7C%20watchOS%206%2B-lightgrey?logo=apple)](https://developer.apple.com)
[![License: Apache 2.0](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)

`SwiftJev` is the TypeSafe Jev provider for [SwiftDecision](https://github.com/SoundBlaster/SwiftDecision). It sends typed Noul, Choice, and Score prompts to the hosted System One API and returns validated probability distributions through SwiftDecision's `DecisionBackend` protocol.

## Add the package

```swift
dependencies: [
    .package(url: "https://github.com/SoundBlaster/SwiftJev.git", from: "0.4.0"),
    .package(url: "https://github.com/SoundBlaster/SwiftDecision.git", from: "0.6.0")
]
```

Add both products to the target that uses them:

```swift
.product(name: "SwiftDecision", package: "SwiftDecision"),
.product(name: "SwiftJev", package: "SwiftJev")
```

## Quick start

Set `TYPESAFE_API_KEY` or pass a key explicitly:

```swift
import SwiftDecision
import SwiftJev

let backend = try SwiftJev.JevDecisionBackend()
let engine = DecisionEngine(backend: backend)
let result = try await engine.noul(
    statement: "Is the service unavailable for all customers?",
    context: "The status page reports that all customers cannot sign in."
)
print(result.value, result.probabilities)
```

The backend validates every prompt and response against the Jev Noul, Choice, and Score contracts. It preserves prompt option order, rejects redirects, checks cancellation, and never includes credentials or response bodies in errors. HTTP transport is injectable for deterministic tests; no network requests happen during initialization.

## Custom API roots and proxies

The backend defaults to `https://api.typesafe.ai/v1`. To use a compatible proxy such as CoreInfra Hub, pass its HTTPS API root; SwiftJev appends `/systemone`:

```swift
let backend = try SwiftJev.JevDecisionBackend(
    apiKey: ProcessInfo.processInfo.environment["COREINFRA_API_KEY"],
    baseURL: URL(string: "https://hub.coreinfra.ai/typesafe/api/v1")!
)
```

The proxy must accept the TypeSafe System One request and response contract. Keep API keys in the host environment or Keychain; do not embed a shared key in an app binary.

For iOS apps, store a user-provided API key in Keychain and pass it explicitly to `JevDecisionBackend`. See the [iOS Keychain runbook](Documentation/iOS-Keychain-Runbook.md). Do not ship a shared provider key inside an app binary.

```sh
export TYPESAFE_API_KEY="your-api-key"
```

## Live benchmark

The benchmark is opt-in because requests are billable:

```sh
SWIFTJEV_RUN_JEV_BENCHMARKS=1 TYPESAFE_API_KEY="$TYPESAFE_API_KEY" \
  swift run --disable-sandbox JevBenchmark --samples 20
```

It reports end-to-end sequential latency and throughput for Noul, Choice, and Score. The benchmark never runs in CI and does not print prompts or credentials.

## Relationship to SwiftDecision

SwiftJev owns the provider and HTTP transport. SwiftDecision owns typed decision APIs, policy validation, acceptance and fallback behavior, cancellation, timeouts, and traces. This package is intentionally a thin provider adapter; it does not expose raw System One response models.

## License

Apache License 2.0. See [LICENSE](LICENSE).

### Failure classification

`JevFailureClassifier.classify(error)` returns a `DecisionFailureCategory` without
changing the thrown error. Cancellation, authentication, TLS, malformed responses,
and invalid configuration are not transient. Timeouts, selected connectivity
errors, HTTP 429, 408, 425 and 5xx are classified separately. This is descriptive:
the caller decides whether to retry or use a fallback. No automatic recovery is
added to `predict`. For a total deadline across several inferences, pass the same
SwiftDecision `DecisionBudget` to each engine call; HTTP timeout is an inactivity
limit and does not replace that budget.
