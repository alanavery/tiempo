import XCTest
@testable import Tiempo

final class SortOrderTests: XCTestCase {
    func testMovingVisibleItemsPreservesNeighbors() {
        let all = ["A", "B", "C", "D", "E"]
        let visible = ["B", "C", "D"]
        let reordered = SortOrder.movingVisible(
            all: all,
            visible: visible,
            from: IndexSet(integer: 0),
            to: 3
        ) { $0 == $1 }
        XCTAssertEqual(reordered, ["A", "C", "D", "B", "E"])
    }

    func testReindexAssignsContiguousRanks() {
        var ranks = [10, 20, 30]
        SortOrder.reindex(Array(ranks.indices)) { index, rank in
            ranks[index] = rank
        }
        XCTAssertEqual(ranks, [0, 1, 2])
    }
}
