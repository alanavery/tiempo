import SwiftData
import XCTest
@testable import Tiempo

@MainActor
final class TimeTrackerTests: XCTestCase {
    func testStartingSecondTaskPausesTheFirst() throws {
        let context = try makeContext()
        let project = Project(name: "Work")
        context.insert(project)
        let taskA = TaskItem(name: "Task 1", project: project)
        let taskB = TaskItem(name: "Task 2", project: project)
        context.insert(taskA)
        context.insert(taskB)

        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let switchTime = start.addingTimeInterval(12)

        try TimeTracker.start(taskA, at: start, in: context)
        try TimeTracker.start(taskB, at: switchTime, in: context)

        XCTAssertNil(taskA.runningSince)
        XCTAssertFalse(taskA.isRunning)
        XCTAssertEqual(taskB.runningSince, switchTime)
        XCTAssertTrue(taskB.isRunning)
        XCTAssertEqual(taskA.accumulated, 12, accuracy: 0.001)
        XCTAssertEqual(TimeTracker.elapsed(taskA, at: switchTime), 12, accuracy: 0.001)
        XCTAssertEqual(
            TimeTracker.elapsed(taskB, at: switchTime.addingTimeInterval(8)),
            8,
            accuracy: 0.001
        )
    }

    func testElapsedIncludesRunningSpanThenHoldsAfterPause() throws {
        let context = try makeContext()
        let project = Project(name: "Work")
        context.insert(project)
        let task = TaskItem(name: "Task 1", project: project)
        context.insert(task)

        let start = Date(timeIntervalSince1970: 1_700_000_000)
        try TimeTracker.start(task, at: start, in: context)

        let pauseTime = start.addingTimeInterval(5)
        XCTAssertEqual(TimeTracker.elapsed(task, at: pauseTime), 5, accuracy: 0.001)

        TimeTracker.pause(task, at: pauseTime)
        XCTAssertNil(task.runningSince)
        XCTAssertEqual(task.accumulated, 5, accuracy: 0.001)
        XCTAssertEqual(
            TimeTracker.elapsed(task, at: pauseTime.addingTimeInterval(30)),
            5,
            accuracy: 0.001
        )
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
