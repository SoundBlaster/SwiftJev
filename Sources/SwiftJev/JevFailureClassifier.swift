import Foundation
import SwiftDecision
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

/// Classifies Jev failures without replacing the original error or applying recovery policy.
public enum JevFailureClassifier {
    public static func classify(_ error: any Error) -> DecisionFailureCategory {
        let engineCategory = DecisionFailureCategory.classify(error)
        if engineCategory != .permanent { return engineCategory }
        if let error = error as? URLError {
            switch error.code {
            case .cancelled: return .cancelled
            case .timedOut: return .timedOut
            case .cannotFindHost, .cannotConnectToHost, .networkConnectionLost,
                 .dnsLookupFailed, .notConnectedToInternet: return .transport
            default: return .permanent
            }
        }
        if let error = error as? JevDecisionBackendError, case let .httpFailure(statusCode) = error {
            if statusCode == 429 { return .rateLimited }
            if statusCode == 408 || statusCode == 425 || (500..<600).contains(statusCode) {
                return .serviceUnavailable
            }
        }
        return .permanent
    }
}
