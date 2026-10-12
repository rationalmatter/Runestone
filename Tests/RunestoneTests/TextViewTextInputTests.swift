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

// MARK: - Text in Range
extension TextViewTextInputTests {
    // Deleting backward appends the text UIKit reads around the caret, so an empty range must answer "" rather than nil.
    func testTextInEmptyRangeIsEmptyString() {
        let textView = makeTextView()
        let range = textView.textRange(from: textView.endOfDocument, to: textView.endOfDocument)!
        XCTAssertEqual(textView.text(in: range), "")
    }

    func testTextInRangePastEndAfterTextShrankIsEmptyString() {
        let textView = makeTextView(text: "Hello world")
        let range = rangeOfSecondWord(in: textView)
        textView.text = "Hi"
        XCTAssertEqual(textView.text(in: range), "")
    }

    func testTextInRangeOverlappingEndAfterTextShrankIsCappedToText() {
        let textView = makeTextView(text: "Hello world")
        let range = textView.textRange(from: textView.beginningOfDocument, to: textView.endOfDocument)!
        textView.text = "Hi"
        XCTAssertEqual(textView.text(in: range), "Hi")
    }

    func testTextInForeignRangeIsEmptyString() {
        let textView = makeTextView()
        XCTAssertEqual(textView.text(in: ForeignTextRange()), "")
    }

    func testTextInRange() {
        let textView = makeTextView(text: "Hello world")
        let range = rangeOfSecondWord(in: textView)
        XCTAssertEqual(textView.text(in: range), "world")
    }
}

// MARK: - First Rect
extension TextViewTextInputTests {
    // The keyboard refreshes its candidate bar after a selection change by asking for the first rect of a range it held
    // across an edit, which can start past the end of the shorter text. It's measured as the end of the text.
    func testFirstRectForRangePastEndAfterTextShrankIsRectAtEndOfText() {
        let textView = makeTextView(text: "Hello world")
        let range = rangeOfSecondWord(in: textView)
        textView.text = "Hi"
        let endRange = textView.textRange(from: textView.endOfDocument, to: textView.endOfDocument)!
        XCTAssertEqual(textView.firstRect(for: range), textView.firstRect(for: endRange))
    }

    func testFirstRectForForeignRangeIsZero() {
        let textView = makeTextView()
        XCTAssertEqual(textView.firstRect(for: ForeignTextRange()), .zero)
    }
}

// MARK: - Cut and Copy
// Reading the pasteboard's contents raises the paste permission alert and blocks the test, so these tests watch its
// change count instead, which reads without one.
extension TextViewTextInputTests {
    // UIKit can set a selection from a range it held across an edit that shrank the text. text(in:) caps that range for
    // UIKit, but Cut and Copy must not act on it: cutting would delete past the end of the text.
    func testCuttingStaleSelectionAfterTextShrankChangesNothing() throws {
        let textView = makeTextView(text: "Hello world")
        let staleRange = textView.textRange(from: textView.beginningOfDocument, to: textView.endOfDocument)!
        textView.selectedTextRange = staleRange
        textView.text = "Hi"
        textView.selectedTextRange = staleRange
        let changeCount = UIPasteboard.general.changeCount
        try editActionsResponder(of: textView).cut(nil)
        XCTAssertEqual(textView.text, "Hi")
        XCTAssertEqual(UIPasteboard.general.changeCount, changeCount)
    }

    func testCopyingStaleSelectionAfterTextShrankKeepsPasteboard() throws {
        let textView = makeTextView(text: "Hello world")
        let staleRange = textView.textRange(from: textView.beginningOfDocument, to: textView.endOfDocument)!
        textView.selectedTextRange = staleRange
        textView.text = "Hi"
        textView.selectedTextRange = staleRange
        let changeCount = UIPasteboard.general.changeCount
        try editActionsResponder(of: textView).copy(nil)
        XCTAssertEqual(UIPasteboard.general.changeCount, changeCount)
    }

    func testCuttingEmptySelectionChangesNothing() throws {
        let textView = makeTextView(text: "Hello world")
        textView.selectedTextRange = textView.textRange(from: textView.endOfDocument, to: textView.endOfDocument)
        let changeCount = UIPasteboard.general.changeCount
        try editActionsResponder(of: textView).cut(nil)
        XCTAssertEqual(textView.text, "Hello world")
        XCTAssertEqual(UIPasteboard.general.changeCount, changeCount)
    }

    func testCopyingEmptySelectionKeepsPasteboard() throws {
        let textView = makeTextView(text: "Hello world")
        textView.selectedTextRange = textView.textRange(from: textView.endOfDocument, to: textView.endOfDocument)
        let changeCount = UIPasteboard.general.changeCount
        try editActionsResponder(of: textView).copy(nil)
        XCTAssertEqual(UIPasteboard.general.changeCount, changeCount)
    }

    func testCuttingSelectionRemovesItAndWritesPasteboard() throws {
        let textView = makeTextView(text: "Hello world")
        textView.selectedTextRange = rangeOfSecondWord(in: textView)
        let changeCount = UIPasteboard.general.changeCount
        try editActionsResponder(of: textView).cut(nil)
        XCTAssertEqual(textView.text, "Hello ")
        XCTAssertNotEqual(UIPasteboard.general.changeCount, changeCount)
    }

    func testCopyingSelectionKeepsTextAndWritesPasteboard() throws {
        let textView = makeTextView(text: "Hello world")
        textView.selectedTextRange = rangeOfSecondWord(in: textView)
        let changeCount = UIPasteboard.general.changeCount
        try editActionsResponder(of: textView).copy(nil)
        XCTAssertEqual(textView.text, "Hello world")
        XCTAssertNotEqual(UIPasteboard.general.changeCount, changeCount)
    }
}

private extension TextViewTextInputTests {
    private static let textViewFrame = CGRect(x: 0, y: 0, width: 320, height: 480)

    private static let secondWordOffset = ("Hello " as NSString).length

    // The edit menu sends Cut and Copy to the text input view the text view hosts, not to the text view itself.
    private func editActionsResponder(of textView: TextView) throws -> TextInputView {
        try XCTUnwrap(textView.subviews.lazy.compactMap { $0 as? TextInputView }.first)
    }

    // The range of "world" in "Hello world".
    private func rangeOfSecondWord(in textView: TextView) -> UITextRange {
        let start = textView.position(from: textView.beginningOfDocument, offset: Self.secondWordOffset)!
        return textView.textRange(from: start, to: textView.endOfDocument)!
    }

    private func makeTextView(text: String = "Hello world") -> TextView {
        let textView = TextView(frame: Self.textViewFrame)
        textView.text = text
        return textView
    }
}

private final class ForeignTextPosition: UITextPosition {}

private final class ForeignTextRange: UITextRange {}
