import SwiftUI

/// Text and its selection travel together when the composer replaces a draft.
struct ComposerText {
    var text: String
    var legacySelection: NSRange?
    private(set) var replacementVersion = 0
    private var selectionStorage: Any?

    init(text: String = "") {
        self.text = text
    }

    @available(iOS 18.0, *)
    var selection: TextSelection? {
        get { selectionStorage as? TextSelection }
        set { selectionStorage = newValue }
    }

    mutating func replace(with replacement: String) {
        // iOS 18 converts the old selection to UTF-16 offsets during the next field
        // update. Clearing or shortening text without clearing its indices can trap.
        selectionStorage = nil
        legacySelection = nil
        replacementVersion &+= 1
        text = replacement
    }

    mutating func insertNewline() {
        guard !text.isEmpty else { return }
        let range: Range<String.Index>
        if #available(iOS 18.0, *), case .selection(let selected) = selection?.indices,
           selected.upperBound <= text.endIndex {
            range = selected
        } else {
            range = legacySelection.flatMap { Range($0, in: text) } ?? text.endIndex..<text.endIndex
        }
        // A newline after a lone carriage return forms one Character; count scalars.
        let offset = text.unicodeScalars.distance(from: text.startIndex, to: range.lowerBound)
        var replacement = text
        replacement.replaceSubrange(range, with: "\n")
        replace(with: replacement)
        let insertion = text.unicodeScalars.index(text.startIndex, offsetBy: offset + 1)
        if #available(iOS 18.0, *) {
            selection = TextSelection(insertionPoint: insertion)
        } else {
            legacySelection = NSRange(insertion..<insertion, in: text)
        }
    }
}
