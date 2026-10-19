import SwiftUI

struct MeetingTimeSheet: View {
    @Environment(\.dismiss) private var dismiss
    var onConfirm: (Double) -> Void

    @State private var hours: Int
    @State private var minutes: Int

    init(meetingHours: Double = 0, onConfirm: @escaping (Double) -> Void) {
        self.onConfirm = onConfirm
        let totalMinutes = max(0, Int((meetingHours * 60).rounded()))
        _hours = State(initialValue: min(24, totalMinutes / 60))
        _minutes = State(initialValue: totalMinutes % 60)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Meeting Time")
                .font(.headline)

            Text("Subtract meetings from today's tracked workday. Interval and break lengths stay the same.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            Stepper(value: $hours, in: 0...24) {
                Text("Meeting hours: \(hours)")
            }
            .accessibilityIdentifier("meeting-hours")

            Stepper(value: $minutes, in: 0...59) {
                Text("Meeting minutes: \(minutes)")
            }
            .accessibilityIdentifier("meeting-minutes")
            .disabled(hours >= 24)

            HStack {
                Spacer()
                Button("Cancel", role: .cancel) {
                    dismiss()
                }
                Button("Reset", role: .destructive, action: confirm)
                    .keyboardShortcut(.defaultAction)
                    .accessibilityIdentifier("confirm-meeting-time")
            }
        }
        .padding(20)
        .frame(width: 360)
        .onChange(of: hours) { _, newValue in
            if newValue >= 24 {
                minutes = 0
            }
        }
    }

    private func confirm() {
        let clampedHours = min(24, max(0, hours))
        let clampedMinutes = clampedHours >= 24 ? 0 : min(59, max(0, minutes))
        onConfirm(Double(clampedHours) + Double(clampedMinutes) / 60)
        dismiss()
    }
}
