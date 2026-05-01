import SwiftUI
import AppKit

struct WindowAccessor: NSViewRepresentable {
    let onWindowUpdate: (NSWindow?) -> Void

    func makeNSView(context: Context) -> NSView {
        let view = NSView()
        DispatchQueue.main.async {
            onWindowUpdate(view.window)
        }
        return view
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        // Only forward when the window reference actually changes
        let currentWindow = nsView.window
        if context.coordinator.lastWindow !== currentWindow {
            context.coordinator.lastWindow = currentWindow
            DispatchQueue.main.async {
                onWindowUpdate(currentWindow)
            }
        }
    }

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    final class Coordinator {
        weak var lastWindow: NSWindow?
    }
}
