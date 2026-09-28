import SwiftData
import SwiftUI

struct NewProjectSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @State private var name = ""
    @FocusState private var nameFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("New Project")
                .font(.headline)

            TextField("Name", text: $name)
                .textFieldStyle(.roundedBorder)
                .focused($nameFocused)
                .accessibilityIdentifier("project-name")
                .onSubmit(create)

            HStack {
                Spacer()
                Button("Cancel", role: .cancel) {
                    dismiss()
                }
                Button("Create", action: create)
                    .keyboardShortcut(.defaultAction)
                    .disabled(trimmedName.isEmpty)
                    .accessibilityIdentifier("create-project")
            }
        }
        .padding(20)
        .frame(width: 320)
        .onAppear { nameFocused = true }
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private func create() {
        guard !trimmedName.isEmpty else { return }
        modelContext.insert(Project(name: trimmedName))
        try? modelContext.save()
        dismiss()
    }
}
