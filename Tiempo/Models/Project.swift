import Foundation
import SwiftData

@Model
final class Project {
    var name: String
    var createdAt: Date

    @Relationship(deleteRule: .nullify, inverse: \TaskItem.project)
    var tasks: [TaskItem] = []

    init(name: String, createdAt: Date = .now) {
        self.name = name
        self.createdAt = createdAt
    }
}
