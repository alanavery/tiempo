import SwiftData
import SwiftUI

struct SidebarView: View {
    var projects: [Project]
    @Binding var selection: SidebarItem
    var onNewProject: () -> Void
    var onDelete: (Project) -> Void

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
}
