import Foundation
import SwiftDecision
import SwiftJev
import XCTest
#if canImport(FoundationNetworking)
import FoundationNetworking
#endif

final class JevFailureClassifierTests: XCTestCase {
    func testTransientHTTPStatuses() {
        XCTAssertEqual(JevFailureClassifier.classify(JevDecisionBackendError.httpFailure(statusCode: 429)), .rateLimited)
        for status in [408, 425, 500, 503, 599] {
            XCTAssertEqual(JevFailureClassifier.classify(JevDecisionBackendError.httpFailure(statusCode: status)), .serviceUnavailable)
        }
        for status in [400, 401, 403, 404, 422, 600] {
            XCTAssertEqual(JevFailureClassifier.classify(JevDecisionBackendError.httpFailure(statusCode: status)), .permanent)
        }
    }

    func testTransportAllowlistAndCancellation() {
        for code in [URLError.cannotFindHost, .cannotConnectToHost, .networkConnectionLost, .dnsLookupFailed, .notConnectedToInternet] {
            XCTAssertEqual(JevFailureClassifier.classify(URLError(code)), .transport)
        }
        for code in [URLError.badURL, .serverCertificateUntrusted, .userAuthenticationRequired] {
            XCTAssertEqual(JevFailureClassifier.classify(URLError(code)), .permanent)
        }
        XCTAssertEqual(JevFailureClassifier.classify(URLError(.cancelled)), .cancelled)
        XCTAssertEqual(JevFailureClassifier.classify(CancellationError()), .cancelled)
        XCTAssertEqual(JevFailureClassifier.classify(URLError(.timedOut)), .timedOut)
        XCTAssertEqual(JevFailureClassifier.classify(DecisionError.timedOut), .timedOut)
        XCTAssertEqual(JevFailureClassifier.classify(JevDecisionBackendError.malformedResponse), .permanent)
    }
}
