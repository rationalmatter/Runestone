@testable import Runestone
import UIKit
import XCTest

final class TreeSitterSyntaxHighlightTokenTests: XCTestCase {
    func testTokenWithoutStylingIsEmpty() {
        let token = TreeSitterSyntaxHighlightToken(
            range: NSRange(location: 0, length: 5),
            textColor: nil,
            shadow: nil,
            font: nil,
            fontTraits: [],
            background: nil
        )
        XCTAssertTrue(token.isEmpty)
    }

    func testTokenWithOnlyBackgroundIsNotEmpty() {
        let token = TreeSitterSyntaxHighlightToken(
            range: NSRange(location: 0, length: 5),
            textColor: nil,
            shadow: nil,
            font: nil,
            fontTraits: [],
            background: BackgroundStyle(color: .red, cornerRadius: 4)
        )
        XCTAssertFalse(token.isEmpty)
    }

    func testTokenWithBackgroundAndEmptyRangeIsEmpty() {
        let token = TreeSitterSyntaxHighlightToken(
            range: NSRange(location: 3, length: 0),
            textColor: nil,
            shadow: nil,
            font: nil,
            fontTraits: [],
            background: BackgroundStyle(color: .red)
        )
        XCTAssertTrue(token.isEmpty)
    }

    func testTokensWithDifferentBackgroundsAreNotEqual() {
        let range = NSRange(location: 0, length: 5)
        let tokenA = TreeSitterSyntaxHighlightToken(
            range: range,
            textColor: nil,
            shadow: nil,
            font: nil,
            fontTraits: [],
            background: BackgroundStyle(color: .red)
        )
        let tokenB = TreeSitterSyntaxHighlightToken(
            range: range,
            textColor: nil,
            shadow: nil,
            font: nil,
            fontTraits: [],
            background: BackgroundStyle(color: .green)
        )
        XCTAssertNotEqual(tokenA, tokenB)
    }
}
