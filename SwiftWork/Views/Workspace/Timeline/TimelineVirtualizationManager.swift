import Foundation

@MainActor
final class TimelineVirtualizationManager {
    let renderBuffer = 20

    /// Clamps an arbitrary range so it is safe to apply to an events array.
    func clampedRange(_ range: Range<Int>, totalCount: Int) -> Range<Int> {
        guard totalCount > 0 else { return 0..<0 }

        let lower = min(max(0, range.lowerBound), totalCount)
        let upper = min(max(lower, range.upperBound), totalCount)
        return lower..<upper
    }

    /// Returns the subset of events that should be rendered,
    /// based on the current visible range plus a buffer on each side.
    func eventsToRender(visibleRange: Range<Int>, allEvents: [AgentEvent]) -> [AgentEvent] {
        guard !allEvents.isEmpty else { return [] }

        let safeVisibleRange = clampedRange(visibleRange, totalCount: allEvents.count)
        let lower = max(0, safeVisibleRange.lowerBound - renderBuffer)
        let upper = min(allEvents.count, safeVisibleRange.upperBound + renderBuffer)

        guard lower < upper else { return [] }
        return Array(allEvents[lower..<upper])
    }
}
