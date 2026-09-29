import SwiftData
import SwiftUI

struct TaskListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskItem.createdAt) private var tasks: [TaskItem]
    @State private var resetConfirmationPresented = false
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
        .safeAreaInset(edge: .bottom, spacing: 0) {
            if !projects.isEmpty {
                totalBar
            }
        }
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

    private var totalBar: some View {
        VStack(spacing: 0) {
            Divider()
            HStack {
                Button("Reset", systemImage: "arrow.counterclockwise") {
                    resetConfirmationPresented = true
                }
                .disabled(!canReset)
                .accessibilityIdentifier("reset-all")
                Spacer()
                Text("Total")
                    .font(.headline)
                TimelineView(.periodic(from: .now, by: 1)) { context in
                    Text(DurationFormat.string(from: TimeTracker.totalElapsed(tasks, at: context.date)))
                        .font(.title3.monospacedDigit().weight(.semibold))
                        .frame(minWidth: 88, alignment: .trailing)
                        .accessibilityIdentifier("total-elapsed")
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .background(.bar)
        .alert("Reset all task times?", isPresented: $resetConfirmationPresented) {
            Button("Reset", role: .destructive, action: resetAll)
                .accessibilityIdentifier("confirm-reset")
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Every task returns to 00:00:00, and the running timer stops.")
        }
    }

    private var canReset: Bool {
        tasks.contains { $0.accumulated > 0 || $0.isRunning }
    }

    private func resetAll() {
        try? TimeTracker.resetAll(in: modelContext)
        try? modelContext.save()
    }

    private func delete(_ task: TaskItem) {
        modelContext.delete(task)
        try? modelContext.save()
    }
}
