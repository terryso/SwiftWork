import Foundation

enum TimelineVirtualizationStrategy {
    case bufferedViewport
    case conservative
}

@MainActor
final class TimelineVirtualizationManager {
    let renderBuffer = 20
    private let strategy: TimelineVirtualizationStrategy

    init(strategy: TimelineVirtualizationStrategy = .bufferedViewport) {
        self.strategy = strategy
    }

    /// Clamps an arbitrary range so it is safe to apply to an events array.
    func clampedRange(_ range: Range<Int>, totalCount: Int) -> Range<Int> {
        guard totalCount > 0 else { return 0..<0 }

        let lower = min(max(0, range.lowerBound), totalCount)
        let upper = min(max(lower, range.upperBound), totalCount)
        return lower..<upper
    }

    func renderRange(visibleRange: Range<Int>, totalCount: Int) -> Range<Int> {
        guard totalCount > 0 else { return 0..<0 }

        switch strategy {
        case .bufferedViewport:
            let safeVisibleRange = clampedRange(visibleRange, totalCount: totalCount)
            let lower = max(0, safeVisibleRange.lowerBound - renderBuffer)
            let upper = min(totalCount, safeVisibleRange.upperBound + renderBuffer)
            return lower..<upper
        case .conservative:
            return 0..<totalCount
        }
    }

    /// Returns the subset of events that should be rendered,
    /// based on the current visible range plus a buffer on each side.
    func eventsToRender(visibleRange: Range<Int>, allEvents: [AgentEvent]) -> [AgentEvent] {
        guard !allEvents.isEmpty else { return [] }

        let renderRange = renderRange(visibleRange: visibleRange, totalCount: allEvents.count)
        guard !renderRange.isEmpty else { return [] }
        return Array(allEvents[renderRange])
    }
}
