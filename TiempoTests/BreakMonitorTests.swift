import SwiftData
import XCTest
@testable import Tiempo

@MainActor
final class BreakMonitorTests: XCTestCase {
    func testPausingAtABreakKeepsProjectsAndTasks() throws {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        defaults.set(2.0 / 3600.0, forKey: "break.workdayHours")
        defaults.set(2, forKey: "break.intervals")
        defaults.set(0.0, forKey: "break.breakMinutes")
        let monitor = BreakMonitor(defaults: defaults)
        XCTAssertEqual(monitor.segmentLength ?? 0, 1, accuracy: 0.001)

        let context = try makeContext()
        let project = Project(name: "Work")
        context.insert(project)
        let taskA = TaskItem(name: "Task 1", project: project)
        let taskB = TaskItem(name: "Task 2", project: project)
        context.insert(taskA)
        context.insert(taskB)
        try context.save()

        let start = Date(timeIntervalSince1970: 1_700_000_000)
        try TimeTracker.start(taskA, at: start, in: context)
        try context.save()

        monitor.tick(tasks: [taskA, taskB], at: start.addingTimeInterval(1), in: context)

        let projects = try context.fetch(FetchDescriptor<Project>())
        let tasks = try context.fetch(FetchDescriptor<TaskItem>())
        XCTAssertEqual(projects.count, 1)
        XCTAssertEqual(projects.first?.name, "Work")
        XCTAssertEqual(tasks.count, 2)
        XCTAssertNil(taskA.runningSince)
        XCTAssertTrue(monitor.cycle.onBreak)
        XCTAssertEqual(taskA.project?.persistentModelID, project.persistentModelID)
        XCTAssertEqual(taskB.project?.persistentModelID, project.persistentModelID)
    }

    func testWorkdayCompletionPausesAndBalanceSplitsBreakTime() throws {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        defaults.set(1.0, forKey: "break.workdayHours")
        defaults.set(2, forKey: "break.intervals")
        defaults.set(15.0, forKey: "break.breakMinutes")
        defaults.set(1, forKey: "break.completed")
        defaults.set(false, forKey: "break.onBreak")
        let day = BreakMonitor(defaults: defaults)
        XCTAssertEqual(day.segmentLength ?? 0, 22.5 * 60, accuracy: 0.001)
        XCTAssertEqual(day.totalBreakTime, 15 * 60, accuracy: 0.001)
        XCTAssertEqual(day.cycle.breaksCompleted, 1)

        let context = try makeContext()
        let project = Project(name: "Work")
        context.insert(project)
        let taskA = TaskItem(name: "Task 1", project: project)
        let taskB = TaskItem(name: "Task 2", project: project)
        context.insert(taskA)
        context.insert(taskB)
        taskA.accumulated = 22.5 * 60
        taskB.accumulated = 22.5 * 60
        try context.save()

        day.tick(tasks: [taskA, taskB], at: .now, in: context)

        XCTAssertTrue(day.cycle.workdayComplete)
        XCTAssertTrue(day.canBalance)

        day.balance(tasks: [taskA, taskB], in: context)

        XCTAssertEqual(taskA.accumulated, 30 * 60, accuracy: 0.001)
        XCTAssertEqual(taskB.accumulated, 30 * 60, accuracy: 0.001)
        XCTAssertEqual(taskA.accumulated + taskB.accumulated, day.workdayLength, accuracy: 0.001)
        XCTAssertTrue(day.cycle.balanced)
        XCTAssertFalse(day.canBalance)
    }

    func testStartingATimerEndsTheBreak() throws {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        defaults.set(8.0, forKey: "break.workdayHours")
        defaults.set(5, forKey: "break.intervals")
        defaults.set(15.0, forKey: "break.breakMinutes")
        defaults.set(true, forKey: "break.onBreak")
        defaults.set(0, forKey: "break.completed")
        let monitor = BreakMonitor(defaults: defaults)
        XCTAssertTrue(monitor.cycle.onBreak)

        monitor.endBreak()

        XCTAssertFalse(monitor.cycle.onBreak)
        XCTAssertEqual(monitor.cycle.breaksCompleted, 1)
        XCTAssertFalse(defaults.bool(forKey: "break.onBreak"))
        XCTAssertEqual(defaults.integer(forKey: "break.completed"), 1)
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
