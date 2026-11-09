import SwiftUI

struct EditTimeSheet: View {
    @Environment(\.dismiss) private var dismiss
    var onSave: (TimeInterval) -> Void

    @State private var text: String
    @FocusState private var textFocused: Bool

    init(elapsed: TimeInterval, onSave: @escaping (TimeInterval) -> Void) {
        self.onSave = onSave
        _text = State(initialValue: DurationFormat.decimalHoursString(from: elapsed))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Edit Time")
                .font(.headline)

            TextField("0", text: $text)
                .textFieldStyle(.roundedBorder)
                .font(.body.monospacedDigit())
                .focused($textFocused)
                .accessibilityIdentifier("edit-time")
                .onSubmit(save)

            Text(helpText)
                .font(.caption)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)

            HStack {
                Spacer()
                Button("Cancel", role: .cancel) {
                    dismiss()
                }
                Button("Save", action: save)
                    .keyboardShortcut(.defaultAction)
                    .disabled(parsed == nil)
                    .accessibilityIdentifier("save-edit-time")
            }
        }
        .padding(20)
        .frame(width: 320)
        .onAppear { textFocused = true }
    }

    private var helpText: String {
        if let parsed {
            return "Saves as \(DurationFormat.string(from: parsed)). Use hours, like 3.75 for 3 hours 45 minutes."
        }
        return "Use hours, like 3.75 for 3 hours 45 minutes. Seconds are cleared on save."
    }

    private var parsed: TimeInterval? {
        DurationFormat.timeInterval(fromDecimalHours: text)
    }

    private func save() {
        guard let parsed else { return }
        onSave(parsed)
        dismiss()
    }
}
