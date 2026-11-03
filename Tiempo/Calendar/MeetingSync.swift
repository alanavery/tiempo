import Foundation
import SwiftData
import UserNotifications

@MainActor
@Observable
final class MeetingSync {
    static let taskName = "Meetings"
    static let calendarName = "Verndale"

    private(set) var isInMeeting = false
    private(set) var activeEventTitle: String?
    private(set) var authorization: CalendarAuthorization

    var isEnabled: Bool {
        didSet { defaults.set(isEnabled, forKey: Keys.enabled) }
    }

    private let source: CalendarEventSource
    private let defaults: UserDefaults
    private var previousTaskID: PersistentIdentifier?
    private var meetingsTaskID: PersistentIdentifier?
    private var dismissedEventKey: String?

    init(
        source: CalendarEventSource = EventKitCalendarSource(),
        defaults: UserDefaults = .standard
    ) {
        self.source = source
        self.defaults = defaults
        authorization = source.authorization
        if defaults.object(forKey: Keys.enabled) == nil {
            isEnabled = false
        } else {
            isEnabled = defaults.bool(forKey: Keys.enabled)
        }
    }

    var authorizationGranted: Bool {
        authorization.isGranted
    }

    var protectedTaskID: PersistentIdentifier? {
        isInMeeting ? meetingsTaskID : nil
    }

    func requestAccess() async {
        _ = await source.requestAccess()
        authorization = source.authorization
    }

    func refreshAuthorization() {
        authorization = source.authorization
    }

    func tick(tasks: [TaskItem], at date: Date = .now, in context: ModelContext, endingBreak: () -> Void) {
        refreshAuthorization()
        guard isEnabled, authorizationGranted else {
            leaveMeetingIfNeeded(tasks: tasks, at: date, in: context, endingBreak: endingBreak, notify: false)
            return
        }

        let current = source.timedEvents(on: Self.calendarName, spanning: date).first
        if let current {
            enterOrStayInMeeting(
                event: current,
                tasks: tasks,
                at: date,
                in: context,
                endingBreak: endingBreak
            )
        } else {
            dismissedEventKey = nil
            leaveMeetingIfNeeded(tasks: tasks, at: date, in: context, endingBreak: endingBreak, notify: true)
        }
    }

    func meetingsTask(in tasks: [TaskItem]) -> TaskItem? {
        guard let meetingsTaskID else {
            return tasks.first { $0.name == Self.taskName }
        }
        return tasks.first { $0.persistentModelID == meetingsTaskID }
            ?? tasks.first { $0.name == Self.taskName }
    }

    private func enterOrStayInMeeting(
        event: CalendarEventSnapshot,
        tasks: [TaskItem],
        at date: Date,
        in context: ModelContext,
        endingBreak: () -> Void
    ) {
        let key = eventKey(event)
        if dismissedEventKey == key {
            return
        }

        guard let meetings = ensureMeetingsTask(among: tasks, in: context) else { return }
        meetingsTaskID = meetings.persistentModelID

        let entering = !isInMeeting
        if entering {
            let previous = tasks.first {
                $0.persistentModelID != meetings.persistentModelID && $0.runningSince != nil
            }
            previousTaskID = previous?.persistentModelID
            activeEventTitle = event.title
            isInMeeting = true
            endingBreak()
            try? TimeTracker.start(meetings, at: date, in: context)
            try? context.save()
            notify(
                title: "Meeting started",
                body: "Switched to \(Self.taskName) for \(event.title)."
            )
            return
        }

        activeEventTitle = event.title
        guard meetings.runningSince == nil else { return }

        dismissedEventKey = key
        previousTaskID = nil
        activeEventTitle = nil
        isInMeeting = false
    }

    private func eventKey(_ event: CalendarEventSnapshot) -> String {
        "\(event.title)|\(event.start.timeIntervalSince1970)"
    }

    private func leaveMeetingIfNeeded(
        tasks: [TaskItem],
        at date: Date,
        in context: ModelContext,
        endingBreak: () -> Void,
        notify shouldNotify: Bool
    ) {
        guard isInMeeting else { return }
        let meetings = meetingsTask(in: tasks)
        if let meetings, meetings.runningSince != nil {
            TimeTracker.pause(meetings, at: date)
        }

        let previous = previousTaskID.flatMap { id in
            tasks.first { $0.persistentModelID == id }
        }
        previousTaskID = nil
        let eventTitle = activeEventTitle
        activeEventTitle = nil
        isInMeeting = false
        meetingsTaskID = meetings?.persistentModelID

        if let previous {
            endingBreak()
            try? TimeTracker.start(previous, at: date, in: context)
        }
        try? context.save()

        guard shouldNotify else { return }
        if let previous {
            notify(
                title: "Meeting ended",
                body: "Resumed \(previous.name)."
            )
        } else if let eventTitle {
            notify(
                title: "Meeting ended",
                body: "\(Self.taskName) paused after \(eventTitle)."
            )
        } else {
            notify(
                title: "Meeting ended",
                body: "\(Self.taskName) paused."
            )
        }
    }

    private func ensureMeetingsTask(among tasks: [TaskItem], in context: ModelContext) -> TaskItem? {
        if let existing = meetingsTask(in: tasks) {
            return existing
        }
        let projects = (try? context.fetch(
            FetchDescriptor<Project>(sortBy: [
                SortDescriptor(\.sortIndex),
                SortDescriptor(\.createdAt),
            ])
        )) ?? []
        guard let project = projects.first else { return nil }
        let maxIndex = tasks.map(\.sortIndex).max() ?? -1
        let task = TaskItem(name: Self.taskName, project: project, sortIndex: maxIndex + 1)
        context.insert(task)
        try? context.save()
        return task
    }

    private func notify(title: String, body: String) {
        requestNotificationPermission()
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: nil)
        Task {
            try? await UNUserNotificationCenter.current().add(request)
        }
    }

    private func requestNotificationPermission() {
        Task {
            _ = try? await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound])
        }
    }

    private enum Keys {
        static let enabled = "calendar.meetingSyncEnabled"
    }
}
