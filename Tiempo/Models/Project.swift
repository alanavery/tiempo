import Foundation
import SwiftData

@Model
final class Project {
    var name: String
    var createdAt: Date
    var sortIndex: Int

    init(name: String, createdAt: Date = .now, sortIndex: Int = 0) {
        self.name = name
        self.createdAt = createdAt
        self.sortIndex = sortIndex
    }
}
