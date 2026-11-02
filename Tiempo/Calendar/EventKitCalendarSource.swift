import EventKit
import Foundation

@MainActor
final class EventKitCalendarSource: CalendarEventSource {
    private let store = EKEventStore()
    private var cachedEvents: [CalendarEventSnapshot] = []
    private var cachedCalendarName: String?
    private var cachedDayStart: Date?
    private var lastFetch: Date?

    var authorizationGranted: Bool {
        EKEventStore.authorizationStatus(for: .event) == .fullAccess
    }

    func requestAccess() async -> Bool {
        do {
            return try await store.requestFullAccessToEvents()
        } catch {
            return false
        }
    }

    func timedEvents(on calendarNamed: String, spanning date: Date) -> [CalendarEventSnapshot] {
        refreshIfNeeded(calendarNamed: calendarNamed, around: date)
        return cachedEvents.filter { $0.start <= date && date < $0.end }
    }

    private func refreshIfNeeded(calendarNamed: String, around date: Date) {
        let dayStart = Calendar.current.startOfDay(for: date)
        let stale = lastFetch.map { date.timeIntervalSince($0) >= 60 } ?? true
        let dayChanged = cachedDayStart != dayStart
        let calendarChanged = cachedCalendarName != calendarNamed
        guard stale || dayChanged || calendarChanged || cachedEvents.isEmpty else { return }
        guard authorizationGranted else {
            cachedEvents = []
            cachedCalendarName = calendarNamed
            cachedDayStart = dayStart
            lastFetch = date
            return
        }

        let calendars = store.calendars(for: .event).filter { $0.title == calendarNamed }
        guard !calendars.isEmpty else {
            cachedEvents = []
            cachedCalendarName = calendarNamed
            cachedDayStart = dayStart
            lastFetch = date
            return
        }

        let dayEnd = Calendar.current.date(byAdding: .day, value: 1, to: dayStart) ?? date
        let predicate = store.predicateForEvents(withStart: dayStart, end: dayEnd, calendars: calendars)
        cachedEvents = store.events(matching: predicate)
            .filter { !$0.isAllDay }
            .map {
                CalendarEventSnapshot(
                    title: $0.title ?? "Meeting",
                    start: $0.startDate,
                    end: $0.endDate
                )
            }
            .sorted { $0.start < $1.start }
        cachedCalendarName = calendarNamed
        cachedDayStart = dayStart
        lastFetch = date
    }
}
