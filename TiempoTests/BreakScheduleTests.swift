import XCTest
@testable import Tiempo

final class BreakScheduleTests: XCTestCase {
    private let hour: TimeInterval = 3600
    private let tenMinutes: TimeInterval = 600

    func testBreaksMatchTheHourAndTenMinuteExample() {
        var cycle = BreakCycle()

        (cycle, _) = expectNoSignal(total: hour - 1, cycle: cycle)
        (cycle, _) = expect(total: hour, cycle: cycle, signals: [.notify], onBreak: true, completed: 0)
        (cycle, _) = expectNoSignal(total: hour + tenMinutes - 1, cycle: cycle)
        (cycle, _) = expect(total: hour + tenMinutes, cycle: cycle, signals: [.pause], onBreak: false, completed: 1)

        (cycle, _) = expectNoSignal(total: 2 * hour + tenMinutes - 1, cycle: cycle)
        (cycle, _) = expect(total: 2 * hour + tenMinutes, cycle: cycle, signals: [.notify], onBreak: true, completed: 1)
        (cycle, _) = expect(total: 2 * hour + 2 * tenMinutes, cycle: cycle, signals: [.pause], onBreak: false, completed: 2)

        (cycle, _) = expect(total: 3 * hour + 2 * tenMinutes, cycle: cycle, signals: [.notify], onBreak: true, completed: 2)
    }

    func testRepeatingTheSameTotalDoesNotSignalAgain() {
        let (cycle, signals) = BreakSchedule.advance(total: hour, interval: hour, breakDuration: tenMinutes, cycle: BreakCycle())
        XCTAssertEqual(signals, [.notify])
        let (_, again) = BreakSchedule.advance(total: hour, interval: hour, breakDuration: tenMinutes, cycle: cycle)
        XCTAssertEqual(again, [])
    }

    func testPhaseLocatesTheExampleBoundaries() {
        XCTAssertEqual(
            BreakSchedule.phase(total: hour, interval: hour, breakDuration: tenMinutes),
            BreakCycle(breaksCompleted: 0, onBreak: true)
        )
        XCTAssertEqual(
            BreakSchedule.phase(total: hour + tenMinutes, interval: hour, breakDuration: tenMinutes),
            BreakCycle(breaksCompleted: 1, onBreak: false)
        )
        XCTAssertEqual(
            BreakSchedule.phase(total: 2 * hour + tenMinutes, interval: hour, breakDuration: tenMinutes),
            BreakCycle(breaksCompleted: 1, onBreak: true)
        )
        XCTAssertEqual(
            BreakSchedule.phase(total: 3 * hour + 2 * tenMinutes, interval: hour, breakDuration: tenMinutes),
            BreakCycle(breaksCompleted: 2, onBreak: true)
        )
    }

    private func expectNoSignal(total: TimeInterval, cycle: BreakCycle) -> (BreakCycle, [BreakSignal]) {
        let result = BreakSchedule.advance(total: total, interval: hour, breakDuration: tenMinutes, cycle: cycle)
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
        let result = BreakSchedule.advance(total: total, interval: hour, breakDuration: tenMinutes, cycle: cycle)
        XCTAssertEqual(result.1, signals)
        XCTAssertEqual(result.0, BreakCycle(breaksCompleted: completed, onBreak: onBreak))
        return result
    }
}
