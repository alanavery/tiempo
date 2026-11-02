import SwiftData
import XCTest
@testable import Tiempo

@MainActor
final class MeetingSyncTests: XCTestCase {
    func testStartsMeetingsAndStealsFocus() throws {
        let source = MockCalendarSource()
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let sync = MeetingSync(source: source, defaults: defaults)
        sync.isEnabled = true

        let context = try makeContext()
        let project = Project(name: "Work")
        context.insert(project)
        let coding = TaskItem(name: "Coding", project: project)
        context.insert(coding)
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        try TimeTracker.start(coding, at: start, in: context)
        try context.save()

        source.events = [
            CalendarEventSnapshot(title: "Standup", start: start, end: start.addingTimeInterval(1800))
        ]

        sync.tick(tasks: [coding], at: start.addingTimeInterval(60), in: context, endingBreak: {})

        let tasks = try context.fetch(FetchDescriptor<TaskItem>())
        let meetings = try XCTUnwrap(tasks.first { $0.name == "Meetings" })
        XCTAssertNotNil(meetings.runningSince)
        XCTAssertNil(coding.runningSince)
        XCTAssertTrue(sync.isInMeeting)
        XCTAssertEqual(sync.activeEventTitle, "Standup")
    }

    func testResumesPreviousTaskWhenMeetingEnds() throws {
        let source = MockCalendarSource()
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let sync = MeetingSync(source: source, defaults: defaults)
        sync.isEnabled = true

        let context = try makeContext()
        let project = Project(name: "Work")
        context.insert(project)
        let coding = TaskItem(name: "Coding", project: project)
        context.insert(coding)
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        try TimeTracker.start(coding, at: start, in: context)
        try context.save()

        source.events = [
            CalendarEventSnapshot(title: "Standup", start: start, end: start.addingTimeInterval(1800))
        ]
        sync.tick(tasks: [coding], at: start.addingTimeInterval(60), in: context, endingBreak: {})

        var tasks = try context.fetch(FetchDescriptor<TaskItem>())
        source.events = []
        sync.tick(tasks: tasks, at: start.addingTimeInterval(1900), in: context, endingBreak: {})

        tasks = try context.fetch(FetchDescriptor<TaskItem>())
        let meetings = try XCTUnwrap(tasks.first { $0.name == "Meetings" })
        XCTAssertNil(meetings.runningSince)
        XCTAssertNotNil(coding.runningSince)
        XCTAssertFalse(sync.isInMeeting)
    }

    func testSkipsAllDayStyleAbsenceWhenNoTimedEvent() throws {
        let source = MockCalendarSource()
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        let sync = MeetingSync(source: source, defaults: defaults)
        sync.isEnabled = true

        let context = try makeContext()
        let project = Project(name: "Work")
        context.insert(project)
        let coding = TaskItem(name: "Coding", project: project)
        context.insert(coding)
        try TimeTracker.start(coding, at: .now, in: context)
        try context.save()

        source.events = []
        sync.tick(tasks: [coding], at: .now, in: context, endingBreak: {})

        XCTAssertFalse(sync.isInMeeting)
        XCTAssertNotNil(coding.runningSince)
        XCTAssertEqual(try context.fetch(FetchDescriptor<TaskItem>()).count, 1)
    }

    func testBreakPauseExcludesMeetingsTaskWhileInMeeting() throws {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        defaults.set(2.0 / 3600.0, forKey: "break.workdayHours")
        defaults.set(2, forKey: "break.intervals")
        defaults.set(0.0, forKey: "break.breakMinutes")
        let monitor = BreakMonitor(defaults: defaults)

        let context = try makeContext()
        let project = Project(name: "Work")
        context.insert(project)
        let meetings = TaskItem(name: "Meetings", project: project)
        let coding = TaskItem(name: "Coding", project: project)
        context.insert(meetings)
        context.insert(coding)
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        try TimeTracker.start(meetings, at: start, in: context)
        try context.save()

        monitor.tick(
            tasks: [meetings, coding],
            at: start.addingTimeInterval(1),
            in: context,
            excludingFromPause: meetings.persistentModelID
        )

        XCTAssertTrue(monitor.cycle.onBreak)
        XCTAssertNotNil(meetings.runningSince)
    }

    private func makeContext() throws -> ModelContext {
        let configuration = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Schema([Project.self, TaskItem.self]),
            configurations: [configuration]
        )
        return ModelContext(container)
    }
}

@MainActor
private final class MockCalendarSource: CalendarEventSource {
    var authorizationGranted = true
    var events: [CalendarEventSnapshot] = []

    func requestAccess() async -> Bool {
        authorizationGranted = true
        return true
    }

    func timedEvents(on calendarNamed: String, spanning date: Date) -> [CalendarEventSnapshot] {
        events.filter { $0.start <= date && date < $0.end }
    }
}
