import Foundation

enum DurationFormat {
    static func string(from interval: TimeInterval) -> String {
        let parts = parts(of: interval)
        return String(format: "%02d:%02d:%02d", parts.hours, parts.minutes, parts.seconds)
    }

    static func menuBarString(from interval: TimeInterval) -> String? {
        let parts = parts(of: interval)
        guard parts.hours > 0 || parts.minutes > 0 || parts.seconds > 0 else { return nil }
        return "\(parts.hours):" + String(format: "%02d", parts.minutes)
    }

    private static func parts(of interval: TimeInterval) -> (hours: Int, minutes: Int, seconds: Int) {
        let totalSeconds = max(0, Int(interval))
        return (
            totalSeconds / 3600,
            (totalSeconds % 3600) / 60,
            totalSeconds % 60
        )
    }
}
