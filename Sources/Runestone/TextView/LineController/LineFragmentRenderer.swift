import CoreText
import UIKit

protocol LineFragmentRendererDelegate: AnyObject {
    func string(in lineFragmentRenderer: LineFragmentRenderer) -> String?
}

final class LineFragmentRenderer {
    private enum HorizontalPosition {
        case character(Int)
        case endOfLine
    }

    weak var delegate: LineFragmentRendererDelegate?
    var lineFragment: LineFragment
    let invisibleCharacterConfiguration: InvisibleCharacterConfiguration
    var markedRange: NSRange?
    var markedTextBackgroundColor: UIColor = .systemFill
    var markedTextBackgroundCornerRadius: CGFloat = 0
    var highlightedRangeFragments: [HighlightedRangeFragment] = []
    var syntaxBackgroundFragments: [SyntaxBackgroundFragment] = []

    private var showInvisibleCharacters: Bool {
        invisibleCharacterConfiguration.showTabs
            || invisibleCharacterConfiguration.showSpaces
            || invisibleCharacterConfiguration.showLineBreaks
            || invisibleCharacterConfiguration.showSoftLineBreaks
    }

    init(lineFragment: LineFragment, invisibleCharacterConfiguration: InvisibleCharacterConfiguration) {
        self.lineFragment = lineFragment
        self.invisibleCharacterConfiguration = invisibleCharacterConfiguration
    }

    func draw(to context: CGContext, inCanvasOfSize canvasSize: CGSize) {
        // Backgrounds of syntax highlighted ranges are decoration and are drawn first so that
        // search results and marked text are drawn on top of them.
        drawSyntaxBackgrounds(to: context, inCanvasOfSize: canvasSize)
        drawHighlightedRanges(to: context, inCanvasOfSize: canvasSize)
        drawMarkedRange(to: context)
        drawInvisibleCharacters()
        drawText(to: context)
    }

    /// Rect to fill with the background of a syntax highlighted range.
    /// - Parameters:
    ///   - syntaxBackgroundFragment: Background to compute the rect of.
    ///   - canvasSize: Size of the canvas the line fragment is drawn in.
    /// - Returns: Rect of the background, relative to the line fragment.
    func rect(for syntaxBackgroundFragment: SyntaxBackgroundFragment, inCanvasOfSize canvasSize: CGSize) -> CGRect {
        let range = syntaxBackgroundFragment.range
        let startX = CTLineGetOffsetForStringIndex(lineFragment.line, range.lowerBound, nil)
        let endX: CGFloat
        if syntaxBackgroundFragment.fillsLineWidth {
            endX = canvasSize.width
        } else {
            endX = CTLineGetOffsetForStringIndex(lineFragment.line, range.upperBound, nil)
        }
        return CGRect(x: startX, y: 0, width: endX - startX, height: lineFragment.scaledSize.height)
    }
}

private extension LineFragmentRenderer {
    private func drawSyntaxBackgrounds(to context: CGContext, inCanvasOfSize canvasSize: CGSize) {
        guard !syntaxBackgroundFragments.isEmpty else {
            return
        }
        context.saveGState()
        for syntaxBackgroundFragment in syntaxBackgroundFragments {
            let rect = rect(for: syntaxBackgroundFragment, inCanvasOfSize: canvasSize)
            let roundedCorners = syntaxBackgroundFragment.roundedCorners
            let cornerRadius = syntaxBackgroundFragment.cornerRadius
            context.setFillColor(syntaxBackgroundFragment.color.cgColor)
            if !roundedCorners.isEmpty && cornerRadius > 0 {
                let cornerRadii = CGSize(width: cornerRadius, height: cornerRadius)
                let bezierPath = UIBezierPath(roundedRect: rect, byRoundingCorners: roundedCorners, cornerRadii: cornerRadii)
                context.addPath(bezierPath.cgPath)
                context.fillPath()
            } else {
                context.fill(rect)
            }
            if let strokeColor = syntaxBackgroundFragment.strokeColor {
                strokeSyntaxBackground(rect,
                                       to: context,
                                       color: strokeColor,
                                       width: syntaxBackgroundFragment.strokeWidth,
                                       roundedCorners: roundedCorners,
                                       cornerRadius: cornerRadius)
            }
        }
        context.restoreGState()
    }

    /// Strokes the edge of a syntax background, inside its bounds.
    ///
    /// The path is inset by half the stroke width so the stroke does not spill outside the
    /// background's rect — backgrounds on consecutive lines touch, and a centered stroke would
    /// overlap the neighbor.
    private func strokeSyntaxBackground(_ rect: CGRect,
                                        to context: CGContext,
                                        color: UIColor,
                                        width: CGFloat,
                                        roundedCorners: UIRectCorner,
                                        cornerRadius: CGFloat) {
        // UITraitCollection.current carries the display scale during UIView.draw; a bare context,
        // as in tests, reports 0 and falls back to a one-point hairline.
        let displayScale = max(UITraitCollection.current.displayScale, 1)
        let lineWidth = width > 0 ? width : 1 / displayScale
        let strokeRect = rect.insetBy(dx: lineWidth / 2, dy: lineWidth / 2)
        guard strokeRect.width > 0 && strokeRect.height > 0 else {
            return
        }
        context.setStrokeColor(color.cgColor)
        context.setLineWidth(lineWidth)
        if !roundedCorners.isEmpty && cornerRadius > 0 {
            let insetCornerRadius = max(cornerRadius - lineWidth / 2, 0)
            let cornerRadii = CGSize(width: insetCornerRadius, height: insetCornerRadius)
            let bezierPath = UIBezierPath(roundedRect: strokeRect, byRoundingCorners: roundedCorners, cornerRadii: cornerRadii)
            context.addPath(bezierPath.cgPath)
            context.strokePath()
        } else {
            context.stroke(strokeRect)
        }
    }

    private func drawHighlightedRanges(to context: CGContext, inCanvasOfSize canvasSize: CGSize) {
        guard !highlightedRangeFragments.isEmpty else {
            return
        }
        context.saveGState()
        for highlightedRange in highlightedRangeFragments {
            let startX = CTLineGetOffsetForStringIndex(lineFragment.line, highlightedRange.range.lowerBound, nil)
            let endX: CGFloat
            if shouldHighlightLineEnding(for: highlightedRange) {
                endX = canvasSize.width
            } else {
                endX = CTLineGetOffsetForStringIndex(lineFragment.line, highlightedRange.range.upperBound, nil)
            }
            let rect = CGRect(x: startX, y: 0, width: endX - startX, height: lineFragment.scaledSize.height)
            let roundedCorners = highlightedRange.roundedCorners
            context.setFillColor(highlightedRange.color.cgColor)
            if !roundedCorners.isEmpty && highlightedRange.cornerRadius > 0 {
                let cornerRadii = CGSize(width: highlightedRange.cornerRadius, height: highlightedRange.cornerRadius)
                let bezierPath = UIBezierPath(roundedRect: rect, byRoundingCorners: roundedCorners, cornerRadii: cornerRadii)
                context.addPath(bezierPath.cgPath)
                context.fillPath()
            } else {
                context.fill(rect)
            }
        }
        context.restoreGState()
    }

    private func drawMarkedRange(to context: CGContext) {
        if let markedRange = markedRange {
            context.saveGState()
            let startX = CTLineGetOffsetForStringIndex(lineFragment.line, markedRange.lowerBound, nil)
            let endX = CTLineGetOffsetForStringIndex(lineFragment.line, markedRange.upperBound, nil)
            let rect = CGRect(x: startX, y: 0, width: endX - startX, height: lineFragment.scaledSize.height)
            context.setFillColor(markedTextBackgroundColor.cgColor)
            if markedTextBackgroundCornerRadius > 0 {
                let cornerRadius = markedTextBackgroundCornerRadius
                let path = CGPath(roundedRect: rect, cornerWidth: cornerRadius, cornerHeight: cornerRadius, transform: nil)
                context.addPath(path)
                context.fillPath()
            } else {
                context.fill(rect)
            }
            context.restoreGState()
        }
    }

    private func drawInvisibleCharacters() {
        if showInvisibleCharacters, let string = delegate?.string(in: self) {
            drawInvisibleCharacters(in: string)
        }
    }

    private func drawText(to context: CGContext) {
        context.saveGState()
        context.textMatrix = .identity
        context.translateBy(x: 0, y: lineFragment.scaledSize.height)
        context.scaleBy(x: 1, y: -1)
        let yPosition = lineFragment.descent + (lineFragment.scaledSize.height - lineFragment.baseSize.height) / 2
        context.textPosition = CGPoint(x: 0, y: yPosition)
        CTLineDraw(lineFragment.line, context)
        context.restoreGState()
    }

    private func drawInvisibleCharacters(in string: String) {
        var indexInLineFragment = 0
        for substring in string {
            let indexInLine = lineFragment.visibleRange.location + indexInLineFragment
            indexInLineFragment += substring.utf16.count
            if invisibleCharacterConfiguration.showSpaces && substring == Symbol.Character.space {
                draw(invisibleCharacterConfiguration.spaceSymbol, at: .character(indexInLine))
            } else if invisibleCharacterConfiguration.showNonBreakingSpaces && substring == Symbol.Character.nonBreakingSpace {
                draw(invisibleCharacterConfiguration.nonBreakingSpaceSymbol, at: .character(indexInLine))
            } else if invisibleCharacterConfiguration.showTabs && substring == Symbol.Character.tab {
                draw(invisibleCharacterConfiguration.tabSymbol, at: .character(indexInLine))
            } else if invisibleCharacterConfiguration.showLineBreaks && isLineBreak(substring) {
                draw(invisibleCharacterConfiguration.lineBreakSymbol, at: .endOfLine)
            } else if invisibleCharacterConfiguration.showSoftLineBreaks && substring == Symbol.Character.lineSeparator {
                draw(invisibleCharacterConfiguration.softLineBreakSymbol, at: .endOfLine)
            }
        }
    }

    private func draw(_ symbol: String, at horizontalPosition: HorizontalPosition) {
        let attrs: [NSAttributedString.Key: Any] = [
            .foregroundColor: invisibleCharacterConfiguration.textColor,
            .font: invisibleCharacterConfiguration.font
        ]
        let size = symbol.size(withAttributes: attrs)
        let xPosition = xPosition(for: horizontalPosition)
        let yPosition = (lineFragment.scaledSize.height - size.height) / 2
        let rect = CGRect(x: xPosition, y: yPosition, width: size.width, height: size.height)
        symbol.draw(in: rect, withAttributes: attrs)
    }

    private func xPosition(for horizontalPosition: HorizontalPosition) -> CGFloat {
        switch horizontalPosition {
        case .character(let index):
            return CTLineGetOffsetForStringIndex(lineFragment.line, index, nil)
        case .endOfLine:
            return CGFloat(CTLineGetTypographicBounds(lineFragment.line, nil, nil, nil))
        }
    }

    private func shouldHighlightLineEnding(for highlightedRangeFragment: HighlightedRangeFragment) -> Bool {
        guard highlightedRangeFragment.range.upperBound == lineFragment.range.upperBound else {
            return false
        }
        guard let string = delegate?.string(in: self), let lastCharacter = string.last else {
            return false
        }
        return isLineBreak(lastCharacter)
    }

    private func isLineBreak(_ string: String.Element) -> Bool {
        string == Symbol.Character.lineFeed || string == Symbol.Character.carriageReturn || string == Symbol.Character.carriageReturnLineFeed
    }
}
