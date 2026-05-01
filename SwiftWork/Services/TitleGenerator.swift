import Foundation

enum TitleGenerator {
    static func generate(
        events: [AgentEvent],
        apiKey: String,
        baseURL: String?,
        model: String
    ) async -> String? {
        guard !apiKey.isEmpty else { return nil }

        let messages = events
            .filter { $0.type == .userMessage || $0.type == .assistant }
            .suffix(10)
            .map { event -> [String: String] in
                let content = String(event.content.prefix(500))
                return [
                    "role": event.type == .userMessage ? "user" : "assistant",
                    "content": content
                ]
            }

        guard !messages.isEmpty else { return nil }

        let base = (baseURL ?? "https://api.anthropic.com")
            .trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        guard let url = URL(string: base + "/v1/messages") else { return nil }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(apiKey, forHTTPHeaderField: "x-api-key")
        request.setValue("2023-06-01", forHTTPHeaderField: "anthropic-version")
        request.setValue("application/json", forHTTPHeaderField: "content-type")
        request.timeoutInterval = 15

        let body: [String: Any] = [
            "model": model,
            "max_tokens": 50,
            "system": "根据以下对话内容，生成一个简短的标题（最多20个字符，使用对话所用的语言）。只输出标题，不要输出任何其他内容。",
            "messages": messages
        ]

        guard let httpBody = try? JSONSerialization.data(withJSONObject: body) else { return nil }
        request.httpBody = httpBody

        do {
            let (data, response) = try await URLSession.shared.data(for: request)
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                return nil
            }
            guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
                  let content = json["content"] as? [[String: Any]],
                  let first = content.first,
                  let text = first["text"] as? String else {
                return nil
            }
            let title = text
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .trimmingCharacters(in: CharacterSet(charactersIn: "\"'「」"))
            guard !title.isEmpty else { return nil }
            return title.count > 30 ? String(title.prefix(30)) : title
        } catch {
            return nil
        }
    }
}
