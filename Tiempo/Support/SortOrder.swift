import Foundation

enum SortOrder {
    static func reindex<T>(_ items: [T], assign: (T, Int) -> Void) {
        for (index, item) in items.enumerated() {
            assign(item, index)
        }
    }

    static func movingVisible<T>(
        all: [T],
        visible: [T],
        from source: IndexSet,
        to destination: Int,
        matches: (T, T) -> Bool
    ) -> [T] {
        var reorderedVisible = visible
        reorderedVisible.move(fromOffsets: source, toOffset: destination)
        var next = reorderedVisible.makeIterator()
        return all.map { item in
            if visible.contains(where: { matches($0, item) }), let replacement = next.next() {
                return replacement
            }
            return item
        }
    }
}
