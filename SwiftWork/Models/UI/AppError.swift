import Foundation

enum ErrorDomain: String, Sendable {
    case sdk
    case network
    case data
    case ui
}

struct AppError: LocalizedError, Sendable {
    let domain: ErrorDomain
    let code: String
    let message: String
    let underlying: Error?

    var errorDescription: String? {
        message
    }

    init(
        domain: ErrorDomain,
        code: String,
        message: String,
        underlying: Error? = nil
    ) {
        self.domain = domain
        self.code = code
        self.message = message
        self.underlying = underlying
    }
}
