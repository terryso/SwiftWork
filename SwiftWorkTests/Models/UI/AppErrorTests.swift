import XCTest
@testable import SwiftWork

final class AppErrorTests: XCTestCase {

    // MARK: - AC#4: AppError Unified Error Model

    // [P0] AppError conforms to LocalizedError
    func testAppErrorIsLocalizedError() throws {
        let error = AppError(
            domain: .network,
            code: "TIMEOUT",
            message: "Connection timed out",
            underlying: nil
        )

        XCTAssertEqual(error.errorDescription, "Connection timed out")
    }

    // [P0] AppError is Sendable
    func testAppErrorIsSendable() throws {
        let error = AppError(
            domain: .sdk,
            code: "STREAM_CLOSED",
            message: "Stream disconnected",
            underlying: nil
        )
        let _: any Sendable = error
    }

    // [P1] ErrorDomain has sdk, network, data, ui cases
    func testErrorDomainAllCases() throws {
        let domains: [ErrorDomain] = [.sdk, .network, .data, .ui]
        XCTAssertEqual(domains.count, 4)
    }

    // [P1] AppError carries optional underlying error
    func testAppErrorUnderlyingError() throws {
        let underlying = NSError(domain: "test", code: 1, userInfo: nil)
        let error = AppError(
            domain: .sdk,
            code: "WRAPPED",
            message: "Wrapped error",
            underlying: underlying
        )

        XCTAssertNotNil(error.underlying)
    }

    // [P1] AppError domain raw values are correct
    func testErrorDomainRawValues() throws {
        XCTAssertEqual(ErrorDomain.sdk.rawValue, "sdk")
        XCTAssertEqual(ErrorDomain.network.rawValue, "network")
        XCTAssertEqual(ErrorDomain.data.rawValue, "data")
        XCTAssertEqual(ErrorDomain.ui.rawValue, "ui")
    }
}
