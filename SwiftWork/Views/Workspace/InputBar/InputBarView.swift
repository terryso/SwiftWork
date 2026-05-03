import SwiftUI

struct InputBarView: View {
    let agentBridge: AgentBridge

    @State private var inputText: String = ""
    @FocusState private var isFocused: Bool

    private var trimmedInputText: String {
        inputText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        HStack(alignment: .bottom, spacing: InputBarComposerMetrics.controlSpacing) {
            ZStack(alignment: .topLeading) {
                IMESafeTextView(text: $inputText, onSend: sendMessage)
                    .focused($isFocused)

                Text(InputBarComposerMetrics.placeholderText)
                    .font(.system(size: InputBarComposerMetrics.fontSize))
                    .foregroundStyle(.secondary)
                    .opacity(InputBarComposerMetrics.showsPlaceholder(for: inputText) ? 1 : 0)
                    .padding(.leading, InputBarComposerMetrics.placeholderLeadingPadding)
                    .padding(.top, InputBarComposerMetrics.placeholderTopPadding)
                    .allowsHitTesting(false)
                    .accessibilityHidden(!InputBarComposerMetrics.showsPlaceholder(for: inputText))
            }
            .frame(
                minHeight: InputBarComposerMetrics.composerMinHeight,
                maxHeight: InputBarComposerMetrics.composerMaxHeight,
                alignment: .topLeading
            )
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(InputBarComposerMetrics.composerPadding)
            .fixedSize(horizontal: false, vertical: true)

            // Send button (always visible when there is text)
            if !trimmedInputText.isEmpty || !agentBridge.isRunning {
                Button {
                    sendMessage()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.title2)
                        .foregroundStyle(trimmedInputText.isEmpty ? .gray : .blue)
                }
                .buttonStyle(.plain)
                .disabled(trimmedInputText.isEmpty)
                .padding(.trailing, InputBarComposerMetrics.controlTrailingPadding)
                .padding(.bottom, InputBarComposerMetrics.controlBottomPadding)
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
                .padding(.trailing, InputBarComposerMetrics.controlTrailingPadding)
                .padding(.bottom, InputBarComposerMetrics.controlBottomPadding)
            }
        }
        .background(.bar)
        .clipShape(RoundedRectangle(cornerRadius: InputBarComposerMetrics.cornerRadius))
        .overlay(
            RoundedRectangle(cornerRadius: InputBarComposerMetrics.cornerRadius)
                .stroke(Color.primary.opacity(0.15), lineWidth: 1)
        )
        .padding(.horizontal)
        .padding(.vertical, InputBarComposerMetrics.outerVerticalPadding)
    }

    private func sendMessage() {
        let text = trimmedInputText
        guard !text.isEmpty else { return }

        agentBridge.sendMessage(text)
        inputText = ""
    }
}
