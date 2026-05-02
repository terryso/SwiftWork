import Foundation

@MainActor
final class TimelineVirtualizationManager {
    let renderBuffer = 20

    /// Returns the subset of events that should be rendered,
    /// based on the current visible range plus a buffer on each side.
    func eventsToRender(visibleRange: Range<Int>, allEvents: [AgentEvent]) -> [AgentEvent] {
        guard !allEvents.isEmpty else { return [] }

        let lower = max(0, visibleRange.lowerBound - renderBuffer)
        let upper = min(allEvents.count, visibleRange.upperBound + renderBuffer)

        guard lower < upper else { return [] }
        return Array(allEvents[lower..<upper])
    }
}
