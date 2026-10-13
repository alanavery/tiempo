import Foundation

struct BreakCycle: Equatable {
    var breaksCompleted = 0
    var onBreak = false
}

enum BreakSignal: Equatable {
    case notify
    case pause
}

enum BreakSchedule {
    static func segmentLength(
        workdayHours: Double,
        intervals: Int,
        breakMinutes: Double
    ) -> TimeInterval? {
        guard intervals > 0, workdayHours > 0 else { return nil }
        let workdayMinutes = workdayHours * 60
        let breakTotal = Double(max(0, intervals - 1)) * max(0, breakMinutes)
        guard workdayMinutes > breakTotal else { return nil }
        let segmentMinutes = (workdayMinutes - breakTotal) / Double(intervals)
        guard segmentMinutes > 0 else { return nil }
        return segmentMinutes * 60
    }

    static func advance(
        total: TimeInterval,
        segment: TimeInterval,
        intervals: Int,
        cycle: BreakCycle
    ) -> (BreakCycle, [BreakSignal]) {
        let segmentSeconds = wholeSeconds(segment)
        guard segmentSeconds > 0, intervals > 0 else { return (cycle, []) }
        let maxBreaks = intervals - 1
        guard maxBreaks > 0 else { return (cycle, []) }
        if cycle.onBreak || cycle.breaksCompleted >= maxBreaks {
            return (cycle, [])
        }

        let nextBreakAt = (cycle.breaksCompleted + 1) * segmentSeconds
        guard wholeSeconds(total) >= nextBreakAt else { return (cycle, []) }
        return (
            BreakCycle(breaksCompleted: cycle.breaksCompleted, onBreak: true),
            [.notify, .pause]
        )
    }

    static func phase(
        total: TimeInterval,
        segment: TimeInterval,
        intervals: Int
    ) -> BreakCycle? {
        let segmentSeconds = wholeSeconds(segment)
        guard segmentSeconds > 0, intervals > 0 else { return nil }
        let maxBreaks = max(0, intervals - 1)
        let completed = min(wholeSeconds(total) / segmentSeconds, maxBreaks)
        return BreakCycle(breaksCompleted: completed, onBreak: false)
    }

    static func notifyTotal(breaksCompleted: Int, segment: TimeInterval) -> TimeInterval {
        TimeInterval((breaksCompleted + 1) * wholeSeconds(segment))
    }

    private static func wholeSeconds(_ interval: TimeInterval) -> Int {
        max(0, Int(interval.rounded(.down)))
    }
}
