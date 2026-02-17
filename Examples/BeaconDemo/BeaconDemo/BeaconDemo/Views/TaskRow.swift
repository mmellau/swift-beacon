import SwiftUI
import Beacon

struct TaskRow: View {
    let task: TaskItem
    let onToggle: () -> Void
    var beaconId: String? = nil
    var priorityBeaconId: String? = nil
    var onPriorityTap: (() -> Void)? = nil

    var body: some View {
        HStack(spacing: 12) {
            Button(action: onToggle) {
                Image(systemName: task.isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundStyle(task.isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)
            .applyBeaconTarget(beaconId.map { "\($0)-checkbox" })

            VStack(alignment: .leading, spacing: 4) {
                Text(task.title)
                    .strikethrough(task.isCompleted)
                    .foregroundStyle(task.isCompleted ? .secondary : .primary)

                if let dueDate = task.dueDate {
                    Text(dueDate, style: .date)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer()

            if let color = task.priority.color {
                Button {
                    onPriorityTap?()
                } label: {
                    Circle()
                        .fill(color)
                        .frame(width: 12, height: 12)
                }
                .buttonStyle(.plain)
                .applyBeaconTarget(priorityBeaconId)
            }
        }
        .padding(.vertical, 8)
        .contentShape(.rect)
    }
}
