import Foundation

struct BreakCycle: Equatable {
    var breaksCompleted = 0
    var onBreak = false
    var workdayComplete = false
    var balanced = false
}

enum BreakSignal: Equatable {
    case notify
    case pause
    case workdayComplete
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

    static func totalBreakTime(intervals: Int, breakMinutes: Double) -> TimeInterval {
        Double(max(0, intervals - 1)) * max(0, breakMinutes) * 60
    }

    static func advance(
        total: TimeInterval,
        segment: TimeInterval,
        intervals: Int,
        cycle: BreakCycle
    ) -> (BreakCycle, [BreakSignal]) {
        let segmentSeconds = wholeSeconds(segment)
        guard segmentSeconds > 0, intervals > 0 else { return (cycle, []) }
        if cycle.workdayComplete || cycle.onBreak {
            return (cycle, [])
        }

        let totalSeconds = wholeSeconds(total)
        let maxBreaks = max(0, intervals - 1)
        let workdayAt = intervals * segmentSeconds

        if cycle.breaksCompleted >= maxBreaks {
            guard totalSeconds >= workdayAt else { return (cycle, []) }
            return (
                BreakCycle(
                    breaksCompleted: cycle.breaksCompleted,
                    onBreak: false,
                    workdayComplete: true,
                    balanced: cycle.balanced
                ),
                [.workdayComplete, .pause]
            )
        }

        let nextBreakAt = (cycle.breaksCompleted + 1) * segmentSeconds
        guard totalSeconds >= nextBreakAt else { return (cycle, []) }
        return (
            BreakCycle(
                breaksCompleted: cycle.breaksCompleted,
                onBreak: true,
                workdayComplete: false,
                balanced: cycle.balanced
            ),
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
        let totalSeconds = wholeSeconds(total)
        let workdayAt = intervals * segmentSeconds
        if totalSeconds >= workdayAt {
            return BreakCycle(breaksCompleted: maxBreaks, onBreak: false, workdayComplete: true)
        }
        let completed = min(totalSeconds / segmentSeconds, maxBreaks)
        return BreakCycle(breaksCompleted: completed, onBreak: false)
    }

    static func notifyTotal(breaksCompleted: Int, segment: TimeInterval) -> TimeInterval {
        TimeInterval((breaksCompleted + 1) * wholeSeconds(segment))
    }

    private static func wholeSeconds(_ interval: TimeInterval) -> Int {
        max(0, Int(interval.rounded(.down)))
    }
}
