import UIKit

protocol LineFragmentControllerDelegate: AnyObject {
    func string(in controller: LineFragmentController) -> String?
    func attributedString(in controller: LineFragmentController) -> NSAttributedString?
}

final class LineFragmentController {
    weak var delegate: LineFragmentControllerDelegate?
    var lineFragment: LineFragment {
        didSet {
            if lineFragment !== oldValue {
                renderer.lineFragment = lineFragment
                updateSyntaxBackgrounds()
                lineFragmentView?.setNeedsDisplay()
            }
        }
    }
    weak var lineFragmentView: LineFragmentView? {
        didSet {
            if lineFragmentView !== oldValue || lineFragmentView?.renderer !== renderer {
                lineFragmentView?.renderer = renderer
            }
        }
    }
    var markedRange: NSRange? {
        get {
            renderer.markedRange
        }
        set {
            if newValue != renderer.markedRange {
                renderer.markedRange = newValue
                lineFragmentView?.setNeedsDisplay()
            }
        }
    }
    var markedTextBackgroundColor: UIColor {
        get {
            renderer.markedTextBackgroundColor
        }
        set {
            if newValue != renderer.markedTextBackgroundColor {
                renderer.markedTextBackgroundColor = newValue
                lineFragmentView?.setNeedsDisplay()
            }
        }
    }
    var markedTextBackgroundCornerRadius: CGFloat {
        get {
            renderer.markedTextBackgroundCornerRadius
        }
        set {
            if newValue != renderer.markedTextBackgroundCornerRadius {
                renderer.markedTextBackgroundCornerRadius = newValue
                lineFragmentView?.setNeedsDisplay()
            }
        }
    }
    var highlightedRangeFragments: [HighlightedRangeFragment] {
        get {
            renderer.highlightedRangeFragments
        }
        set {
            if newValue != renderer.highlightedRangeFragments {
                renderer.highlightedRangeFragments = newValue
                lineFragmentView?.setNeedsDisplay()
            }
        }
    }

    private let renderer: LineFragmentRenderer

    init(lineFragment: LineFragment, invisibleCharacterConfiguration: InvisibleCharacterConfiguration) {
        self.lineFragment = lineFragment
        self.renderer = LineFragmentRenderer(lineFragment: lineFragment, invisibleCharacterConfiguration: invisibleCharacterConfiguration)
        self.renderer.delegate = self
    }

    /// Rebuilds the backgrounds of the syntax highlighted ranges in the line fragment.
    ///
    /// The backgrounds are read from the attributes of the line, so they are rebuilt when the line
    /// fragment changes and when the line may have been restyled, e.g. after syntax highlighting
    /// a line asynchronously.
    func updateSyntaxBackgrounds() {
        let syntaxBackgroundFragments: [SyntaxBackgroundFragment]
        if let attributedString = delegate?.attributedString(in: self) {
            syntaxBackgroundFragments = SyntaxBackgroundFragment.fragments(in: attributedString,
                                                                          forLineFragmentRange: lineFragment.visibleRange)
        } else {
            syntaxBackgroundFragments = []
        }
        if syntaxBackgroundFragments != renderer.syntaxBackgroundFragments {
            renderer.syntaxBackgroundFragments = syntaxBackgroundFragments
            lineFragmentView?.setNeedsDisplay()
        }
    }
}

// MARK: - LineFragmentRendererDelegate
extension LineFragmentController: LineFragmentRendererDelegate {
    func string(in lineFragmentRenderer: LineFragmentRenderer) -> String? {
        delegate?.string(in: self)
    }
}
