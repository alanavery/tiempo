import SwiftData
import SwiftUI

enum SidebarItem: Hashable {
    case all
    case project(PersistentIdentifier)
}

struct ContentView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Project.createdAt) private var projects: [Project]
    @State private var selection: SidebarItem = .all
    @State private var newProjectPresented = false
    @State private var newTaskPresented = false

    var body: some View {
        NavigationSplitView {
            SidebarView(
                projects: projects,
                selection: $selection,
                onNewProject: { newProjectPresented = true },
                onDelete: deleteProject
            )
            .navigationSplitViewColumnWidth(min: 200, ideal: 220, max: 280)
        } detail: {
            TaskListView(
                selection: selection,
                projects: projects,
                onNewTask: { newTaskPresented = true }
            )
        }
        .frame(minWidth: 760, minHeight: 480)
        .sheet(isPresented: $newProjectPresented) {
            NewProjectSheet()
        }
        .sheet(isPresented: $newTaskPresented) {
            NewTaskSheet(projects: projects, preferredProjectID: preferredProjectID)
        }
        .onChange(of: projectIDs) { _, ids in
            if case .project(let id) = selection, !ids.contains(id) {
                selection = .all
            }
        }
    }

    private var projectIDs: [PersistentIdentifier] {
        projects.map(\.persistentModelID)
    }

    private var preferredProjectID: PersistentIdentifier? {
        if case .project(let id) = selection {
            return id
        }
        return projects.first?.persistentModelID
    }

    private func deleteProject(_ project: Project) {
        if case .project(let id) = selection, id == project.persistentModelID {
            selection = .all
        }
        let projectID = project.persistentModelID
        let tasks = (try? modelContext.fetch(FetchDescriptor<TaskItem>())) ?? []
        for task in tasks where task.project?.persistentModelID == projectID {
            modelContext.delete(task)
        }
        modelContext.delete(project)
        try? modelContext.save()
    }
}
