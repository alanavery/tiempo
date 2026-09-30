import SwiftData
import SwiftUI

struct SidebarView: View {
    @Environment(\.modelContext) private var modelContext
    var projects: [Project]
    @Binding var selection: SidebarItem
    var onNewProject: () -> Void
    var onDelete: (Project) -> Void
    @State private var renamingProjectID: PersistentIdentifier?

    var body: some View {
        List(selection: $selection) {
            Label("All Tasks", systemImage: "tray.full")
                .tag(SidebarItem.all)
                .accessibilityIdentifier("all-tasks")

            Section("Projects") {
                if projects.isEmpty {
                    Text("No projects yet")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(projects) { project in
                        Label(project.name, systemImage: "folder")
                            .tag(SidebarItem.project(project.persistentModelID))
                            .accessibilityIdentifier("project-\(project.name)")
                            .contextMenu {
                                Button("Rename") {
                                    renamingProjectID = project.persistentModelID
                                }
                                Button("Delete", role: .destructive) {
                                    onDelete(project)
                                }
                            }
                    }
                }
            }
        }
        .listStyle(.sidebar)
        .navigationTitle("Tiempo")
        .sheet(isPresented: renamingPresented) {
            if let project = renamingProject {
                RenameSheet(title: "Rename Project", name: project.name) { newName in
                    project.name = newName
                    try? modelContext.save()
                }
            }
        }
        .safeAreaInset(edge: .bottom, spacing: 0) {
            Divider()
            Button(action: onNewProject) {
                Label("New Project", systemImage: "plus")
            }
            .buttonStyle(.borderless)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .accessibilityIdentifier("new-project")
        }
    }

    private var renamingProject: Project? {
        projects.first { $0.persistentModelID == renamingProjectID }
    }

    private var renamingPresented: Binding<Bool> {
        Binding(
            get: { renamingProjectID != nil },
            set: { isPresented in
                if !isPresented {
                    renamingProjectID = nil
                }
            }
        )
    }
}
