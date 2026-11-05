import SwiftUI
import UIKit

struct LegacyComposerField: UIViewRepresentable {
    @Binding var input: ComposerText
    @Binding var isFocused: Bool
    let placeholder: String
    let submit: () -> Void

    func makeUIView(context: Context) -> ComposerTextView {
        let view = ComposerTextView()
        view.delegate = context.coordinator
        view.backgroundColor = .clear
        view.textColor = .label
        view.font = .preferredFont(forTextStyle: .body)
        view.adjustsFontForContentSizeCategory = true
        view.textContainerInset = .zero
        view.textContainer.lineFragmentPadding = 0
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return view
    }

    func updateUIView(_ view: ComposerTextView, context: Context) {
        let coordinator = context.coordinator
        coordinator.parent = self
        view.accessibilityLabel = placeholder
        view.onCommandReturn = submit
        let replacing = coordinator.replacementVersion != input.replacementVersion
        coordinator.updating = true
        if replacing || (view.markedTextRange == nil && view.text != input.text) {
            view.text = input.text
            view.selectedRange = input.legacySelection ?? NSRange(location: input.text.utf16.count, length: 0)
        } else if view.markedTextRange == nil, let selection = input.legacySelection,
                  NSMaxRange(selection) <= view.text.utf16.count, view.selectedRange != selection {
            view.selectedRange = selection
        }
        coordinator.replacementVersion = input.replacementVersion
        coordinator.updating = false
        if isFocused && !view.isFirstResponder {
            view.becomeFirstResponder()
        } else if !isFocused && view.isFirstResponder {
            view.resignFirstResponder()
        }
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: ComposerTextView, context: Context) -> CGSize? {
        guard let width = proposal.width, width > 0 else { return nil }
        let lineHeight = uiView.font?.lineHeight ?? 22
        let height = uiView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude)).height
        return CGSize(width: width, height: min(max(lineHeight, height), lineHeight * 8))
    }

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: LegacyComposerField
        var replacementVersion = -1
        var updating = false

        init(_ parent: LegacyComposerField) { self.parent = parent }

        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            !(text == "\n" && textView.text.isEmpty && textView.markedTextRange == nil)
        }

        func textViewDidChange(_ textView: UITextView) {
            guard !updating else { return }
            parent.input.text = textView.text
            parent.input.legacySelection = textView.selectedRange
            textView.invalidateIntrinsicContentSize()
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            guard !updating, textView.markedTextRange == nil else { return }
            parent.input.legacySelection = textView.selectedRange
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            if !parent.isFocused { parent.isFocused = true }
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            if parent.isFocused { parent.isFocused = false }
        }
    }
}

final class ComposerTextView: UITextView {
    var onCommandReturn: (() -> Void)?

    override var keyCommands: [UIKeyCommand]? {
        let send = UIKeyCommand(input: "\r", modifierFlags: .command, action: #selector(sendMessage))
        send.wantsPriorityOverSystemBehavior = true
        return [send] + (super.keyCommands ?? [])
    }

    @objc private func sendMessage() {
        guard markedTextRange == nil else { return }
        onCommandReturn?()
    }
}
