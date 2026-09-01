import UIKit

/// A background drawn behind text matching a capture sequence.
///
/// Returned from ``Theme/background(for:)`` to give a syntax highlighted range a background,
/// for example a chip behind inline code or a band behind a fenced code block.
///
/// The background is drawn beneath the text of a line fragment and beneath both highlighted
/// ranges and marked text, so it never obscures a search result or text being composed with
/// an input method.
public struct BackgroundStyle: Equatable {
    /// Color to fill the background with.
    public var color: UIColor
    /// Corner radius of the background.
    ///
    /// A value of zero or less means that the background has square corners. Defaults to 0.
    ///
    /// A range that wraps onto multiple line fragments only rounds the corners at the beginning
    /// and the end of the range. Ranges that are highlighted per line, for example a fenced code
    /// block spanning multiple lines, should use a corner radius of zero. Each of the lines is
    /// styled separately and a corner radius would scallop the boundary between them.
    public var cornerRadius: CGFloat
    /// Whether the background extends to the trailing edge of the container.
    ///
    /// Set this to `true` for backgrounds that should read as a band spanning the width of the
    /// text view, for example a fenced code block, and `false` for backgrounds that hug the text,
    /// for example inline code. Defaults to `false`.
    public var fillsLineWidth: Bool
    /// Color to stroke the background's edge with, or `nil` for no stroke. Defaults to `nil`.
    ///
    /// The stroke is drawn inside the background's bounds, so backgrounds on consecutive lines
    /// stay visually separate instead of merging where they touch. A background that wraps onto
    /// multiple line fragments strokes each fragment's rect separately.
    public var strokeColor: UIColor?
    /// Width of the stroke. A value of zero or less means a one-pixel hairline. Defaults to 0.
    public var strokeWidth: CGFloat

    /// Creates a background to be drawn behind text matching a capture sequence.
    /// - Parameters:
    ///   - color: Color to fill the background with.
    ///   - cornerRadius: Corner radius of the background. A value of zero or less means that the background has square corners.
    ///   - fillsLineWidth: Whether the background extends to the trailing edge of the container.
    ///   - strokeColor: Color to stroke the background's edge with, or `nil` for no stroke.
    ///   - strokeWidth: Width of the stroke. A value of zero or less means a one-pixel hairline.
    public init(color: UIColor,
                cornerRadius: CGFloat = 0,
                fillsLineWidth: Bool = false,
                strokeColor: UIColor? = nil,
                strokeWidth: CGFloat = 0) {
        self.color = color
        self.cornerRadius = cornerRadius
        self.fillsLineWidth = fillsLineWidth
        self.strokeColor = strokeColor
        self.strokeWidth = strokeWidth
    }
}
