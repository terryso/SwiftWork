import Foundation

protocol HTTPDataLoading: Sendable {
    func data(for request: URLRequest) async throws -> (Data, URLResponse)
}

struct URLSessionHTTPClient: HTTPDataLoading {
    private let session: URLSession

    init(session: URLSession = .shared) {
        self.session = session
    }

    func data(for request: URLRequest) async throws -> (Data, URLResponse) {
        try await session.data(for: request)
    }
}

enum ProviderAPIEndpoints {
    static func modelsURL(provider: AgentProvider, baseURL: String?) throws -> URL {
        let pathComponents = provider == .anthropic ? ["v1", "models"] : ["models"]
        return try endpoint(provider: provider, baseURL: baseURL, pathComponents: pathComponents)
    }

    static func messagesURL(provider: AgentProvider, baseURL: String?) throws -> URL {
        let pathComponents = provider == .anthropic
            ? ["v1", "messages"]
            : ["chat", "completions"]
        return try endpoint(provider: provider, baseURL: baseURL, pathComponents: pathComponents)
    }

    private static func endpoint(
        provider: AgentProvider,
        baseURL: String?,
        pathComponents: [String]
    ) throws -> URL {
        let custom = baseURL?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        let rawBaseURL = custom.isEmpty ? provider.defaultBaseURL : custom
        let normalized = rawBaseURL.trimmingCharacters(in: CharacterSet(charactersIn: "/"))

        guard var components = URLComponents(string: normalized),
              let scheme = components.scheme?.lowercased(),
              scheme == "https" || scheme == "http",
              let host = components.host else {
            throw AppError(
                domain: .network,
                code: "INVALID_PROVIDER_BASE_URL",
                message: "Base URL 无效，请输入完整的 HTTP 或 HTTPS 地址"
            )
        }

        if scheme == "http", !isLoopback(host) {
            throw AppError(
                domain: .security,
                code: "INSECURE_PROVIDER_BASE_URL",
                message: "远程 Base URL 必须使用 HTTPS；仅本机地址可使用 HTTP"
            )
        }

        components.query = nil
        components.fragment = nil

        guard var url = components.url else {
            throw AppError(
                domain: .network,
                code: "INVALID_PROVIDER_BASE_URL",
                message: "Base URL 无效，请检查地址格式"
            )
        }

        for component in pathComponents {
            url.appendPathComponent(component)
        }
        return url
    }

    private static func isLoopback(_ host: String) -> Bool {
        let normalizedHost = host.lowercased()
        return normalizedHost == "localhost"
            || normalizedHost == "::1"
            || normalizedHost.hasPrefix("127.")
    }
}

protocol ModelDiscovering: Sendable {
    func fetchModels(
        provider: AgentProvider,
        apiKey: String,
        baseURL: String?
    ) async throws -> [String]
}

struct ModelDiscoveryService: ModelDiscovering {
    private struct ModelsResponse: Decodable {
        let data: [ModelRecord]
    }

    private struct ModelRecord: Decodable {
        let id: String
    }

    private let httpClient: any HTTPDataLoading

    init(httpClient: any HTTPDataLoading = URLSessionHTTPClient()) {
        self.httpClient = httpClient
    }

    func fetchModels(
        provider: AgentProvider,
        apiKey: String,
        baseURL: String?
    ) async throws -> [String] {
        try Task.checkCancellation()

        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty else {
            throw AppError(
                domain: .security,
                code: "MODEL_DISCOVERY_MISSING_API_KEY",
                message: "请先配置 API Key"
            )
        }

        var request = URLRequest(
            url: try ProviderAPIEndpoints.modelsURL(provider: provider, baseURL: baseURL)
        )
        request.httpMethod = "GET"
        request.timeoutInterval = 20

        switch provider {
        case .anthropic:
            request.setValue(trimmedKey, forHTTPHeaderField: "x-api-key")
            request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        case .openAI:
            request.setValue("Bearer \(trimmedKey)", forHTTPHeaderField: "Authorization")
        }

        do {
            let (data, response) = try await httpClient.data(for: request)
            try Task.checkCancellation()

            guard let httpResponse = response as? HTTPURLResponse else {
                throw AppError(
                    domain: .network,
                    code: "MODEL_DISCOVERY_INVALID_RESPONSE",
                    message: "模型服务返回了无效响应"
                )
            }

            guard (200...299).contains(httpResponse.statusCode) else {
                throw AppError(
                    domain: .network,
                    code: "MODEL_DISCOVERY_HTTP_\(httpResponse.statusCode)",
                    message: "获取模型失败（HTTP \(httpResponse.statusCode)）"
                )
            }

            let decoded: ModelsResponse
            do {
                decoded = try JSONDecoder().decode(ModelsResponse.self, from: data)
            } catch {
                throw AppError(
                    domain: .network,
                    code: "MODEL_DISCOVERY_INVALID_JSON",
                    message: "模型服务返回的数据格式无法识别"
                )
            }

            let models = Set(decoded.data.compactMap { record -> String? in
                let model = record.id.trimmingCharacters(in: .whitespacesAndNewlines)
                return model.isEmpty ? nil : model
            }).sorted()

            guard !models.isEmpty else {
                throw AppError(
                    domain: .network,
                    code: "MODEL_DISCOVERY_EMPTY",
                    message: "模型服务没有返回可用模型"
                )
            }

            return models
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as URLError where error.code == .cancelled {
            throw CancellationError()
        } catch let error as AppError {
            throw error
        } catch {
            if Task.isCancelled {
                throw CancellationError()
            }
            throw AppError(
                domain: .network,
                code: "MODEL_DISCOVERY_NETWORK_ERROR",
                message: "无法连接模型服务，请检查网络和 Base URL",
                underlying: error
            )
        }
    }
}
