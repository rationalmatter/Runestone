@testable import Runestone
import UIKit

/// Theme that only styles the syntax highlighted ranges the test is interested in.
final class MockTheme: Theme {
    let font: UIFont = .monospacedSystemFont(ofSize: 14, weight: .regular)
    let textColor: UIColor = .label
    let gutterBackgroundColor: UIColor = .secondarySystemBackground
    let gutterHairlineColor: UIColor = .opaqueSeparator
    let lineNumberColor: UIColor = .secondaryLabel
    let lineNumberFont: UIFont = .monospacedSystemFont(ofSize: 14, weight: .regular)
    let selectedLineBackgroundColor: UIColor = .secondarySystemBackground
    let selectedLinesLineNumberColor: UIColor = .label
    let selectedLinesGutterBackgroundColor: UIColor = .secondarySystemBackground
    let invisibleCharactersColor: UIColor = .tertiaryLabel
    let pageGuideHairlineColor: UIColor = .opaqueSeparator
    let pageGuideBackgroundColor: UIColor = .secondarySystemBackground
    let markedTextBackgroundColor: UIColor = .systemFill

    private let textColors: [String: UIColor]
    private let backgrounds: [String: BackgroundStyle]

    init(textColors: [String: UIColor] = [:], backgrounds: [String: BackgroundStyle] = [:]) {
        self.textColors = textColors
        self.backgrounds = backgrounds
    }

    func textColor(for highlightName: String) -> UIColor? {
        textColors[highlightName]
    }

    func background(for highlightName: String) -> BackgroundStyle? {
        backgrounds[highlightName]
    }
}
