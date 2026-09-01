import CoreText
@testable import Runestone
import UIKit
import XCTest

final class LineFragmentRendererTests: XCTestCase {
    // The text begins with a space so that a pixel can be sampled from a cell that no glyph covers.
    private let text = " let value = compute()"
    private let canvasWidth: CGFloat = 500
    private let xInLeadingSpace = 3

    func testBackgroundRectSpansTheStyledCharacters() {
        let lineFragment = makeLineFragment()
        let renderer = makeRenderer(for: lineFragment)
        let syntaxBackgroundFragment = makeSyntaxBackgroundFragment(range: NSRange(location: 4, length: 5))
        let canvasSize = CGSize(width: canvasWidth, height: lineFragment.scaledSize.height)
        let rect = renderer.rect(for: syntaxBackgroundFragment, inCanvasOfSize: canvasSize)
        XCTAssertEqual(rect.minX, CTLineGetOffsetForStringIndex(lineFragment.line, 4, nil), accuracy: 0.0001)
        XCTAssertEqual(rect.maxX, CTLineGetOffsetForStringIndex(lineFragment.line, 9, nil), accuracy: 0.0001)
        XCTAssertEqual(rect.minY, 0, accuracy: 0.0001)
        XCTAssertEqual(rect.height, lineFragment.scaledSize.height, accuracy: 0.0001)
        XCTAssertGreaterThan(rect.width, 0)
        XCTAssertLessThan(rect.maxX, canvasWidth)
    }

    func testBackgroundRectFillingLineWidthExtendsToCanvasWidth() {
        let lineFragment = makeLineFragment()
        let renderer = makeRenderer(for: lineFragment)
        let syntaxBackgroundFragment = makeSyntaxBackgroundFragment(range: NSRange(location: 4, length: 5), fillsLineWidth: true)
        let canvasSize = CGSize(width: canvasWidth, height: lineFragment.scaledSize.height)
        let rect = renderer.rect(for: syntaxBackgroundFragment, inCanvasOfSize: canvasSize)
        XCTAssertEqual(rect.minX, CTLineGetOffsetForStringIndex(lineFragment.line, 4, nil), accuracy: 0.0001)
        XCTAssertEqual(rect.maxX, canvasWidth, accuracy: 0.0001)
        XCTAssertEqual(rect.height, lineFragment.scaledSize.height, accuracy: 0.0001)
    }

    func testSyntaxBackgroundIsDrawn() {
        let lineFragment = makeLineFragment()
        let renderer = makeRenderer(for: lineFragment)
        renderer.syntaxBackgroundFragments = [
            makeSyntaxBackgroundFragment(range: NSRange(location: 0, length: text.utf16.count), color: .red, fillsLineWidth: true)
        ]
        // Sampled beyond the end of the text, which only the background reaches.
        let pixel = drawnPixel(with: renderer, atX: Int(canvasWidth) - 5)
        XCTAssertGreaterThan(pixel.red, 200)
        XCTAssertLessThan(pixel.green, 55)
        XCTAssertLessThan(pixel.blue, 55)
        XCTAssertEqual(pixel.alpha, 255)
    }

    func testStrokeIsDrawnInsideTheBackgroundBounds() {
        let lineFragment = makeLineFragment()
        let renderer = makeRenderer(for: lineFragment)
        renderer.syntaxBackgroundFragments = [
            makeSyntaxBackgroundFragment(range: NSRange(location: 0, length: text.utf16.count),
                                         color: .blue,
                                         fillsLineWidth: true,
                                         strokeColor: .red,
                                         strokeWidth: 2)
        ]
        // The bottom row is the background's own boundary row, so an inside stroke covers it
        // where a strokeless background would show the fill.
        let pixel = drawnPixel(with: renderer, atX: Int(canvasWidth) - 5)
        XCTAssertGreaterThan(pixel.red, 200)
        XCTAssertLessThan(pixel.blue, 55)
    }

    func testWithoutAStrokeTheBoundaryRowShowsTheFill() {
        let lineFragment = makeLineFragment()
        let renderer = makeRenderer(for: lineFragment)
        renderer.syntaxBackgroundFragments = [
            makeSyntaxBackgroundFragment(range: NSRange(location: 0, length: text.utf16.count),
                                         color: .blue,
                                         fillsLineWidth: true)
        ]
        let pixel = drawnPixel(with: renderer, atX: Int(canvasWidth) - 5)
        XCTAssertGreaterThan(pixel.blue, 200)
        XCTAssertLessThan(pixel.red, 55)
    }

    func testHighlightedRangeIsDrawnOnTopOfSyntaxBackground() {
        let lineFragment = makeLineFragment()
        let renderer = makeRenderer(for: lineFragment)
        renderer.syntaxBackgroundFragments = [
            makeSyntaxBackgroundFragment(range: NSRange(location: 0, length: text.utf16.count), color: .red, fillsLineWidth: true)
        ]
        renderer.highlightedRangeFragments = [
            HighlightedRangeFragment(range: NSRange(location: 0, length: text.utf16.count),
                                     containsStart: true,
                                     containsEnd: true,
                                     color: .green,
                                     cornerRadius: 0)
        ]
        // Sampled within the range of the search result, where the background is drawn underneath it.
        let pixel = drawnPixel(with: renderer, atX: xInLeadingSpace)
        XCTAssertGreaterThan(pixel.green, 200)
        XCTAssertLessThan(pixel.red, 55)
        XCTAssertLessThan(pixel.blue, 55)
        XCTAssertEqual(pixel.alpha, 255)
    }
}

private struct Pixel {
    let red: UInt8
    let green: UInt8
    let blue: UInt8
    let alpha: UInt8
}

private extension LineFragmentRendererTests {
    private func makeLineFragment() -> LineFragment {
        let attributes: [NSAttributedString.Key: Any] = [.font: UIFont.monospacedSystemFont(ofSize: 14, weight: .regular)]
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        let typesetter = CTTypesetterCreateWithAttributedString(attributedString)
        let range = NSRange(location: 0, length: attributedString.length)
        let line = CTTypesetterCreateLine(typesetter, CFRangeMake(range.location, range.length))
        var ascent: CGFloat = 0
        var descent: CGFloat = 0
        var leading: CGFloat = 0
        let width = CGFloat(CTLineGetTypographicBounds(line, &ascent, &descent, &leading))
        let size = CGSize(width: width, height: ascent + descent + leading)
        return LineFragment(id: LineFragmentID(lineId: "1", lineFragmentIndex: 0),
                            index: 0,
                            visibleRange: range,
                            line: line,
                            descent: descent,
                            baseSize: size,
                            scaledSize: size,
                            yPosition: 0)
    }

    private func makeRenderer(for lineFragment: LineFragment) -> LineFragmentRenderer {
        LineFragmentRenderer(lineFragment: lineFragment, invisibleCharacterConfiguration: InvisibleCharacterConfiguration())
    }

    private func makeSyntaxBackgroundFragment(range: NSRange,
                                              color: UIColor = .red,
                                              fillsLineWidth: Bool = false,
                                              strokeColor: UIColor? = nil,
                                              strokeWidth: CGFloat = 0) -> SyntaxBackgroundFragment {
        SyntaxBackgroundFragment(range: range,
                                 containsStart: true,
                                 containsEnd: true,
                                 style: BackgroundStyle(color: color,
                                                        cornerRadius: 0,
                                                        fillsLineWidth: fillsLineWidth,
                                                        strokeColor: strokeColor,
                                                        strokeWidth: strokeWidth))
    }

    /// Draws the line fragment to a bitmap and reads a single pixel of the drawing.
    /// - Parameters:
    ///   - renderer: Renderer to draw with.
    ///   - x: Horizontal position of the pixel to read.
    /// - Returns: The pixel at the specified position in the bottom row of the bitmap. The bottom row
    ///   is fully covered by the line fragment even when its height is not a whole number of pixels.
    private func drawnPixel(with renderer: LineFragmentRenderer, atX x: Int) -> Pixel {
        let width = Int(canvasWidth)
        let height = Int(ceil(renderer.lineFragment.scaledSize.height))
        let bytesPerRow = width * 4
        var pixels = [UInt8](repeating: 0, count: bytesPerRow * height)
        pixels.withUnsafeMutableBytes { buffer in
            guard let context = CGContext(data: buffer.baseAddress,
                                          width: width,
                                          height: height,
                                          bitsPerComponent: 8,
                                          bytesPerRow: bytesPerRow,
                                          space: CGColorSpaceCreateDeviceRGB(),
                                          bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
                return XCTFail("Cannot create the context to draw the line fragment in")
            }
            renderer.draw(to: context, inCanvasOfSize: CGSize(width: CGFloat(width), height: CGFloat(height)))
        }
        let offset = (height - 1) * bytesPerRow + x * 4
        return Pixel(red: pixels[offset], green: pixels[offset + 1], blue: pixels[offset + 2], alpha: pixels[offset + 3])
    }
}
