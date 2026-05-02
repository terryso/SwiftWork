import SwiftUI

/// Renders Markdown content with syntax-highlighted code blocks and collapsible long text.
struct MarkdownContentView: View {
    let markdown: String

    @State private var isExpanded = false
    @State private var renderedViews: [AnyView] = []
    @State private var cachedMarkdownHash: Int = 0

    private static let collapseCharThreshold = 1000
    private static let collapseLineThreshold = 20

    private var shouldCollapse: Bool {
        let charCount = markdown.count
        let lineCount = markdown.components(separatedBy: .newlines).count
        return charCount > Self.collapseCharThreshold || lineCount > Self.collapseLineThreshold
    }

    private var collapsedViewCount: Int {
        guard !renderedViews.isEmpty else { return 0 }
        let cutoff = max(1, renderedViews.count / 2)
        return min(cutoff, renderedViews.count)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            if shouldCollapse && !isExpanded {
                // Collapsed state
                ForEach(Array(renderedViews.prefix(collapsedViewCount).enumerated()), id: \.offset) { _, view in
                    view
                }
                if renderedViews.count > collapsedViewCount {
                    fadeOutOverlay
                }
                expandButton
            } else {
                // Expanded or short content
                ForEach(Array(renderedViews.enumerated()), id: \.offset) { _, view in
                    view
                }
                if shouldCollapse {
                    collapseButton
                }
            }
        }
        .onAppear {
            renderIfNeeded()
        }
        .onChange(of: markdown) {
            renderIfNeeded()
        }
    }

    // MARK: - Render Cache

    private func renderIfNeeded() {
        let newHash = markdown.hashValue
        guard newHash != cachedMarkdownHash else { return }
        cachedMarkdownHash = newHash
        renderedViews = MarkdownRenderer.render(markdown)
    }

    // MARK: - Collapse / Expand UI

    private var expandButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                isExpanded = true
            }
        } label: {
            Text("展开")
                .font(.caption)
                .foregroundStyle(Color.accentColor)
        }
        .buttonStyle(.plain)
    }

    private var collapseButton: some View {
        Button {
            withAnimation(.easeInOut(duration: 0.25)) {
                isExpanded = false
            }
        } label: {
            Text("折叠")
                .font(.caption)
                .foregroundStyle(Color.accentColor)
        }
        .buttonStyle(.plain)
    }

    private var fadeOutOverlay: some View {
        LinearGradient(
            colors: [
                Color(nsColor: .textBackgroundColor).opacity(0),
                Color(nsColor: .textBackgroundColor),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .frame(height: 40)
        .allowsHitTesting(false)
    }
}
