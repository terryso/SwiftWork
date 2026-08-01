import Foundation

enum TitleGenerator {
    static func generate(
        events: [AgentEvent],
        apiKey: String,
        baseURL: String?,
        model: String,
        provider: AgentProvider = .anthropic,
        httpClient: any HTTPDataLoading = URLSessionHTTPClient()
    ) async -> String? {
        let trimmedKey = apiKey.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedKey.isEmpty, !model.isEmpty else { return nil }

        let messages = events
            .filter { $0.type == .userMessage || $0.type == .assistant }
            .suffix(10)
            .map { event in
                [
                    "role": event.type == .userMessage ? "user" : "assistant",
                    "content": String(event.content.prefix(500))
                ]
            }

        guard !messages.isEmpty else { return nil }

        do {
            var request = URLRequest(
                url: try ProviderAPIEndpoints.messagesURL(provider: provider, baseURL: baseURL)
            )
            request.httpMethod = "POST"
            request.setValue("application/json", forHTTPHeaderField: "content-type")
            request.timeoutInterval = 15

            let body: [String: Any]
            switch provider {
            case .anthropic:
                request.setValue(trimmedKey, forHTTPHeaderField: "x-api-key")
                request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
                body = [
                    "model": model,
                    "max_tokens": 50,
                    "system": titlePrompt,
                    "messages": messages
                ]
            case .openAI:
                request.setValue("Bearer \(trimmedKey)", forHTTPHeaderField: "Authorization")
                body = [
                    "model": model,
                    "max_tokens": 50,
                    "messages": [["role": "system", "content": titlePrompt]] + messages
                ]
            }

            request.httpBody = try JSONSerialization.data(withJSONObject: body)
            let (data, response) = try await httpClient.data(for: request)
            try Task.checkCancellation()

            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                return nil
            }

            let rawTitle: String?
            switch provider {
            case .anthropic:
                rawTitle = anthropicTitle(from: data)
            case .openAI:
                rawTitle = openAITitle(from: data)
            }

            guard let rawTitle else { return nil }
            let title = rawTitle
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .trimmingCharacters(in: CharacterSet(charactersIn: "\"'「」"))
            guard !title.isEmpty else { return nil }
            return title.count > 30 ? String(title.prefix(30)) : title
        } catch {
            return nil
        }
    }

    private static let titlePrompt = "根据以下对话内容，生成一个简短的标题（最多20个字符，使用对话所用的语言）。只输出标题，不要输出任何其他内容。"

    private static func anthropicTitle(from data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let content = json["content"] as? [[String: Any]],
              let first = content.first else {
            return nil
        }
        return first["text"] as? String
    }

    private static func openAITitle(from data: Data) -> String? {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let choices = json["choices"] as? [[String: Any]],
              let first = choices.first,
              let message = first["message"] as? [String: Any] else {
            return nil
        }
        return message["content"] as? String
    }
}
