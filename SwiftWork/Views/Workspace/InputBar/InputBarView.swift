import SwiftUI

struct InputBarView: View {
    let agentBridge: AgentBridge

    @State private var inputText: String = ""
    @State private var selectionRequest: NSRange?
    @State private var autocompleteVM = SkillAutocompleteViewModel()
    @FocusState private var isFocused: Bool

    private var trimmedInputText: String {
        inputText.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        VStack(spacing: 0) {
            // Autocomplete menu above the input bar
            if autocompleteVM.isVisible {
                SkillAutocompleteMenuView(viewModel: autocompleteVM) { selectedText in
                    applyAutocomplete(selectedText)
                }
                .padding(.horizontal)
                .padding(.top, 4)
            }

            HStack(alignment: .bottom, spacing: InputBarComposerMetrics.controlSpacing) {
                ZStack(alignment: .topLeading) {
                    IMESafeTextView(
                        text: $inputText,
                        selectionRequest: $selectionRequest,
                        onSend: sendMessage,
                        onEscape: handleEscape,
                        onArrowUp: handleArrowUp,
                        onArrowDown: handleArrowDown,
                        onTabWithAutocomplete: handleTabWithAutocomplete
                    )
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

            inlineErrorMessage
        }
        .onChange(of: inputText) { _, newValue in
            if agentBridge.errorMessage != nil {
                agentBridge.errorMessage = nil
            }
            agentBridge.refreshDiscoveredSkillsSnapshot()
            autocompleteVM.updateQuery(newValue)
        }
        .onAppear {
            agentBridge.refreshDiscoveredSkillsSnapshot()
            autocompleteVM.updateSkillsSource(agentBridge.discoveredSkills, currentText: inputText)
        }
        .onChange(of: agentBridge.discoveredSkillsRevision) { _, _ in
            autocompleteVM.updateSkillsSource(agentBridge.discoveredSkills, currentText: inputText)
        }
    }

    private func sendMessage() {
        let text = trimmedInputText
        guard !text.isEmpty else { return }

        autocompleteVM.dismiss()
        let outcome = agentBridge.sendMessage(text)
        switch outcome {
        case .ignored, .sentPlainText, .sentSlashSkill:
            inputText = ""
        case .rejectedUnavailableSkill:
            break
        }
    }

    @ViewBuilder
    private var inlineErrorMessage: some View {
        if let error = agentBridge.errorMessage, !error.isEmpty {
            Text(error)
                .font(.caption)
                .foregroundStyle(.red)
                .padding(.horizontal)
                .padding(.top, 2)
        }
    }

    private func handleEscape() -> Bool {
        guard autocompleteVM.isVisible else { return false }
        autocompleteVM.dismiss()
        return true
    }

    private func handleArrowUp() -> Bool {
        guard autocompleteVM.isVisible else { return false }
        autocompleteVM.moveSelection(down: false)
        return true
    }

    private func handleArrowDown() -> Bool {
        guard autocompleteVM.isVisible else { return false }
        autocompleteVM.moveSelection(down: true)
        return true
    }

    private func handleTabWithAutocomplete() -> Bool {
        guard autocompleteVM.isVisible,
              let index = autocompleteVM.selectedIndex,
              let result = autocompleteVM.selectSkill(at: index) else {
            return false
        }
        applyAutocomplete(result)
        return true
    }

    private func applyAutocomplete(_ selectedText: String) {
        let completedText = selectedText + " "
        inputText = completedText
        selectionRequest = selectionRangeAtEnd(of: completedText)
        autocompleteVM.dismiss()
    }
}
