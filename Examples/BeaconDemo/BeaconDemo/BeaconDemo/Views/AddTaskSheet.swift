import SwiftUI
import Beacon

struct AddTaskSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var title = ""
    @State private var hasDueDate = false
    @State private var dueDate = Date()

    let onAdd: (TaskItem) -> Void
    var showBeaconTargets = false

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextField("Task title", text: $title)
                        .applyBeaconTarget(showBeaconTargets ? "title-field" : nil, shape: .capsule)
                }

                Section {
                    Toggle("Set due date", isOn: $hasDueDate)
                        .applyBeaconTarget(showBeaconTargets ? "due-toggle" : nil, shape: .capsule)

                    if hasDueDate {
                        DatePicker("Due date", selection: $dueDate, displayedComponents: .date)
                            .applyBeaconTarget(showBeaconTargets ? "date-picker" : nil, shape: .capsule)
                    }
                }
            }
            .navigationTitle("New Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Add") {
                        let task = TaskItem(
                            title: title,
                            dueDate: hasDueDate ? dueDate : nil
                        )
                        onAdd(task)
                        dismiss()
                    }
                    .disabled(title.isEmpty)
                    .applyBeaconTarget(showBeaconTargets ? "add-button" : nil, shape: .capsule)
                }
            }
        }
        .interactiveDismissDisabled(Beacon.Sequence.isRunning)
    }
}
