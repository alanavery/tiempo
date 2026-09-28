import SwiftData
import SwiftUI

struct NewTaskSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    var projects: [Project]
    var preferredProjectID: PersistentIdentifier?

    @State private var name = ""
    @State private var projectID: PersistentIdentifier?
    @FocusState private var nameFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("New Task")
                .font(.headline)

            TextField("Name", text: $name)
                .textFieldStyle(.roundedBorder)
                .focused($nameFocused)
                .accessibilityIdentifier("task-name")
                .onSubmit(create)

            Picker("Project", selection: $projectID) {
                ForEach(projects) { project in
                    Text(project.name).tag(Optional(project.persistentModelID))
                }
            }
            .accessibilityIdentifier("task-project")

            HStack {
                Spacer()
                Button("Cancel", role: .cancel) {
                    dismiss()
                }
                Button("Create", action: create)
                    .keyboardShortcut(.defaultAction)
                    .disabled(!canCreate)
                    .accessibilityIdentifier("create-task")
            }
        }
        .padding(20)
        .frame(width: 360)
        .onAppear {
            if projectID == nil {
                projectID = preferredProjectID ?? projects.first?.persistentModelID
            }
            nameFocused = true
        }
    }

    private var trimmedName: String {
        name.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canCreate: Bool {
        !trimmedName.isEmpty && selectedProject != nil
    }

    private var selectedProject: Project? {
        projects.first { $0.persistentModelID == projectID }
    }

    private func create() {
        guard let project = selectedProject, !trimmedName.isEmpty else { return }
        modelContext.insert(TaskItem(name: trimmedName, project: project))
        try? modelContext.save()
        dismiss()
    }
}
