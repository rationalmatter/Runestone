@testable import Runestone
import UIKit
import XCTest

// UIKit hands UITextInput positions and ranges it holds on to, or did not get from the text view at all.
// These tests pin the answers given for those instead of trapping.
final class TextViewTextInputTests: XCTestCase {}

// MARK: - Comparing Positions
extension TextViewTextInputTests {
    // Hardware up/down arrow keys on iPad reach compare(_:to:) with a position the text view did not create.
    func testComparingForeignPositionIsOrderedSame() {
        let textView = makeTextView()
        let foreignPosition = ForeignTextPosition()
        XCTAssertEqual(textView.compare(foreignPosition, to: textView.endOfDocument), .orderedSame)
        XCTAssertEqual(textView.compare(textView.beginningOfDocument, to: foreignPosition), .orderedSame)
    }

    func testComparingIndexedPositions() {
        let textView = makeTextView()
        XCTAssertEqual(textView.compare(textView.beginningOfDocument, to: textView.endOfDocument), .orderedAscending)
        XCTAssertEqual(textView.compare(textView.endOfDocument, to: textView.beginningOfDocument), .orderedDescending)
        XCTAssertEqual(textView.compare(textView.endOfDocument, to: textView.endOfDocument), .orderedSame)
    }
}

private extension TextViewTextInputTests {
    private static let textViewFrame = CGRect(x: 0, y: 0, width: 320, height: 480)

    private func makeTextView(text: String = "Hello world") -> TextView {
        let textView = TextView(frame: Self.textViewFrame)
        textView.text = text
        return textView
    }
}

private final class ForeignTextPosition: UITextPosition {}
