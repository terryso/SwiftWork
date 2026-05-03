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
            tv.invalidateIntrinsicContentSize()
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(parent: self)
    }

    func makeNSView(context: Context) -> SendTextView {
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
        tv.textContainer?.widthTracksTextView = true
        tv.textContainer?.lineBreakMode = .byWordWrapping
        tv.textContainerInset = NSSize(width: 4, height: 6)
        tv.setContentHuggingPriority(.defaultLow, for: .horizontal)

        return tv
    }

    func updateNSView(_ tv: SendTextView, context: Context) {
        if tv.string != text {
            tv.string = text
            tv.invalidateIntrinsicContentSize()
        }
        tv.onSend = onSend
    }
}

final class SendTextView: NSTextView {
    var onSend: (() -> Void)?

    override var intrinsicContentSize: NSSize {
        guard let container = textContainer, let manager = layoutManager else {
            return super.intrinsicContentSize
        }
        manager.ensureLayout(for: container)
        let rect = manager.usedRect(for: container)
        return NSSize(width: -1, height: rect.height + textContainerInset.height * 2)
    }

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

        // IME composing — let it handle Enter (confirm candidate)
        if hasMarkedText() {
            super.keyDown(with: event)
            return
        }

        onSend?()
    }
}
