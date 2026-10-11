import SwiftUI
import Testing

@testable import Joghd

struct LibraryGridMetricsTests {
    @Test
    func usesTwoColumnsForTheGrid() {
        #expect(LibraryGridMetrics.columns.count == 2)
    }

    @Test
    func coversUseConsistentPortraitSlots() {
        #expect(LibraryGridMetrics.coverAspectRatio < 1)
        #expect(abs(Double(LibraryGridMetrics.coverAspectRatio) - 2.0 / 3.0) < 0.0001)
    }
}
