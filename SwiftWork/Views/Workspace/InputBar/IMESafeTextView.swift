import SwiftUI
import AppKit

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
            tv.enclosingScrollView?.invalidateIntrinsicContentSize()
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

        let tv = SendTextView()
        tv.delegate = context.coordinator
        tv.isRichText = false
        tv.drawsBackground = false
        tv.isEditable = true
        tv.isSelectable = true
        tv.font = NSFont.systemFont(ofSize: NSFont.systemFontSize)
        tv.textColor = .textColor
        tv.insertionPointColor = .controlAccentColor
        tv.isAutomaticQuoteSubstitutionEnabled = false
        tv.isAutomaticDashSubstitutionEnabled = false
        tv.isAutomaticTextReplacementEnabled = false

        tv.isVerticallyResizable = true
        tv.isHorizontallyResizable = false
        tv.textContainer?.widthTracksTextView = false
        tv.textContainer?.lineBreakMode = .byWordWrapping
        tv.textContainerInset = NSSize(width: 4, height: 4)

        scrollView.documentView = tv

        return scrollView
    }

    func updateNSView(_ scrollView: AutoSizingScrollView, context: Context) {
        guard let tv = scrollView.documentView as? SendTextView else { return }
        if !tv.hasMarkedText() && tv.string != text {
            tv.string = text
            scrollView.invalidateIntrinsicContentSize()
        }
        tv.onSend = onSend
    }
}

final class AutoSizingScrollView: NSScrollView {
    private static let singleLineHeight: CGFloat = 22
    private static let maxVisibleHeight: CGFloat = 120

    override var intrinsicContentSize: NSSize {
        guard let tv = documentView as? NSTextView,
              let container = tv.textContainer,
              let manager = tv.layoutManager else {
            return NSSize(width: -1, height: Self.singleLineHeight)
        }
        manager.ensureLayout(for: container)
        let rect = manager.usedRect(for: container)
        let contentHeight = rect.height + tv.textContainerInset.height * 2
        let height = min(max(contentHeight, Self.singleLineHeight), Self.maxVisibleHeight)
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
        let textHeight = manager.usedRect(for: container).height + tv.textContainerInset.height * 2
        tv.frame = NSRect(x: 0, y: 0, width: width, height: max(textHeight, Self.singleLineHeight + tv.textContainerInset.height * 2))
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
