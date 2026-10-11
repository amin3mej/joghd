struct InlineText: Equatable, Sendable {
    struct Run: Equatable, Sendable {
        var text: String
        var isBold: Bool
        var isItalic: Bool

        init(text: String, isBold: Bool = false, isItalic: Bool = false) {
            self.text = text
            self.isBold = isBold
            self.isItalic = isItalic
        }
    }

    var runs: [Run]

    var plainText: String {
        runs.map(\.text).joined()
    }

    init(runs: [Run]) {
        self.runs = runs
    }

    init(_ string: String) {
        self.init(runs: [Run(text: string)])
    }
}
