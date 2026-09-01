@testable import Runestone
import UIKit
import XCTest

final class SyntaxBackgroundFragmentTests: XCTestCase {
    private let style = BackgroundStyle(color: .red, cornerRadius: 4)

    func testNoFragmentsWhenNoRangeHasABackground() {
        let attributedString = NSMutableAttributedString(string: "let value = compute()")
        let fragments = SyntaxBackgroundFragment.fragments(in: attributedString,
                                                           forLineFragmentRange: NSRange(location: 0, length: 21))
        XCTAssertTrue(fragments.isEmpty)
    }

    func testRangeWithinLineFragmentRoundsAllCorners() {
        let attributedString = NSMutableAttributedString(string: "let value = compute()")
        attributedString.addAttribute(.syntaxBackground, value: style, range: NSRange(location: 4, length: 5))
        let fragments = SyntaxBackgroundFragment.fragments(in: attributedString,
                                                           forLineFragmentRange: NSRange(location: 0, length: 21))
        XCTAssertEqual(fragments.count, 1)
        XCTAssertEqual(fragments.first?.range, NSRange(location: 4, length: 5))
        XCTAssertEqual(fragments.first?.containsStart, true)
        XCTAssertEqual(fragments.first?.containsEnd, true)
        XCTAssertEqual(fragments.first?.roundedCorners, .allCorners)
        XCTAssertEqual(fragments.first?.style, style)
    }

    func testRangeSpanningLineFragmentsOnlyRoundsOuterCorners() {
        // The line is broken into the line fragments "let value " and "= compute()" and the styled
        // range spans the boundary between them.
        let attributedString = NSMutableAttributedString(string: "let value = compute()")
        attributedString.addAttribute(.syntaxBackground, value: style, range: NSRange(location: 6, length: 8))
        let firstLineFragmentRange = NSRange(location: 0, length: 10)
        let secondLineFragmentRange = NSRange(location: 10, length: 11)
        let firstFragments = SyntaxBackgroundFragment.fragments(in: attributedString, forLineFragmentRange: firstLineFragmentRange)
        let secondFragments = SyntaxBackgroundFragment.fragments(in: attributedString, forLineFragmentRange: secondLineFragmentRange)
        XCTAssertEqual(firstFragments.count, 1)
        XCTAssertEqual(firstFragments.first?.range, NSRange(location: 6, length: 4))
        XCTAssertEqual(firstFragments.first?.containsStart, true)
        XCTAssertEqual(firstFragments.first?.containsEnd, false)
        XCTAssertEqual(firstFragments.first?.roundedCorners, [.topLeft, .bottomLeft])
        XCTAssertEqual(secondFragments.count, 1)
        XCTAssertEqual(secondFragments.first?.range, NSRange(location: 10, length: 4))
        XCTAssertEqual(secondFragments.first?.containsStart, false)
        XCTAssertEqual(secondFragments.first?.containsEnd, true)
        XCTAssertEqual(secondFragments.first?.roundedCorners, [.topRight, .bottomRight])
    }

    func testRangeSpanningThreeLineFragmentsLeavesMiddleFragmentSquare() {
        let attributedString = NSMutableAttributedString(string: "let value = compute()")
        attributedString.addAttribute(.syntaxBackground, value: style, range: NSRange(location: 2, length: 17))
        let fragments = SyntaxBackgroundFragment.fragments(in: attributedString,
                                                           forLineFragmentRange: NSRange(location: 7, length: 7))
        XCTAssertEqual(fragments.count, 1)
        XCTAssertEqual(fragments.first?.range, NSRange(location: 7, length: 7))
        XCTAssertEqual(fragments.first?.containsStart, false)
        XCTAssertEqual(fragments.first?.containsEnd, false)
        XCTAssertEqual(fragments.first?.roundedCorners, [])
    }

    func testAdjacentRangesWithTheSameStyleAreJoined() {
        let attributedString = NSMutableAttributedString(string: "let value = compute()")
        attributedString.addAttribute(.syntaxBackground, value: style, range: NSRange(location: 4, length: 3))
        attributedString.addAttribute(.syntaxBackground, value: style, range: NSRange(location: 7, length: 2))
        let fragments = SyntaxBackgroundFragment.fragments(in: attributedString,
                                                           forLineFragmentRange: NSRange(location: 0, length: 21))
        XCTAssertEqual(fragments.count, 1)
        XCTAssertEqual(fragments.first?.range, NSRange(location: 4, length: 5))
        XCTAssertEqual(fragments.first?.roundedCorners, .allCorners)
    }

    func testAdjacentRangesWithDifferentStylesAreNotJoined() {
        let otherStyle = BackgroundStyle(color: .green, cornerRadius: 0, fillsLineWidth: true)
        let attributedString = NSMutableAttributedString(string: "let value = compute()")
        attributedString.addAttribute(.syntaxBackground, value: style, range: NSRange(location: 4, length: 3))
        attributedString.addAttribute(.syntaxBackground, value: otherStyle, range: NSRange(location: 7, length: 2))
        let fragments = SyntaxBackgroundFragment.fragments(in: attributedString,
                                                           forLineFragmentRange: NSRange(location: 0, length: 21))
        XCTAssertEqual(fragments.count, 2)
        XCTAssertEqual(fragments.first?.style, style)
        XCTAssertEqual(fragments.first?.roundedCorners, .allCorners)
        XCTAssertEqual(fragments.last?.style, otherStyle)
        XCTAssertEqual(fragments.last?.roundedCorners, .allCorners)
        XCTAssertEqual(fragments.last?.fillsLineWidth, true)
    }

    func testFragmentsAreCappedToTheLineFragmentRange() {
        let attributedString = NSMutableAttributedString(string: "let value = compute()")
        attributedString.addAttribute(.syntaxBackground, value: style, range: NSRange(location: 0, length: 21))
        let fragments = SyntaxBackgroundFragment.fragments(in: attributedString,
                                                           forLineFragmentRange: NSRange(location: 10, length: 100))
        XCTAssertEqual(fragments.count, 1)
        XCTAssertEqual(fragments.first?.range, NSRange(location: 10, length: 11))
        XCTAssertEqual(fragments.first?.containsStart, false)
        XCTAssertEqual(fragments.first?.containsEnd, true)
    }

    func testNoFragmentsWhenLineFragmentRangeIsEmpty() {
        let attributedString = NSMutableAttributedString(string: "let value = compute()")
        attributedString.addAttribute(.syntaxBackground, value: style, range: NSRange(location: 0, length: 21))
        let fragments = SyntaxBackgroundFragment.fragments(in: attributedString,
                                                           forLineFragmentRange: NSRange(location: 4, length: 0))
        XCTAssertTrue(fragments.isEmpty)
    }
}
