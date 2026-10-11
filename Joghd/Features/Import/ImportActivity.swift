struct ImportActivity {
    private var inFlight = 0

    var isActive: Bool { inFlight > 0 }

    mutating func begin() {
        inFlight += 1
    }

    mutating func end() {
        inFlight = max(0, inFlight - 1)
    }
}
