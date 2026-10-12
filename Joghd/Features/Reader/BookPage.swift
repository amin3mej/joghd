import UIKit

struct BookPage {
    let text: NSAttributedString
    let range: NSRange

    func contains(characterOffset offset: Int) -> Bool {
        range.location <= offset && offset < NSMaxRange(range)
    }
}
