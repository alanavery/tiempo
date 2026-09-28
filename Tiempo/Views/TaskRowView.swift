import SwiftData
import SwiftUI

struct TaskRowView: View {
    @Environment(\.modelContext) private var modelContext
    var task: TaskItem
    var showsProject: Bool

    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 2) {
                Text(task.name)
                    .font(.body)
                if showsProject, let projectName = task.project?.name {
                    Text(projectName)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 12)

            TimelineView(.periodic(from: .now, by: 1)) { context in
                Text(DurationFormat.string(from: TimeTracker.elapsed(task, at: context.date)))
                    .font(.title3.monospacedDigit().weight(task.isRunning ? .semibold : .regular))
                    .foregroundStyle(task.isRunning ? AnyShapeStyle(.primary) : AnyShapeStyle(.secondary))
                    .frame(minWidth: 88, alignment: .trailing)
                    .accessibilityIdentifier("elapsed-\(task.name)")
            }

            timerButton
        }
        .padding(.vertical, 4)
        .padding(.horizontal, 4)
        .background {
            if task.isRunning {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.accentColor.opacity(0.16))
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityIdentifier("task-\(task.name)")
    }

    @ViewBuilder
    private var timerButton: some View {
        if task.isRunning {
            Button(action: toggle) {
                Label("Pause", systemImage: "pause.fill")
            }
            .buttonStyle(.borderedProminent)
            .accessibilityIdentifier("timer-\(task.name)")
        } else {
            Button(action: toggle) {
                Label("Start", systemImage: "play.fill")
            }
            .buttonStyle(.bordered)
            .accessibilityIdentifier("timer-\(task.name)")
        }
    }

    private func toggle() {
        if task.isRunning {
            TimeTracker.pause(task)
        } else {
            try? TimeTracker.start(task, in: modelContext)
        }
        try? modelContext.save()
    }
}
