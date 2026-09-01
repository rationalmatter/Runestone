import UIKit

extension NSMutableAttributedString {
    /// Mirrors syntax background fill colors to the standard .backgroundColor attribute.
    ///
    /// TextView draws backgrounds from the internal ``NSAttributedString/Key/syntaxBackground``
    /// attribute, which standard text components like UILabel and UITextView do not recognize.
    /// Strings leaving Runestone through a public API get the fill color mirrored so backgrounds
    /// remain visible. The corner radius and fillsLineWidth of ``BackgroundStyle`` only apply when
    /// the string is displayed in a TextView.
    func applyExportableSyntaxBackgrounds() {
        let range = NSRange(location: 0, length: length)
        beginEditing()
        enumerateAttribute(.syntaxBackground, in: range) { value, attributeRange, _ in
            if let style = value as? BackgroundStyle {
                addAttribute(.backgroundColor, value: style.color, range: attributeRange)
            }
        }
        endEditing()
    }
}
