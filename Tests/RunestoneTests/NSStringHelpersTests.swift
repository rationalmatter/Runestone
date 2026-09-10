@testable import Runestone
import XCTest

final class NSStringHelpersTests: XCTestCase {
    func testByteCountOfLetter() {
        let str = "H" as NSString
        XCTAssertEqual(str.byteCount, 2)
    }

    func testByteCountOfMultipleLetter() {
        let str = "Hello" as NSString
        XCTAssertEqual(str.byteCount, 10)
    }

    func testByteCountOfEmoji() {
        let str = "🥳" as NSString
        XCTAssertEqual(str.byteCount, 4)
    }

    func testByteCountOfMultipleEmojis() {
        let str = "🥳🥳" as NSString
        XCTAssertEqual(str.byteCount, 8)
    }

    func testByteCountOfComposedEmoji() {
        let str = "👨‍👩‍👧‍👦" as NSString
        XCTAssertEqual(str.byteCount, 22)
    }

    func testComposedCharacterSequenceOfFirstLetter() {
        let str = "Hello\r\nWorld" as NSString
        let range = str.customRangeOfComposedCharacterSequence(at: 0)
        XCTAssertEqual(range, NSRange(location: 0, length: 1))
    }

    func testComposedCharacterSequenceOfSecondLetter() {
        let str = "Hello\r\nWorld" as NSString
        let range = str.customRangeOfComposedCharacterSequence(at: 1)
        XCTAssertEqual(range, NSRange(location: 1, length: 1))
    }

    func testComposedCharacterSequenceOfCRLF() {
        let str = "Hello\r\nWorld" as NSString
        let range = str.customRangeOfComposedCharacterSequence(at: 6)
        XCTAssertEqual(range, NSRange(location: 5, length: 2))
    }

    func testComposedCharacterSequenceAtEndOfString() {
        let str = "Hello" as NSString
        let range = str.customRangeOfComposedCharacterSequence(at: str.length)
        XCTAssertEqual(range, NSRange(location: 5, length: 0))
    }

    func testComposedCharacterSequenceAfterEndOfString() {
        let str = "Hello" as NSString
        let range = str.customRangeOfComposedCharacterSequence(at: str.length + 1)
        XCTAssertEqual(range, NSRange(location: 5, length: 0))
    }

    func testComposedCharacterSequenceAfterEndOfStringEndingInCRLF() {
        let str = "Hello\r\n" as NSString
        let range = str.customRangeOfComposedCharacterSequence(at: str.length + 10)
        XCTAssertEqual(range, NSRange(location: 7, length: 0))
    }

    func testComposedCharacterSequenceBeforeBeginningOfString() {
        let str = "Hello" as NSString
        let range = str.customRangeOfComposedCharacterSequence(at: -1)
        XCTAssertEqual(range, NSRange(location: 0, length: 1))
    }

    func testComposedCharacterSequenceAfterEndOfEmptyString() {
        let str = "" as NSString
        let range = str.customRangeOfComposedCharacterSequence(at: 1)
        XCTAssertEqual(range, NSRange(location: 0, length: 0))
    }

    func testComposedCharacterSequencesOfRangeExtendingBeyondEndOfString() {
        let str = "Hello" as NSString
        let range = str.customRangeOfComposedCharacterSequences(for: NSRange(location: 3, length: 5))
        XCTAssertEqual(range, NSRange(location: 3, length: 2))
    }
}
