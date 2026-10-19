import XCTest
@testable import Tiempo

final class BreakScheduleTests: XCTestCase {
    private let segment: TimeInterval = 84 * 60

    func testSegmentLengthMatchesTheEightHourExample() throws {
        let length = try XCTUnwrap(
            BreakSchedule.segmentLength(workdayHours: 8, intervals: 5, breakMinutes: 15)
        )
        XCTAssertEqual(length, 84 * 60, accuracy: 0.001)
        XCTAssertEqual(BreakSchedule.totalBreakTime(intervals: 5, breakMinutes: 15), 60 * 60, accuracy: 0.001)
    }

    func testSegmentLengthRejectsBreaksThatDoNotFit() {
        XCTAssertNil(BreakSchedule.segmentLength(workdayHours: 1, intervals: 5, breakMinutes: 30))
        XCTAssertNil(BreakSchedule.segmentLength(workdayHours: 0, intervals: 5, breakMinutes: 15))
        XCTAssertNil(BreakSchedule.segmentLength(workdayHours: 8, intervals: 0, breakMinutes: 15))
    }

    func testBreaksPauseAtEachSegmentBoundary() {
        var cycle = BreakCycle()

        (cycle, _) = expectNoSignal(total: segment - 1, cycle: cycle)
        (cycle, _) = expect(
            total: segment,
            cycle: cycle,
            signals: [.notify, .pause],
            onBreak: true,
            completed: 0
        )

        cycle = BreakCycle(breaksCompleted: 1, onBreak: false)
        (cycle, _) = expectNoSignal(total: 2 * segment - 1, cycle: cycle)
        (cycle, _) = expect(
            total: 2 * segment,
            cycle: cycle,
            signals: [.notify, .pause],
            onBreak: true,
            completed: 1
        )
    }

    func testBreakStaysUntilEndedByTheCaller() {
        let onBreak = BreakCycle(breaksCompleted: 0, onBreak: true)
        let (cycle, signals) = BreakSchedule.advance(
            total: segment + 3_600,
            segment: segment,
            intervals: 5,
            cycle: onBreak
        )
        XCTAssertEqual(cycle, onBreak)
        XCTAssertEqual(signals, [])
    }

    func testWorkdayCompletesAfterTheFinalInterval() {
        let afterLastBreak = BreakCycle(breaksCompleted: 4, onBreak: false)
        let (cycle, signals) = BreakSchedule.advance(
            total: 5 * segment,
            segment: segment,
            intervals: 5,
            cycle: afterLastBreak
        )
        XCTAssertEqual(
            cycle,
            BreakCycle(breaksCompleted: 4, onBreak: false, workdayComplete: true)
        )
        XCTAssertEqual(signals, [.workdayComplete, .pause])
    }

    func testMeetingTimeShortensOnlyTheFinalAlert() throws {
        let segmentLength = try XCTUnwrap(
            BreakSchedule.segmentLength(workdayHours: 8, intervals: 2, breakMinutes: 60)
        )
        XCTAssertEqual(segmentLength, 3.5 * 3600, accuracy: 0.001)

        var cycle = BreakCycle()
        let (atBreak, breakSignals) = BreakSchedule.advance(
            total: 3.5 * 3600,
            segment: segmentLength,
            intervals: 2,
            meeting: 3600,
            cycle: cycle
        )
        XCTAssertEqual(breakSignals, [.notify, .pause])
        XCTAssertTrue(atBreak.onBreak)

        cycle = BreakCycle(breaksCompleted: 1, onBreak: false)
        let (beforeFinal, none) = BreakSchedule.advance(
            total: 6 * 3600 - 1,
            segment: segmentLength,
            intervals: 2,
            meeting: 3600,
            cycle: cycle
        )
        XCTAssertEqual(none, [])
        XCTAssertEqual(beforeFinal, cycle)

        let (complete, finalSignals) = BreakSchedule.advance(
            total: 6 * 3600,
            segment: segmentLength,
            intervals: 2,
            meeting: 3600,
            cycle: cycle
        )
        XCTAssertEqual(finalSignals, [.workdayComplete, .pause])
        XCTAssertTrue(complete.workdayComplete)
    }

    func testPhaseHonorsMeetingTimeForWorkdayComplete() {
        let segmentLength: TimeInterval = 3.5 * 3600
        XCTAssertEqual(
            BreakSchedule.phase(
                total: 3.5 * 3600,
                segment: segmentLength,
                intervals: 2,
                meeting: 3600
            ),
            BreakCycle(breaksCompleted: 1, onBreak: false)
        )
        XCTAssertEqual(
            BreakSchedule.phase(
                total: 6 * 3600,
                segment: segmentLength,
                intervals: 2,
                meeting: 3600
            ),
            BreakCycle(breaksCompleted: 1, onBreak: false, workdayComplete: true)
        )
    }

    func testWorkdayCompleteDoesNotSignalAgain() {
        let complete = BreakCycle(breaksCompleted: 4, onBreak: false, workdayComplete: true)
        let (cycle, signals) = BreakSchedule.advance(
            total: 5 * segment + 100,
            segment: segment,
            intervals: 5,
            cycle: complete
        )
        XCTAssertEqual(cycle, complete)
        XCTAssertEqual(signals, [])
    }

    func testRepeatingTheSameTotalDoesNotSignalAgain() {
        let (cycle, signals) = BreakSchedule.advance(
            total: segment,
            segment: segment,
            intervals: 5,
            cycle: BreakCycle()
        )
        XCTAssertEqual(signals, [.notify, .pause])
        let (_, again) = BreakSchedule.advance(
            total: segment,
            segment: segment,
            intervals: 5,
            cycle: cycle
        )
        XCTAssertEqual(again, [])
    }

    func testPhaseLocatesCompletedSegmentsAndWorkday() {
        XCTAssertEqual(
            BreakSchedule.phase(total: segment - 1, segment: segment, intervals: 5),
            BreakCycle()
        )
        XCTAssertEqual(
            BreakSchedule.phase(total: segment, segment: segment, intervals: 5),
            BreakCycle(breaksCompleted: 1, onBreak: false)
        )
        XCTAssertEqual(
            BreakSchedule.phase(total: 2 * segment + 30, segment: segment, intervals: 5),
            BreakCycle(breaksCompleted: 2, onBreak: false)
        )
        XCTAssertEqual(
            BreakSchedule.phase(total: 5 * segment, segment: segment, intervals: 5),
            BreakCycle(breaksCompleted: 4, onBreak: false, workdayComplete: true)
        )
    }

    private func expectNoSignal(total: TimeInterval, cycle: BreakCycle) -> (BreakCycle, [BreakSignal]) {
        let result = BreakSchedule.advance(total: total, segment: segment, intervals: 5, cycle: cycle)
        XCTAssertEqual(result.1, [])
        XCTAssertEqual(result.0, cycle)
        return result
    }

    private func expect(
        total: TimeInterval,
        cycle: BreakCycle,
        signals: [BreakSignal],
        onBreak: Bool,
        completed: Int
    ) -> (BreakCycle, [BreakSignal]) {
        let result = BreakSchedule.advance(total: total, segment: segment, intervals: 5, cycle: cycle)
        XCTAssertEqual(result.1, signals)
        XCTAssertEqual(result.0, BreakCycle(breaksCompleted: completed, onBreak: onBreak))
        return result
    }
}
