import SwiftUI

enum ScrollMode: Equatable {
    case followLatest
    case manualBrowse
}

@MainActor
@Observable
final class ScrollModeManager {
    var scrollMode: ScrollMode = .followLatest
    private(set) var isProgrammaticScrollInFlight = false

    var showReturnToBottomButton: Bool {
        scrollMode == .manualBrowse
    }

    // Matches OpenWork scroll-controller.ts thresholds
    private let nearBottomThreshold: CGFloat = 96
    private let scrollUpThreshold: CGFloat = 16

    private var cumulativeUpwardDelta: CGFloat = 0

    /// Processes scroll position changes to determine scroll mode.
    /// Uses cumulative delta so slow trackpad scrolling still triggers manual browse.
    /// - Parameters:
    ///   - scrollDelta: Change in top-anchor position, negated so negative = scrolled up.
    ///   - distanceFromBottom: Distance from viewport bottom to content bottom in points.
    func handleScrollChange(
        scrollDelta: CGFloat,
        distanceFromBottom: CGFloat,
        isProgrammatic: Bool = false
    ) {
        guard !isProgrammatic, !isProgrammaticScrollInFlight else { return }

        if distanceFromBottom <= nearBottomThreshold {
            scrollMode = .followLatest
            cumulativeUpwardDelta = 0
            return
        }

        if scrollDelta < 0 {
            // Scrolling up — accumulate
            cumulativeUpwardDelta += abs(scrollDelta)
            if cumulativeUpwardDelta >= scrollUpThreshold {
                scrollMode = .manualBrowse
            }
        } else if scrollDelta > 0 {
            // Scrolling down — reset accumulator
            cumulativeUpwardDelta = 0
        }
    }

    func returnToBottom() {
        scrollMode = .followLatest
        cumulativeUpwardDelta = 0
    }

    func beginProgrammaticScroll() {
        isProgrammaticScrollInFlight = true
    }

    func endProgrammaticScroll() {
        isProgrammaticScrollInFlight = false
        cumulativeUpwardDelta = 0
    }

    func resetForReload() {
        scrollMode = .followLatest
        cumulativeUpwardDelta = 0
        isProgrammaticScrollInFlight = false
    }
}
