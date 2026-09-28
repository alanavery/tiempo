import SwiftData
import SwiftUI

struct TaskListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskItem.createdAt) private var tasks: [TaskItem]
    var selection: SidebarItem
    var projects: [Project]
    var onNewTask: () -> Void

    var body: some View {
        Group {
            if projects.isEmpty {
                ContentUnavailableView(
                    "No Projects",
                    systemImage: "folder",
                    description: Text("Create a project before adding tasks.")
                )
            } else if visibleTasks.isEmpty {
                ContentUnavailableView(
                    "No Tasks",
                    systemImage: "checklist",
                    description: Text("Create a task and start tracking time.")
                )
            } else {
                List(visibleTasks) { task in
                    TaskRowView(task: task, showsProject: selection == .all)
                        .contextMenu {
                            Button("Delete", role: .destructive) {
                                delete(task)
                            }
                        }
                }
                .listStyle(.inset)
            }
        }
        .navigationTitle(title)
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button("New Task", systemImage: "plus", action: onNewTask)
                    .disabled(projects.isEmpty)
                    .accessibilityIdentifier("new-task")
            }
        }
    }

    private var title: String {
        switch selection {
        case .all:
            "All Tasks"
        case .project(let id):
            projects.first { $0.persistentModelID == id }?.name ?? "Tasks"
        }
    }

    private var visibleTasks: [TaskItem] {
        switch selection {
        case .all:
            tasks
        case .project(let id):
            tasks.filter { $0.project?.persistentModelID == id }
        }
    }

    private func delete(_ task: TaskItem) {
        modelContext.delete(task)
        try? modelContext.save()
    }
}
