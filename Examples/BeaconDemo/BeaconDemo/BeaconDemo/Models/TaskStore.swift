import SwiftUI

@Observable
@MainActor
final class TaskStore {
    var tasks: [TaskItem] = TaskItem.samples

    func add(_ task: TaskItem) {
        tasks.insert(task, at: 0)
    }

    func toggle(_ task: TaskItem) {
        guard let index = tasks.firstIndex(where: { $0.id == task.id }) else { return }
        tasks[index].isCompleted.toggle()
    }

    func delete(_ task: TaskItem) {
        tasks.removeAll { $0.id == task.id }
    }

    func reset() {
        tasks = TaskItem.samples
    }
}
