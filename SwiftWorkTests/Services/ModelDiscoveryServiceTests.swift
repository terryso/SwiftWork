import XCTest
@testable import SwiftWork

private actor ModelDiscoveryHTTPClient: HTTPDataLoading {
    private let data: Data
    private let statusCode: Int
    private(set) var lastRequest: URLRequest?

    init(json: String, statusCode: Int = 200) {
        self.data = Data(json.utf8)
        self.statusCode = statusCode
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        lastRequest = request
        guard let url = request.url,
              let response = HTTPURLResponse(
            url: url,
            statusCode: statusCode,
            httpVersion: nil,
            headerFields: nil
        ) else {
            throw AppError(
                domain: .network,
                code: "TEST_INVALID_REQUEST",
                message: "测试请求无效"
            )
        }
        return (data, response)
    }
}

private struct SuspendedModelDiscoveryHTTPClient: HTTPDataLoading {
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await Task.sleep(for: .seconds(60))
        throw AppError(domain: .network, code: "TEST_TIMEOUT", message: "测试超时")
    }
}

private struct CancelledModelDiscoveryHTTPClient: HTTPDataLoading {
    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        throw URLError(.cancelled)
    }
}

final class ModelDiscoveryServiceTests: XCTestCase {
    func testAnthropicUsesModelsEndpointAndRequiredHeaders() async throws {
        let client = ModelDiscoveryHTTPClient(json: #"{"data":[{"id":"claude-b"},{"id":"claude-a"}]}"#)
        let service = ModelDiscoveryService(httpClient: client)

        let models = try await service.fetchModels(
            provider: .anthropic,
            apiKey: "secret-key",
            baseURL: "https://gateway.example.com/"
        )

        XCTAssertEqual(models, ["claude-a", "claude-b"])
        let request = await client.lastRequest
        XCTAssertEqual(request?.url?.absoluteString, "https://gateway.example.com/v1/models")
        XCTAssertEqual(request?.value(forHTTPHeaderField: "x-api-key"), "secret-key")
        XCTAssertEqual(request?.value(forHTTPHeaderField: "anthropic-version"), "2023-06-01")
        XCTAssertNil(request?.value(forHTTPHeaderField: "Authorization"))
    }

    func testOpenAIUsesVersionedBaseURLAndBearerHeader() async throws {
        let client = ModelDiscoveryHTTPClient(json: #"{"data":[{"id":"gpt-5"}]}"#)
        let service = ModelDiscoveryService(httpClient: client)

        let models = try await service.fetchModels(
            provider: .openAI,
            apiKey: "openai-key",
            baseURL: "https://gateway.example.com/v1/"
        )

        XCTAssertEqual(models, ["gpt-5"])
        let request = await client.lastRequest
        XCTAssertEqual(request?.url?.absoluteString, "https://gateway.example.com/v1/models")
        XCTAssertEqual(request?.value(forHTTPHeaderField: "Authorization"), "Bearer openai-key")
        XCTAssertNil(request?.value(forHTTPHeaderField: "x-api-key"))
    }

    func testModelsAreTrimmedDeduplicatedAndSorted() async throws {
        let client = ModelDiscoveryHTTPClient(
            json: #"{"data":[{"id":" model-z "},{"id":""},{"id":"model-a"},{"id":"model-z"}]}"#
        )
        let service = ModelDiscoveryService(httpClient: client)

        let models = try await service.fetchModels(
            provider: .openAI,
            apiKey: "key",
            baseURL: nil
        )

        XCTAssertEqual(models, ["model-a", "model-z"])
    }

    func testHTTPErrorDoesNotExposeAPIKey() async {
        let client = ModelDiscoveryHTTPClient(
            json: #"{"error":{"message":"rejected"}}"#,
            statusCode: 401
        )
        let service = ModelDiscoveryService(httpClient: client)

        do {
            _ = try await service.fetchModels(
                provider: .openAI,
                apiKey: "super-secret-key",
                baseURL: nil
            )
            XCTFail("Expected HTTP error")
        } catch {
            XCTAssertFalse(error.localizedDescription.contains("super-secret-key"))
            XCTAssertTrue(error.localizedDescription.contains("401"))
        }
    }

    func testInvalidJSONAndEmptyListsAreRejected() async {
        let invalidService = ModelDiscoveryService(
            httpClient: ModelDiscoveryHTTPClient(json: "not-json")
        )
        let emptyService = ModelDiscoveryService(
            httpClient: ModelDiscoveryHTTPClient(json: #"{"data":[]}"#)
        )

        await XCTAssertThrowsErrorAsync {
            _ = try await invalidService.fetchModels(provider: .anthropic, apiKey: "key", baseURL: nil)
        }
        await XCTAssertThrowsErrorAsync {
            _ = try await emptyService.fetchModels(provider: .anthropic, apiKey: "key", baseURL: nil)
        }
    }

    func testInvalidBaseURLIsRejectedBeforeRequest() async {
        let client = ModelDiscoveryHTTPClient(json: #"{"data":[{"id":"unused"}]}"#)
        let service = ModelDiscoveryService(httpClient: client)

        await XCTAssertThrowsErrorAsync {
            _ = try await service.fetchModels(
                provider: .anthropic,
                apiKey: "key",
                baseURL: "not a URL"
            )
        }
        let request = await client.lastRequest
        XCTAssertNil(request)
    }

    func testCancellationIsPropagated() async {
        let service = ModelDiscoveryService(httpClient: SuspendedModelDiscoveryHTTPClient())
        let task = Task {
            try await service.fetchModels(
                provider: .openAI,
                apiKey: "key",
                baseURL: nil
            )
        }

        task.cancel()

        do {
            _ = try await task.value
            XCTFail("Expected cancellation")
        } catch is CancellationError {
            return
        } catch {
            XCTFail("Expected CancellationError, got \(error)")
        }
    }

    func testURLSessionCancellationIsNormalizedToCancellationError() async {
        let service = ModelDiscoveryService(httpClient: CancelledModelDiscoveryHTTPClient())

        do {
            _ = try await service.fetchModels(provider: .openAI, apiKey: "key", baseURL: nil)
            XCTFail("Expected cancellation")
        } catch is CancellationError {
            return
        } catch {
            XCTFail("Expected CancellationError, got \(error)")
        }
    }

    func testRemoteHTTPBaseURLIsRejectedBeforeSendingCredentials() async {
        let client = ModelDiscoveryHTTPClient(json: #"{"data":[{"id":"unused"}]}"#)
        let service = ModelDiscoveryService(httpClient: client)

        await XCTAssertThrowsErrorAsync {
            _ = try await service.fetchModels(
                provider: .openAI,
                apiKey: "secret-key",
                baseURL: "http://gateway.example.com/v1"
            )
        }
        let request = await client.lastRequest
        XCTAssertNil(request)
    }

    func testLoopbackHTTPBaseURLRemainsAvailableForLocalProviders() async throws {
        let client = ModelDiscoveryHTTPClient(json: #"{"data":[{"id":"local-model"}]}"#)
        let service = ModelDiscoveryService(httpClient: client)

        let models = try await service.fetchModels(
            provider: .openAI,
            apiKey: "local-key",
            baseURL: "http://127.0.0.1:11434/v1"
        )

        XCTAssertEqual(models, ["local-model"])
        let request = await client.lastRequest
        XCTAssertEqual(request?.url?.absoluteString, "http://127.0.0.1:11434/v1/models")
    }
}

private func XCTAssertThrowsErrorAsync(
    _ expression: () async throws -> Void,
    file: StaticString = #filePath,
    line: UInt = #line
) async {
    do {
        try await expression()
        XCTFail("Expected error", file: file, line: line)
    } catch {
        return
    }
}
