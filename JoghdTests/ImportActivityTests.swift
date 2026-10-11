import Testing

@testable import Joghd

struct ImportActivityTests {
    @Test
    func startsInactive() {
        #expect(!ImportActivity().isActive)
    }

    @Test
    func becomesActiveOnFirstBegin() {
        var activity = ImportActivity()
        activity.begin()
        #expect(activity.isActive)
    }

    @Test
    func staysActiveUntilEveryImportEnds() {
        var activity = ImportActivity()
        activity.begin()
        activity.begin()
        activity.end()
        #expect(activity.isActive)
        activity.end()
        #expect(!activity.isActive)
    }

    @Test
    func extraEndDoesNotReactivate() {
        var activity = ImportActivity()
        activity.begin()
        activity.end()
        activity.end()
        #expect(!activity.isActive)
    }
}
