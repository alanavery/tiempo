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

    static func timeInterval(from string: String) -> TimeInterval? {
        let trimmed = string.trimmingCharacters(in: .whitespacesAndNewlines)
        let parts = trimmed.split(separator: ":", omittingEmptySubsequences: false)
        guard parts.count == 3,
              let hours = Int(parts[0]), hours >= 0,
              let minutes = Int(parts[1]), (0..<60).contains(minutes),
              let seconds = Int(parts[2]), (0..<60).contains(seconds)
        else { return nil }
        return TimeInterval(hours * 3600 + minutes * 60 + seconds)
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
