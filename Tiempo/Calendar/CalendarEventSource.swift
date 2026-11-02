import Foundation

struct CalendarEventSnapshot: Equatable {
    var title: String
    var start: Date
    var end: Date
}

@MainActor
protocol CalendarEventSource: AnyObject {
    var authorizationGranted: Bool { get }
    func requestAccess() async -> Bool
    func timedEvents(on calendarNamed: String, spanning date: Date) -> [CalendarEventSnapshot]
}
