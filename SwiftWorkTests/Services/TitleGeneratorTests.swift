import XCTest
@testable import SwiftWork

private actor TitleHTTPClient: HTTPDataLoading {
    private let responseData: Data
    private let statusCode: Int
    private(set) var lastRequest: URLRequest?

    init(json: String, statusCode: Int = 200) {
        self.responseData = Data(json.utf8)
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
            throw AppError(domain: .network, code: "TEST_RESPONSE", message: "测试响应无效")
        }
        return (responseData, response)
    }
}

final class TitleGeneratorTests: XCTestCase {
    private let events = [
        AgentEvent(type: .userMessage, content: "帮我修复登录问题", timestamp: .now),
        AgentEvent(type: .assistant, content: "正在检查", timestamp: .now)
    ]

    func testReturnsNilWithoutAPIKeyModelOrConversation() async {
        let missingAPIKey = await TitleGenerator.generate(
            events: events,
            apiKey: "",
            baseURL: nil,
            model: "claude-sonnet-4-6"
        )
        let missingModel = await TitleGenerator.generate(
            events: events,
            apiKey: "key",
            baseURL: nil,
            model: ""
        )
        let missingConversation = await TitleGenerator.generate(
            events: [AgentEvent(type: .system, content: "init", timestamp: .now)],
            apiKey: "key",
            baseURL: nil,
            model: "model"
        )

        XCTAssertNil(missingAPIKey)
        XCTAssertNil(missingModel)
        XCTAssertNil(missingConversation)
    }

    func testAnthropicProtocolBuildsMessagesRequestAndParsesTitle() async {
        let client = TitleHTTPClient(json: #"{"content":[{"type":"text","text":" 登录问题修复 "}]}"#)

        let title = await TitleGenerator.generate(
            events: events,
            apiKey: "anthropic-key",
            baseURL: "https://gateway.example.com/",
            model: "claude-model",
            provider: .anthropic,
            httpClient: client
        )

        XCTAssertEqual(title, "登录问题修复")
        let request = await client.lastRequest
        XCTAssertEqual(request?.url?.absoluteString, "https://gateway.example.com/v1/messages")
        XCTAssertEqual(request?.value(forHTTPHeaderField: "x-api-key"), "anthropic-key")
        XCTAssertEqual(request?.value(forHTTPHeaderField: "anthropic-version"), "2023-06-01")
        XCTAssertNil(request?.value(forHTTPHeaderField: "Authorization"))
    }

    func testOpenAIProtocolBuildsChatCompletionsRequestAndParsesTitle() async {
        let client = TitleHTTPClient(
            json: #"{"choices":[{"message":{"role":"assistant","content":"OpenAI 登录修复"}}]}"#
        )

        let title = await TitleGenerator.generate(
            events: events,
            apiKey: "openai-key",
            baseURL: "https://gateway.example.com/v1/",
            model: "gpt-model",
            provider: .openAI,
            httpClient: client
        )

        XCTAssertEqual(title, "OpenAI 登录修复")
        let request = await client.lastRequest
        XCTAssertEqual(request?.url?.absoluteString, "https://gateway.example.com/v1/chat/completions")
        XCTAssertEqual(request?.value(forHTTPHeaderField: "Authorization"), "Bearer openai-key")
        XCTAssertNil(request?.value(forHTTPHeaderField: "x-api-key"))
    }

    func testHTTPFailureInvalidURLAndInvalidJSONReturnNil() async {
        let failedClient = TitleHTTPClient(json: "{}", statusCode: 401)
        let invalidJSONClient = TitleHTTPClient(json: "not-json")

        let failedRequest = await TitleGenerator.generate(
            events: events,
            apiKey: "key",
            baseURL: nil,
            model: "model",
            httpClient: failedClient
        )
        let invalidURL = await TitleGenerator.generate(
            events: events,
            apiKey: "key",
            baseURL: "not a url",
            model: "model",
            httpClient: failedClient
        )
        let invalidJSON = await TitleGenerator.generate(
            events: events,
            apiKey: "key",
            baseURL: nil,
            model: "model",
            httpClient: invalidJSONClient
        )

        XCTAssertNil(failedRequest)
        XCTAssertNil(invalidURL)
        XCTAssertNil(invalidJSON)
    }

    func testLongTitleIsTruncatedToThirtyCharacters() async {
        let longTitle = String(repeating: "标", count: 40)
        let client = TitleHTTPClient(
            json: #"{"content":[{"type":"text","text":"\#(longTitle)"}]}"#
        )

        let title = await TitleGenerator.generate(
            events: events,
            apiKey: "key",
            baseURL: nil,
            model: "model",
            httpClient: client
        )

        XCTAssertEqual(title?.count, 30)
    }
}
