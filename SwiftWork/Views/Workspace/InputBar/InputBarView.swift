import SwiftUI

struct InputBarView: View {
    let agentBridge: AgentBridge

    @State private var inputText: String = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            IMESafeTextView(text: $inputText, onSend: sendMessage)
                .frame(minHeight: 36, maxHeight: 120)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .focused($isFocused)

            // Send button (always visible when there is text)
            if !inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || !agentBridge.isRunning {
                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : .blue)
                }
                .buttonStyle(.plain)
                .disabled(inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .padding(.trailing, 4)
                .padding(.bottom, 4)
            }

            // Stop button (visible when agent is running)
            if agentBridge.isRunning {
                Button {
                    agentBridge.cancelExecution()
                } label: {
                    Image(systemName: "stop.circle.fill")
                        .font(.title2)
                        .foregroundStyle(.red)
                }
                .buttonStyle(.plain)
                .padding(.trailing, 4)
                .padding(.bottom, 4)
            }
        }
        .background(.bar)
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.primary.opacity(0.15), lineWidth: 1)
        )
        .padding(.horizontal)
        .padding(.vertical, 8)
    }

    private func sendMessage() {
        let text = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }

        agentBridge.sendMessage(text)
        inputText = ""
    }
}
