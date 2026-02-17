import Foundation
import SwiftUI

struct TaskItem: Identifiable {

    enum Priority: String, CaseIterable {
        case none = "None"
        case low = "Low"
        case medium = "Medium"
        case high = "High"

        var color: Color? {
            switch self {
            case .none: nil
            case .low: .blue
            case .medium: .orange
            case .high: .red
            }
        }
    }

    let id: UUID
    var title: String
    var isCompleted: Bool
    var dueDate: Date?
    var priority: Priority

    init(
        id: UUID = UUID(),
        title: String,
        isCompleted: Bool = false,
        dueDate: Date? = nil,
        priority: Priority = .none
    ) {
        self.id = id
        self.title = title
        self.isCompleted = isCompleted
        self.dueDate = dueDate
        self.priority = priority
    }
}

extension TaskItem {
    static let samples: [TaskItem] = [
        TaskItem(title: "Review pull request", isCompleted: true, priority: .low),
        TaskItem(title: "Update documentation", dueDate: Date().addingTimeInterval(86400), priority: .medium),
        TaskItem(title: "Fix login bug", dueDate: Date().addingTimeInterval(172800), priority: .high),
        TaskItem(title: "Write unit tests"),
        TaskItem(title: "Prepare demo")
    ]
}
