import SwiftUI

struct BreakSettingsSheet: View {
    @Environment(\.dismiss) private var dismiss
    var monitor: BreakMonitor

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Breaks")
                .font(.headline)

            Stepper(value: intervalHours, in: 0...99) {
                Text("Interval hours: \(intervalHours.wrappedValue)")
            }
            Stepper(value: intervalMinutes, in: 0...59) {
                Text("Interval minutes: \(intervalMinutes.wrappedValue)")
            }
            Stepper(value: breakHours, in: 0...99) {
                Text("Break hours: \(breakHours.wrappedValue)")
            }
            Stepper(value: breakMinutes, in: 0...59) {
                Text("Break minutes: \(breakMinutes.wrappedValue)")
            }

            Text(summary)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

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
        guard monitor.interval > 0 else {
            return "Set an interval to be prompted for breaks."
        }
        let first = BreakSchedule.notifyTotal(breaksCompleted: 0, interval: monitor.interval, breakDuration: monitor.breakDuration)
        let second = BreakSchedule.notifyTotal(breaksCompleted: 1, interval: monitor.interval, breakDuration: monitor.breakDuration)
        let third = BreakSchedule.notifyTotal(breaksCompleted: 2, interval: monitor.interval, breakDuration: monitor.breakDuration)
        return "Breaks when the total reaches \(DurationFormat.string(from: first)), \(DurationFormat.string(from: second)), and \(DurationFormat.string(from: third))."
    }

    private var intervalHours: Binding<Int> {
        durationComponent(\.interval, unit: 3600)
    }

    private var intervalMinutes: Binding<Int> {
        durationComponent(\.interval, unit: 60)
    }

    private var breakHours: Binding<Int> {
        durationComponent(\.breakDuration, unit: 3600)
    }

    private var breakMinutes: Binding<Int> {
        durationComponent(\.breakDuration, unit: 60)
    }

    private func durationComponent(_ keyPath: ReferenceWritableKeyPath<BreakMonitor, TimeInterval>, unit: Int) -> Binding<Int> {
        Binding {
            component(of: monitor[keyPath: keyPath], unit: unit)
        } set: { newValue in
            monitor[keyPath: keyPath] = replacing(monitor[keyPath: keyPath], unit: unit, with: newValue)
        }
    }

    private func component(of duration: TimeInterval, unit: Int) -> Int {
        let seconds = max(0, Int(duration))
        if unit == 3600 {
            return seconds / 3600
        }
        return (seconds % 3600) / 60
    }

    private func replacing(_ duration: TimeInterval, unit: Int, with value: Int) -> TimeInterval {
        let seconds = max(0, Int(duration))
        let hours = seconds / 3600
        let minutes = (seconds % 3600) / 60
        if unit == 3600 {
            return TimeInterval(value * 3600 + minutes * 60)
        }
        return TimeInterval(hours * 3600 + value * 60)
    }
}
