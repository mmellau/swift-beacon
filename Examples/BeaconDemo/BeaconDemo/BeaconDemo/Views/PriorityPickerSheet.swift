import SwiftUI
import Beacon

struct PriorityPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let task: TaskItem
    var showBeaconTargets: Bool = false
    let onSelect: (TaskItem.Priority) -> Void

    var body: some View {
        NavigationStack {
            List {
                ForEach(TaskItem.Priority.allCases, id: \.self) { priority in
                    Button {
                        onSelect(priority)
                        dismiss()
                    } label: {
                        HStack {
                            Text(priority.rawValue)
                            Spacer()
                            if let color = priority.color {
                                Circle()
                                    .fill(color)
                                    .frame(width: 12, height: 12)
                            }
                            if task.priority == priority {
                                Image(systemName: "checkmark")
                                    .foregroundStyle(.blue)
                            }
                        }
                    }
                    .foregroundStyle(.primary)
                    .applyBeaconTarget(showBeaconTargets ? beaconId(for: priority) : nil, shape: .capsule)
                }
            }
            .navigationTitle("Set Priority")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }

    private func beaconId(for priority: TaskItem.Priority) -> String? {
        switch priority {
        case .high: "priority-high"
        case .medium: "priority-medium"
        case .low: "priority-low"
        case .none: nil
        }
    }
}
