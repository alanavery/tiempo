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
    static func advance(
        total: TimeInterval,
        interval: TimeInterval,
        breakDuration: TimeInterval,
        cycle: BreakCycle
    ) -> (BreakCycle, [BreakSignal]) {
        let totalSeconds = wholeSeconds(total)
        let intervalSeconds = wholeSeconds(interval)
        guard intervalSeconds > 0 else { return (cycle, []) }
        let breakSeconds = wholeSeconds(breakDuration)

        if cycle.onBreak {
            let pauseAt = (cycle.breaksCompleted + 1) * (intervalSeconds + breakSeconds)
            guard totalSeconds >= pauseAt else { return (cycle, []) }
            return (BreakCycle(breaksCompleted: cycle.breaksCompleted + 1, onBreak: false), [.pause])
        }

        let notifyAt = (cycle.breaksCompleted + 1) * intervalSeconds + cycle.breaksCompleted * breakSeconds
        guard totalSeconds >= notifyAt else { return (cycle, []) }
        if breakSeconds == 0 || totalSeconds >= notifyAt + breakSeconds {
            let signals: [BreakSignal] = breakSeconds == 0 ? [.notify, .pause] : [.pause]
            return (BreakCycle(breaksCompleted: cycle.breaksCompleted + 1, onBreak: false), signals)
        }
        return (BreakCycle(breaksCompleted: cycle.breaksCompleted, onBreak: true), [.notify])
    }

    static func phase(
        total: TimeInterval,
        interval: TimeInterval,
        breakDuration: TimeInterval
    ) -> BreakCycle? {
        let totalSeconds = wholeSeconds(total)
        let intervalSeconds = wholeSeconds(interval)
        guard intervalSeconds > 0 else { return nil }
        let breakSeconds = wholeSeconds(breakDuration)
        if totalSeconds < intervalSeconds {
            return BreakCycle()
        }
        if breakSeconds == 0 {
            return BreakCycle(breaksCompleted: totalSeconds / intervalSeconds, onBreak: false)
        }
        let since = totalSeconds - intervalSeconds
        let cycle = breakSeconds + intervalSeconds
        let index = since / cycle
        let offset = since - index * cycle
        if offset < breakSeconds {
            return BreakCycle(breaksCompleted: index, onBreak: true)
        }
        return BreakCycle(breaksCompleted: index + 1, onBreak: false)
    }

    static func notifyTotal(breaksCompleted: Int, interval: TimeInterval, breakDuration: TimeInterval) -> TimeInterval {
        let intervalSeconds = wholeSeconds(interval)
        let breakSeconds = wholeSeconds(breakDuration)
        return TimeInterval((breaksCompleted + 1) * intervalSeconds + breaksCompleted * breakSeconds)
    }

    private static func wholeSeconds(_ interval: TimeInterval) -> Int {
        max(0, Int(interval.rounded(.down)))
    }
}
