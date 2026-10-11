import Foundation

struct EpubContainer {
    var packagePath: String

    static func parse(_ xml: String) throws -> Self {
        let tree = try XMLTreeBuilder.parse(xml)
        guard let rootfile = tree.firstElement(named: "rootfile"),
            let path = rootfile.attribute("full-path")
        else {
            throw BookParsingError.malformedEpub
        }
        return Self(packagePath: path)
    }
}
