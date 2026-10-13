import SwiftUI

struct BreakSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    var monitor: BreakMonitor

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Breaks")
                .font(.headline)

            Stepper(value: workdayHours, in: 0...24) {
                Text("Workday hours: \(workdayHours.wrappedValue)")
            }
            .accessibilityIdentifier("workday-hours")

            Stepper(value: intervals, in: 0...20) {
                Text("Intervals: \(intervals.wrappedValue)")
            }
            .accessibilityIdentifier("intervals")

            Stepper(value: breakMinutes, in: 0...180) {
                Text("Break minutes: \(breakMinutes.wrappedValue)")
            }
            .accessibilityIdentifier("break-minutes")

            Text(summary)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityIdentifier("break-summary")

            HStack {
                Spacer()
                Button("Done") { dismiss() }
                    .keyboardShortcut(.defaultAction)
            }
        }
        .padding(20)
        .frame(width: 360)
    }

    private var summary: String {
        guard let segment = monitor.segmentLength else {
            return "Set a workday, at least one interval, and break lengths that fit inside the workday."
        }
        let segmentMinutes = Int((segment / 60).rounded(.down))
        let breakCount = max(0, monitor.intervals - 1)
        if breakCount == 0 {
            return "One \(segmentMinutes)-minute work segment with no breaks."
        }
        return "\(monitor.intervals) segments of \(segmentMinutes) minutes, with \(breakCount) breaks of \(Int(monitor.breakMinutes.rounded(.down))) minutes. Timers pause when a break starts."
    }

    private var workdayHours: Binding<Int> {
        Binding {
            max(0, Int(monitor.workdayHours.rounded(.down)))
        } set: { newValue in
            monitor.workdayHours = Double(newValue)
        }
    }

    private var intervals: Binding<Int> {
        Binding {
            monitor.intervals
        } set: { newValue in
            monitor.intervals = newValue
        }
    }

    private var breakMinutes: Binding<Int> {
        Binding {
            max(0, Int(monitor.breakMinutes.rounded(.down)))
        } set: { newValue in
            monitor.breakMinutes = Double(newValue)
        }
    }
}
