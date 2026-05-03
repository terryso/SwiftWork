import SwiftUI
import AppKit

enum InputBarComposerMetrics {
    static let placeholderText = "输入消息发送给 Agent..."
    static let fontSize = NSFont.systemFontSize
    static let textContainerInset = NSSize(width: 4, height: 3)
    static let lineFragmentPadding: CGFloat = 0
    static let singleLineTextHeight: CGFloat = 18
    static let singleLineHeight = singleLineTextHeight + textContainerInset.height * 2
    static let maxVisibleHeight: CGFloat = 96

    static let composerPadding = EdgeInsets(top: 4, leading: 8, bottom: 4, trailing: 6)
    static let controlSpacing: CGFloat = 6
    static let controlBottomPadding: CGFloat = 4
    static let controlTrailingPadding: CGFloat = 2
    static let outerVerticalPadding: CGFloat = 4
    static let cornerRadius: CGFloat = 10
    static let placeholderLeadingPadding = textContainerInset.width
    static let placeholderTopPadding = textContainerInset.height
    static let composerMinHeight = singleLineHeight
    static let composerMaxHeight = maxVisibleHeight

    static func clampedVisibleHeight(for contentHeight: CGFloat) -> CGFloat {
        min(max(contentHeight, singleLineHeight), maxVisibleHeight)
    }

    static func needsInternalScrolling(for contentHeight: CGFloat) -> Bool {
        contentHeight > maxVisibleHeight
    }

    static func showsPlaceholder(for text: String) -> Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
}

struct IMESafeTextView: NSViewRepresentable {
    @Binding var text: String
    var onSend: () -> Void

    @MainActor
    class Coordinator: NSObject, NSTextViewDelegate {
        let parent: IMESafeTextView

        init(parent: IMESafeTextView) {
            self.parent = parent
        }

        func textDidChange(_ notification: Notification) {
            guard let tv = notification.object as? NSTextView else { return }
            parent.text = tv.string
            (tv.enclosingScrollView as? AutoSizingScrollView)?
                .syncToTextViewState(resetScrollPosition: tv.string.isEmpty)
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeNSView(context: Context) -> AutoSizingScrollView {
        let scrollView = AutoSizingScrollView()
        scrollView.hasVerticalScroller = true
        scrollView.hasHorizontalScroller = false
        scrollView.autohidesScrollers = true
        scrollView.drawsBackground = false
        scrollView.borderType = .noBorder
        scrollView.scrollerStyle = .overlay
        scrollView.setContentHuggingPriority(.required, for: .vertical)
        scrollView.setContentCompressionResistancePriority(.required, for: .vertical)

        let tv = SendTextView()
        tv.delegate = context.coordinator
        tv.isRichText = false
        tv.drawsBackground = false
        tv.isEditable = true
        tv.isSelectable = true
        tv.font = NSFont.systemFont(ofSize: InputBarComposerMetrics.fontSize)
        tv.textColor = .textColor
        tv.insertionPointColor = .controlAccentColor
        tv.isAutomaticQuoteSubstitutionEnabled = false
        tv.isAutomaticDashSubstitutionEnabled = false
        tv.isAutomaticTextReplacementEnabled = false

        tv.isVerticallyResizable = true
        tv.isHorizontallyResizable = false
        tv.textContainer?.widthTracksTextView = false
        tv.textContainer?.lineBreakMode = .byWordWrapping
        tv.textContainer?.lineFragmentPadding = InputBarComposerMetrics.lineFragmentPadding
        tv.textContainerInset = InputBarComposerMetrics.textContainerInset
        tv.setContentHuggingPriority(.required, for: .vertical)
        tv.setContentCompressionResistancePriority(.required, for: .vertical)

        scrollView.documentView = tv
        scrollView.syncToTextViewState(resetScrollPosition: true)

        return scrollView
    }

    func updateNSView(_ scrollView: AutoSizingScrollView, context: Context) {
        guard let tv = scrollView.documentView as? SendTextView else { return }
        if !tv.hasMarkedText() && tv.string != text {
            let existingSelection = tv.selectedRange()
            tv.string = text
            let selectionLocation = min(existingSelection.location, tv.string.count)
            let selectionLength = min(existingSelection.length, max(tv.string.count - selectionLocation, 0))
            tv.setSelectedRange(NSRange(location: selectionLocation, length: selectionLength))
            scrollView.syncToTextViewState(resetScrollPosition: text.isEmpty)
        }
        tv.onSend = onSend
    }
}

final class AutoSizingScrollView: NSScrollView {
    override var intrinsicContentSize: NSSize {
        guard let tv = documentView as? NSTextView else {
            return NSSize(width: -1, height: InputBarComposerMetrics.singleLineHeight)
        }

        let height = InputBarComposerMetrics.clampedVisibleHeight(for: measuredContentHeight(for: tv))
        return NSSize(width: -1, height: height)
    }

    override func layout() {
        super.layout()
        guard let tv = documentView as? NSTextView,
              let container = tv.textContainer,
              let manager = tv.layoutManager else { return }

        let width = contentView.bounds.width
        guard width > 0 else { return }

        let padding = tv.textContainerInset.width * 2
        container.size = NSSize(width: max(width - padding, 0), height: .greatestFiniteMagnitude)
        manager.ensureLayout(for: container)
        let contentHeight = measuredContentHeight(for: tv)
        let visibleHeight = InputBarComposerMetrics.clampedVisibleHeight(for: contentHeight)
        hasVerticalScroller = InputBarComposerMetrics.needsInternalScrolling(for: contentHeight)
        tv.frame = NSRect(x: 0, y: 0, width: width, height: max(contentHeight, visibleHeight))
    }

    func syncToTextViewState(resetScrollPosition: Bool) {
        guard let tv = documentView as? NSTextView else { return }

        let contentHeight = measuredContentHeight(for: tv)
        hasVerticalScroller = InputBarComposerMetrics.needsInternalScrolling(for: contentHeight)
        invalidateIntrinsicContentSize()
        needsLayout = true

        if resetScrollPosition || !hasVerticalScroller {
            contentView.scroll(to: .zero)
            reflectScrolledClipView(contentView)
        }
    }

    private func measuredContentHeight(for textView: NSTextView) -> CGFloat {
        guard let container = textView.textContainer,
              let manager = textView.layoutManager else {
            return InputBarComposerMetrics.singleLineHeight
        }

        manager.ensureLayout(for: container)
        let usedHeight = manager.usedRect(for: container).height
        let textHeight = max(usedHeight, InputBarComposerMetrics.singleLineTextHeight)
        return textHeight + textView.textContainerInset.height * 2
    }
}

final class SendTextView: NSTextView {
    var onSend: (() -> Void)?

    override func keyDown(with event: NSEvent) {
        guard event.keyCode == 36 else {
            super.keyDown(with: event)
            return
        }

        let mods = event.modifierFlags.intersection(.deviceIndependentFlagsMask)
        if mods.contains(.shift) || mods.contains(.option) {
            super.keyDown(with: event)
            return
        }

        if hasMarkedText() {
            super.keyDown(with: event)
            return
        }

        onSend?()
    }
}
