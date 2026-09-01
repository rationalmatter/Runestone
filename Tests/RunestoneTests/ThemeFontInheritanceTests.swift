@testable import Runestone
import TestTreeSitterLanguages
import UIKit
import XCTest

final class ThemeFontInheritanceTests: XCTestCase {
    private let text = "x = \"hello\""
    private let outerFont: UIFont = .monospacedSystemFont(ofSize: 23, weight: .regular)
    private let innerFont: UIFont = .monospacedSystemFont(ofSize: 11, weight: .regular)

    func testInnerCaptureInheritsEnclosingFont() {
        // The inner capture has a color but no font of its own. It must refine the enclosing
        // capture's font, not reset the range to the theme's base font.
        let theme = MockTheme(textColors: ["inner": .green], fonts: ["outer": outerFont])
        let attributedString = syntaxHighlight(text, with: theme)
        XCTAssertEqual(attributedString.attribute(.font, at: 5, effectiveRange: nil) as? UIFont, outerFont)
        XCTAssertEqual(attributedString.attribute(.foregroundColor, at: 5, effectiveRange: nil) as? UIColor, .green)
    }

    func testInnerCaptureOwnFontWinsOverEnclosingFont() {
        let theme = MockTheme(fonts: ["outer": outerFont, "inner": innerFont])
        let attributedString = syntaxHighlight(text, with: theme)
        XCTAssertEqual(attributedString.attribute(.font, at: 5, effectiveRange: nil) as? UIFont, innerFont)
        // Outside the inner capture the enclosing capture's font still applies.
        XCTAssertEqual(attributedString.attribute(.font, at: 0, effectiveRange: nil) as? UIFont, outerFont)
    }

    func testCaptureWithoutEnclosingFontUsesThemeFont() {
        let theme = MockTheme(textColors: ["inner": .green])
        let attributedString = syntaxHighlight(text, with: theme)
        XCTAssertEqual(attributedString.attribute(.font, at: 5, effectiveRange: nil) as? UIFont, theme.font)
    }
}

private extension ThemeFontInheritanceTests {
    private func syntaxHighlight(_ text: String, with theme: Theme) -> NSAttributedString {
        let query = TreeSitterLanguage.Query(string: "(expression_statement) @outer (string) @inner")
        let language = TreeSitterLanguage(tree_sitter_python(), highlightsQuery: query)
        let syntaxHighlighter = StringSyntaxHighlighter(theme: theme, language: language)
        return syntaxHighlighter.syntaxHighlight(text)
    }
}
