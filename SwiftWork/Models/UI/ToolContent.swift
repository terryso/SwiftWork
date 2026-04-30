import Foundation

struct ToolContent: Sendable {
    let toolName: String
    let toolUseId: String
    let input: String
    let output: String?
    let isError: Bool

    init(
        toolName: String,
        toolUseId: String,
        input: String,
        output: String?,
        isError: Bool
    ) {
        self.toolName = toolName
        self.toolUseId = toolUseId
        self.input = input
        self.output = output
        self.isError = isError
    }
}
