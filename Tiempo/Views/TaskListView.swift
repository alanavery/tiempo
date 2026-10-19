import SwiftData
import SwiftUI

struct TaskListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \TaskItem.sortIndex) private var tasks: [TaskItem]
    @Environment(BreakCoordinator.self) private var breaks
    @State private var resetConfirmationPresented = false
    @State private var meetingTimePresented = false
    @State private var breakSettingsPresented = false
    @State private var renamingTaskID: PersistentIdentifier?
    @State private var editingTimeTaskID: PersistentIdentifier?
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
                List {
                    ForEach(taskGroups) { group in
                        Section(group.title) {
                            ForEach(group.tasks) { task in
                                TaskRowView(task: task, showsProject: false)
                                    .contextMenu {
                                        Button("Rename") {
                                            renamingTaskID = task.persistentModelID
                                        }
                                        Button("Edit Time") {
                                            editingTimeTaskID = task.persistentModelID
                                        }
                                        Button("Delete", role: .destructive) {
                                            delete(task)
                                        }
                                    }
                            }
                            .onMove { source, destination in
                                moveTasks(in: group, from: source, to: destination)
                            }
                        }
                    }
                }
                .listStyle(.inset)
            }
        }
        .navigationTitle(title)
        .sheet(isPresented: renamingPresented) {
            if let task = renamingTask {
                RenameSheet(title: "Rename Task", name: task.name) { newName in
                    task.name = newName
                    try? modelContext.save()
                }
            }
        }
        .sheet(isPresented: editingTimePresented) {
            if let task = editingTimeTask {
                EditTimeSheet(elapsed: TimeTracker.elapsed(task)) { newElapsed in
                    TimeTracker.setElapsed(task, to: newElapsed)
                    try? modelContext.save()
                }
            }
        }
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

    private var taskGroups: [TaskGroup] {
        switch selection {
        case .project(let id):
            guard let project = projects.first(where: { $0.persistentModelID == id }) else { return [] }
            let groupTasks = visibleTasks
            guard !groupTasks.isEmpty else { return [] }
            return [TaskGroup(id: project.persistentModelID, title: project.name, tasks: groupTasks)]
        case .all:
            var groups = projects.compactMap { project -> TaskGroup? in
                let groupTasks = tasks.filter { $0.project?.persistentModelID == project.persistentModelID }
                guard !groupTasks.isEmpty else { return nil }
                return TaskGroup(id: project.persistentModelID, title: project.name, tasks: groupTasks)
            }
            let orphaned = tasks.filter { $0.project == nil }
            if !orphaned.isEmpty {
                groups.append(TaskGroup(id: nil, title: "No Project", tasks: orphaned))
            }
            return groups
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
                Button("Breaks", systemImage: "cup.and.saucer") {
                    breakSettingsPresented = true
                }
                .accessibilityIdentifier("break-settings")
                if breaks.monitor.cycle.workdayComplete, !breaks.monitor.cycle.balanced {
                    Button("Balance", systemImage: "equal.circle", action: balance)
                        .disabled(!canBalance)
                        .accessibilityIdentifier("balance")
                }
                if breaks.monitor.cycle.onBreak {
                    Text("On a break")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if breaks.monitor.cycle.workdayComplete {
                    Text(breaks.monitor.cycle.balanced ? "Balanced" : "Workday complete")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                Spacer()
                bottomStat(
                    label: "Meetings",
                    value: DurationFormat.string(from: breaks.monitor.meetingLength),
                    identifier: "meeting-time"
                )
                bottomStat(
                    label: "Workday",
                    value: DurationFormat.string(from: breaks.monitor.balancedWorkdayLength),
                    identifier: "planned-workday"
                )
                HStack(spacing: 8) {
                    Text("Total")
                        .font(.headline)
                    TimelineView(.periodic(from: .now, by: 1)) { context in
                        Text(DurationFormat.string(from: TimeTracker.totalElapsed(tasks, at: context.date)))
                            .font(.title3.monospacedDigit().weight(.semibold))
                            .frame(minWidth: 88, alignment: .trailing)
                            .accessibilityIdentifier("total-elapsed")
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
        }
        .background(.bar)
        .sheet(isPresented: $breakSettingsPresented) {
            BreakSettingsSheet(monitor: breaks.monitor)
        }
        .sheet(isPresented: $meetingTimePresented) {
            MeetingTimeSheet(meetingHours: 0, onConfirm: resetAll)
        }
        .alert("Reset all task times?", isPresented: $resetConfirmationPresented) {
            Button("Reset", role: .destructive) {
                Task { @MainActor in
                    meetingTimePresented = true
                }
            }
            .accessibilityIdentifier("confirm-reset")
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Every task returns to 00:00:00, and the running timer stops. Next you can set today's meeting time.")
        }
    }

    private func bottomStat(label: String, value: String, identifier: String) -> some View {
        HStack(spacing: 6) {
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.body.monospacedDigit())
                .foregroundStyle(.secondary)
                .accessibilityIdentifier(identifier)
        }
        .padding(.trailing, 8)
    }

    private var canReset: Bool {
        tasks.contains { $0.accumulated > 0 || $0.isRunning }
    }

    private var canBalance: Bool {
        breaks.monitor.canBalance
            && tasks.contains { TimeTracker.elapsed($0) >= 60 }
    }

    private func resetAll(meetingHours: Double) {
        try? TimeTracker.resetAll(in: modelContext)
        breaks.monitor.resetCycle(meetingHours: meetingHours)
        try? modelContext.save()
    }

    private func balance() {
        breaks.monitor.balance(tasks: tasks, in: modelContext)
    }

    private var renamingTask: TaskItem? {
        tasks.first { $0.persistentModelID == renamingTaskID }
    }

    private var renamingPresented: Binding<Bool> {
        Binding(
            get: { renamingTaskID != nil },
            set: { isPresented in
                if !isPresented {
                    renamingTaskID = nil
                }
            }
        )
    }

    private var editingTimeTask: TaskItem? {
        tasks.first { $0.persistentModelID == editingTimeTaskID }
    }

    private var editingTimePresented: Binding<Bool> {
        Binding(
            get: { editingTimeTaskID != nil },
            set: { isPresented in
                if !isPresented {
                    editingTimeTaskID = nil
                }
            }
        )
    }

    private func moveTasks(in group: TaskGroup, from source: IndexSet, to destination: Int) {
        let ordered = SortOrder.movingVisible(
            all: tasks,
            visible: group.tasks,
            from: source,
            to: destination
        ) { $0.persistentModelID == $1.persistentModelID }
        SortOrder.reindex(ordered) { task, index in
            task.sortIndex = index
        }
        try? modelContext.save()
    }

    private func delete(_ task: TaskItem) {
        modelContext.delete(task)
        try? modelContext.save()
    }
}

private struct TaskGroup: Identifiable {
    var id: PersistentIdentifier?
    var title: String
    var tasks: [TaskItem]
}

