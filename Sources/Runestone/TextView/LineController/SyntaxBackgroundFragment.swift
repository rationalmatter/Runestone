import UIKit

/// A background to be drawn behind a range of text in a line fragment.
///
/// Line fragments are drawn separately, so a styled range wrapping onto multiple line fragments is
/// represented by one fragment per line fragment. ``containsStart`` and ``containsEnd`` tell which of
/// them hold the beginning and the end of the styled range so that only the outer corners are rounded.
struct SyntaxBackgroundFragment: Equatable {
    /// Range of the background. The range is local to the line containing the line fragment.
    let range: NSRange
    /// Whether the range contains the beginning of the styled range.
    let containsStart: Bool
    /// Whether the range contains the end of the styled range.
    let containsEnd: Bool
    /// Style to draw the background with.
    let style: BackgroundStyle
    /// Color to fill the background with.
    var color: UIColor {
        style.color
    }
    /// Corner radius of the background.
    var cornerRadius: CGFloat {
        style.cornerRadius
    }
    /// Whether the background extends to the trailing edge of the canvas.
    var fillsLineWidth: Bool {
        style.fillsLineWidth
    }

    var strokeColor: UIColor? {
        style.strokeColor
    }

    var strokeWidth: CGFloat {
        style.strokeWidth
    }

    var verticalInset: CGFloat {
        style.verticalInset
    }
    /// Corners to round when drawing the background.
    var roundedCorners: UIRectCorner {
        if containsStart && containsEnd {
            return .allCorners
        } else if containsStart {
            return [.topLeft, .bottomLeft]
        } else if containsEnd {
            return [.topRight, .bottomRight]
        } else {
            return []
        }
    }
}

extension SyntaxBackgroundFragment {
    /// Creates the backgrounds to be drawn in a line fragment.
    /// - Parameters:
    ///   - attributedString: Attributed string of the line containing the line fragment.
    ///   - range: Range of the line fragment. The range is local to the line.
    /// - Returns: Backgrounds to be drawn in the line fragment.
    static func fragments(in attributedString: NSAttributedString, forLineFragmentRange range: NSRange) -> [SyntaxBackgroundFragment] {
        let stringRange = NSRange(location: 0, length: attributedString.length)
        let cappedRange = range.capped(to: stringRange)
        guard cappedRange.length > 0 else {
            return []
        }
        var runs: [(range: NSRange, style: BackgroundStyle)] = []
        attributedString.enumerateAttribute(.syntaxBackground, in: cappedRange) { value, attributeRange, _ in
            guard let style = value as? BackgroundStyle, attributeRange.length > 0 else {
                return
            }
            // A run may be split by an unrelated attribute, for example the color of a capture nested
            // in the one carrying the background, so adjacent runs of the same style are joined.
            if let previousRun = runs.last, previousRun.style == style, previousRun.range.upperBound == attributeRange.lowerBound {
                runs[runs.count - 1].range = NSRange(location: previousRun.range.lowerBound,
                                                     length: previousRun.range.length + attributeRange.length)
            } else {
                runs.append((attributeRange, style))
            }
        }
        return runs.map { run in
            // The styled range continues outside the line fragment when the character just outside it
            // carries the same style. In that case this line fragment does not contain that end of the
            // styled range and the corners on that side are left square.
            let continuesBefore = style(in: attributedString, at: run.range.lowerBound - 1) == run.style
            let continuesAfter = style(in: attributedString, at: run.range.upperBound) == run.style
            let containsStart = run.range.lowerBound > cappedRange.lowerBound || !continuesBefore
            let containsEnd = run.range.upperBound < cappedRange.upperBound || !continuesAfter
            return SyntaxBackgroundFragment(range: run.range, containsStart: containsStart, containsEnd: containsEnd, style: run.style)
        }
    }

    private static func style(in attributedString: NSAttributedString, at location: Int) -> BackgroundStyle? {
        guard location >= 0 && location < attributedString.length else {
            return nil
        }
        return attributedString.attribute(.syntaxBackground, at: location, effectiveRange: nil) as? BackgroundStyle
    }
}
