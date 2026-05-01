import SwiftUI

/// Unified tool card container that displays a paired toolUse/toolResult/toolProgress
/// as a single expandable card with status indicators, title, and result preview.
struct ToolCardView: View {
    let content: ToolContent
    let registry: ToolRendererRegistry
    let isSelected: Bool
    let onSelect: () -> Void

    @State private var isExpanded = false

    private var statusColor: Color {
        switch content.status {
        case .pending: return .gray
        case .running: return .blue
        case .completed: return .green
        case .failed: return .red
        }
    }

    private var statusLabel: String {
        switch content.status {
        case .pending: return "pending"
        case .running: return "running"
        case .completed: return "completed"
        case .failed: return "failed"
        }
    }

    private var toolIcon: String {
        if let renderer = registry.renderer(for: content.toolName) {
            // Use known SF Symbols for registered tools
            switch content.toolName {
            case "Bash": return "terminal"
            case "Edit": return "pencil.line"
            case "Grep": return "text.magnifyingglass"
            case "Read": return "doc.text"
            case "Write": return "pencil.and.outline"
            default: return "wrench.and.screwdriver"
            }
        }
        return "wrench.and.screwdriver"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Title row (always visible)
            titleRow
                .contentShape(Rectangle())
                .onTapGesture {
                    onSelect()
                    withAnimation(.easeInOut(duration: 0.2)) {
                        isExpanded.toggle()
                    }
                }

            // Expanded content
            if isExpanded {
                expandedContent
                    .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .padding(8)
        .background(cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 2)
        )
    }

    // MARK: - Title Row

    private var titleRow: some View {
        HStack(alignment: .top, spacing: 6) {
            Image(systemName: toolIcon)
                .font(.caption)
                .foregroundStyle(.secondary)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(resolvedSummaryTitle)
                        .font(.caption)
                        .fontWeight(.medium)
                        .lineLimit(1)

                    Spacer()

                    if content.status == .running {
                        ProgressView()
                            .controlSize(.mini)
                    }

                    Text(statusLabel)
                        .font(.system(size: 9))
                        .fontWeight(.medium)
                        .padding(.horizontal, 4)
                        .padding(.vertical, 1)
                        .background(statusColor.opacity(0.15))
                        .foregroundStyle(statusColor)
                        .clipShape(Capsule())
                }

                Text(content.toolName)
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)

                if let subtitle = resolvedSubtitle {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }

            if content.status == .running, let elapsed = content.elapsedTimeSeconds {
                Text("\(elapsed)s")
                    .font(.system(size: 9))
                    .foregroundStyle(.secondary)
                    .monospacedDigit()
            }
        }
    }

    // MARK: - Expanded Content

    private var expandedContent: some View {
        VStack(alignment: .leading, spacing: 8) {
            Divider()

            // Tool-specific body from renderer
            if let renderer = registry.renderer(for: content.toolName) {
                AnyView(renderer.body(content: content))
            } else {
                // Generic fallback for unregistered tools
                genericToolBody
            }

            // Input JSON
            if !content.input.isEmpty {
                VStack(alignment: .leading, spacing: 2) {
                    HStack {
                        Text("INPUT")
                            .font(.system(size: 9))
                            .fontWeight(.semibold)
                            .foregroundStyle(.secondary)
                        Spacer()
                        CopyButton(text: content.input)
                    }
                    Text(content.input)
                        .font(.system(.caption, design: .monospaced))
                        .foregroundStyle(.secondary)
                        .textSelection(.enabled)
                }
            }

            // Output
            if let output = content.output, !output.isEmpty {
                ToolResultContentView(output: output, isError: content.isError)
            }
        }
        .padding(.top, 4)
    }

    // MARK: - Generic Tool Body (fallback)

    private var genericToolBody: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(content.toolName)
                .font(.caption)
                .fontWeight(.medium)
            Text(content.input)
                .font(.system(.caption, design: .monospaced))
                .foregroundStyle(.secondary)
                .lineLimit(5)
        }
    }

    // MARK: - Helpers

    private var resolvedSummaryTitle: String {
        if let renderer = registry.renderer(for: content.toolName) {
            return renderer.summaryTitle(content: content)
        }
        return content.toolName
    }

    private var resolvedSubtitle: String? {
        if let renderer = registry.renderer(for: content.toolName) {
            return renderer.subtitle(content: content)
        }
        return nil
    }

    private var cardBackground: some ShapeStyle {
        if content.isError {
            return AnyShapeStyle(Color.red.opacity(0.05))
        }
        return AnyShapeStyle(Color.gray.opacity(0.1))
    }
}

// MARK: - Copy Button

struct CopyButton: View {
    let text: String

    @State private var copied = false

    var body: some View {
        Button {
            #if os(macOS)
            NSPasteboard.general.clearContents()
            NSPasteboard.general.setString(text, forType: .string)
            #else
            UIPasteboard.general.string = text
            #endif
            copied = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                copied = false
            }
        } label: {
            Image(systemName: copied ? "checkmark" : "doc.on.doc")
                .font(.system(size: 10))
                .foregroundStyle(copied ? .green : .secondary)
        }
        .buttonStyle(.plain)
    }
}
