import SwiftData
import XCTest
@testable import Tiempo

@MainActor
final class BreakMonitorTests: XCTestCase {
    func testPausingAtABreakKeepsProjectsAndTasks() throws {
        let defaults = UserDefaults(suiteName: UUID().uuidString)!
        defaults.set(1.0, forKey: "break.interval")
        defaults.set(0.0, forKey: "break.duration")
        let monitor = BreakMonitor(defaults: defaults)

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
        XCTAssertEqual(taskA.project?.persistentModelID, project.persistentModelID)
        XCTAssertEqual(taskB.project?.persistentModelID, project.persistentModelID)
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
