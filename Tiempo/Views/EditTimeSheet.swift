import SwiftUI

struct EditTimeSheet: View {
    @Environment(\.dismiss) private var dismiss
    var onSave: (TimeInterval) -> Void

    @State private var text: String
    @FocusState private var textFocused: Bool

    init(elapsed: TimeInterval, onSave: @escaping (TimeInterval) -> Void) {
        self.onSave = onSave
        _text = State(initialValue: DurationFormat.string(from: elapsed))
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Edit Time")
                .font(.headline)

            TextField("00:00:00", text: $text)
                .textFieldStyle(.roundedBorder)
                .font(.body.monospacedDigit())
                .focused($textFocused)
                .accessibilityIdentifier("edit-time")
                .onSubmit(save)

            Text("Use hours:minutes:seconds, like 01:30:00.")
                .font(.caption)
                .foregroundStyle(.secondary)

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

    private var parsed: TimeInterval? {
        DurationFormat.timeInterval(from: text)
    }

    private func save() {
        guard let parsed else { return }
        onSave(parsed)
        dismiss()
    }
}
