@testable import Runestone
import TestTreeSitterLanguages
import UIKit
import XCTest

final class ThemeBackgroundTests: XCTestCase {
    private let text = "x = \"hello\""

    func testCaptureWithOnlyABackgroundIsStyled() {
        let style = BackgroundStyle(color: .red, cornerRadius: 4)
        let theme = MockTheme(backgrounds: ["string": style])
        let attributedString = syntaxHighlight(text, with: theme)
        // The theme returns no color, font, or shadow for the capture, so the background is the only
        // reason to style the range. Reading it back proves the range was not discarded as unstyled.
        XCTAssertEqual(attributedString.attribute(.syntaxBackground, at: 5, effectiveRange: nil) as? BackgroundStyle, style)
    }

    func testRangesOutsideACaptureHaveNoBackground() {
        let theme = MockTheme(backgrounds: ["string": BackgroundStyle(color: .red, cornerRadius: 4)])
        let attributedString = syntaxHighlight(text, with: theme)
        XCTAssertNil(attributedString.attribute(.syntaxBackground, at: 0, effectiveRange: nil))
    }

    func testExportedStringCarriesBackgroundColor() {
        // TextView draws backgrounds from the internal attribute, but strings returned from
        // StringSyntaxHighlighter are documented to render in UILabel/UITextView, which need
        // the standard .backgroundColor attribute.
        let style = BackgroundStyle(color: .red, cornerRadius: 4)
        let theme = MockTheme(backgrounds: ["string": style])
        let attributedString = syntaxHighlight(text, with: theme)
        XCTAssertEqual(attributedString.attribute(.backgroundColor, at: 5, effectiveRange: nil) as? UIColor, .red)
        XCTAssertNil(attributedString.attribute(.backgroundColor, at: 0, effectiveRange: nil))
    }

    func testQueryWithNonASCIICommentStillHighlights() {
        // A query's byte length must be measured in UTF-8: a length in characters truncates
        // any query with non-ASCII content into a syntax error and highlighting silently stops.
        let query = TreeSitterLanguage.Query(string: "; comment with an em dash \u{2014} and emoji \u{1F389}\n(string) @string")
        let language = TreeSitterLanguage(tree_sitter_python(), highlightsQuery: query)
        let theme = MockTheme(textColors: ["string": .green])
        let syntaxHighlighter = StringSyntaxHighlighter(theme: theme, language: language)
        let attributedString = syntaxHighlighter.syntaxHighlight(text)
        XCTAssertEqual(attributedString.attribute(.foregroundColor, at: 5, effectiveRange: nil) as? UIColor, .green)
    }

    func testNoBackgroundIsAppliedWhenTheThemeReturnsNil() {
        let theme = MockTheme(textColors: ["string": .green])
        let attributedString = syntaxHighlight(text, with: theme)
        XCTAssertNil(attributedString.attribute(.syntaxBackground, at: 5, effectiveRange: nil))
        XCTAssertEqual(attributedString.attribute(.foregroundColor, at: 5, effectiveRange: nil) as? UIColor, .green)
    }
}

private extension ThemeBackgroundTests {
    private func syntaxHighlight(_ text: String, with theme: Theme) -> NSAttributedString {
        let query = TreeSitterLanguage.Query(string: "(string) @string")
        let language = TreeSitterLanguage(tree_sitter_python(), highlightsQuery: query)
        let syntaxHighlighter = StringSyntaxHighlighter(theme: theme, language: language)
        return syntaxHighlighter.syntaxHighlight(text)
    }
}
