import SwiftUI
import Testing
@testable import CodyncUI

@Suite struct ComposerTextTests {

    @available(iOS 18.0, *)
    @MainActor @Test(arguments: ["", "1", "中文", "👨‍👩‍👧‍👦", "replacement text"])
    func replacingComposerTextDiscardsPreviousSelection(_ replacement: String) {
        var input = ComposerText(text: "previous draft")
        input.selection = TextSelection(insertionPoint: input.text.endIndex)

        input.replace(with: replacement)

        #expect(input.text == replacement)
        #expect(input.selection == nil)
    }

    @available(iOS 18.0, *)
    @MainActor @Test func composerReturnReplacesSelectionAndMovesCursorAfterNewline() {
        var input = ComposerText(text: "A👨‍👩‍👧‍👦中B")
        let start = input.text.index(after: input.text.startIndex)
        let end = input.text.index(before: input.text.endIndex)
        input.selection = TextSelection(range: start..<end)

        input.insertNewline()

        #expect(input.text == "A\nB")
        guard case .selection(let range) = input.selection?.indices else {
            Issue.record("Expected an insertion point after Return")
            return
        }
        #expect(range.isEmpty)
        #expect(range.lowerBound == input.text.index(input.text.startIndex, offsetBy: 2))
    }

    @available(iOS 18.0, *)
    @MainActor @Test func composerReturnAfterCarriageReturnKeepsValidCursor() {
        var input = ComposerText(text: "a\r")
        input.insertNewline()
        #expect(input.text == "a\r\n")
        guard case .selection(let range) = input.selection?.indices else {
            Issue.record("Expected a cursor at the end")
            return
        }
        #expect(range.lowerBound == input.text.endIndex)
    }

    @available(iOS 18.0, *)
    @MainActor @Test func composerReturnAfterSendingDoesNotRestoreOldDraft() {
        var input = ComposerText(text: "1")
        input.selection = TextSelection(insertionPoint: input.text.endIndex)
        input.replace(with: "")
        input.insertNewline()
        #expect(input.text.isEmpty)
        #expect(input.selection == nil)
    }

    @MainActor @Test func replacingLegacyComposerTextDiscardsUTF16Selection() {
        var input = ComposerText(text: "A👨‍👩‍👧‍👦中B")
        input.legacySelection = NSRange(location: 1, length: 12)
        let version = input.replacementVersion
        input.replace(with: "@Reviewer ")
        #expect(input.text == "@Reviewer ")
        #expect(input.legacySelection == nil)
        #expect(input.replacementVersion != version)
    }

    @MainActor @Test func legacyComposerReturnReplacesUTF16Selection() {
        var input = ComposerText(text: "A👨‍👩‍👧‍👦中B")
        input.legacySelection = NSRange(location: 1, length: 12)
        input.insertNewline()
        #expect(input.text == "A\nB")
        if #available(iOS 18.0, *) {
            guard case .selection(let range) = input.selection?.indices else {
                Issue.record("Expected an insertion point after Return")
                return
            }
            #expect(NSRange(range, in: input.text) == NSRange(location: 2, length: 0))
        } else {
            #expect(input.legacySelection == NSRange(location: 2, length: 0))
        }
    }

}
