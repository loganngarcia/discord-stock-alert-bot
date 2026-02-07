//
//  FormattedTextField.swift
//  Stockup
//
//  Created by Assistant
//

import SwiftUI
import AppKit

struct FormattedTextField: NSViewRepresentable {
    @Binding var text: String
    let placeholder: String
    var onSubmit: (() -> Void)? = nil
    
    func makeNSView(context: Context) -> NSScrollView {
        let scrollView = NSTextView.scrollableTextView()
        let textView = scrollView.documentView as! NSTextView
        
        textView.delegate = context.coordinator
        textView.isEditable = true
        textView.isSelectable = true
        textView.isFieldEditor = false
        textView.font = NSFont.systemFont(ofSize: 14)
        textView.textColor = .labelColor
        textView.backgroundColor = .clear
        textView.insertionPointColor = .labelColor
        textView.isAutomaticQuoteSubstitutionEnabled = false
        textView.isAutomaticDashSubstitutionEnabled = false
        
        // Set up placeholder
        if text.isEmpty {
            textView.string = placeholder
            textView.textColor = .placeholderTextColor
            context.coordinator.isShowingPlaceholder = true
        } else {
            context.coordinator.isShowingPlaceholder = false
        }
        
        return scrollView
    }
    
    func updateNSView(_ nsView: NSScrollView, context: Context) {
        let textView = nsView.documentView as! NSTextView
        context.coordinator.parent = self // Update parent reference
        
        // Only update if text actually changed (to avoid cursor jumping)
        if textView.string != text && !text.isEmpty {
            context.coordinator.isShowingPlaceholder = false
            updateAttributedText(textView, text: text)
        } else if text.isEmpty && !context.coordinator.isShowingPlaceholder {
            textView.string = placeholder
            textView.textColor = .placeholderTextColor
            context.coordinator.isShowingPlaceholder = true
        }
    }
    
    private func updateAttributedText(_ textView: NSTextView, text: String) {
        let attributedString = NSMutableAttributedString(string: text)
        let fullRange = NSRange(location: 0, length: text.count)
        
        // Set default attributes
        attributedString.addAttributes([
            .font: NSFont.systemFont(ofSize: 14),
            .foregroundColor: NSColor.labelColor
        ], range: fullRange)
        
        // Find and format mentions
        let pattern = "@([A-Z0-9.]+)"
        if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
            let matches = regex.matches(in: text, options: [], range: fullRange)
            for match in matches {
                // Format mention as bold blue
                attributedString.addAttributes([
                    .font: NSFont.boldSystemFont(ofSize: 14),
                    .foregroundColor: NSColor.systemBlue
                ], range: match.range)
            }
        }
        
        // Preserve cursor position
        let selectedRange = textView.selectedRange()
        textView.textStorage?.setAttributedString(attributedString)
        
        // Restore cursor position if it's still valid
        if selectedRange.location <= text.count {
            textView.setSelectedRange(selectedRange)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, NSTextViewDelegate {
        var parent: FormattedTextField
        var shouldCallOnSubmit = false
        var isShowingPlaceholder = false
        
        init(_ parent: FormattedTextField) {
            self.parent = parent
        }
        
        func textDidChange(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            
            var newText = textView.string
            
            // If placeholder is showing and user is typing, remove placeholder from text
            if isShowingPlaceholder {
                // Remove placeholder text if it appears in the string
                if newText.contains(parent.placeholder) {
                    newText = newText.replacingOccurrences(of: parent.placeholder, with: "")
                    textView.string = newText
                }
                // Clear placeholder state
                isShowingPlaceholder = false
                textView.textColor = .labelColor
            }
            
            // Handle empty text - show placeholder
            if newText.isEmpty {
                textView.string = parent.placeholder
                textView.textColor = .placeholderTextColor
                isShowingPlaceholder = true
                parent.text = ""
                return
            }
            
            // Update binding with actual text (never include placeholder)
            if parent.text != newText {
                parent.text = newText
            }
            
            // Update formatting
            DispatchQueue.main.async {
                self.updateFormatting(textView)
            }
        }
        
        func textViewDidChangeSelection(_ notification: Notification) {
            guard let textView = notification.object as? NSTextView else { return }
            
            // Clear placeholder when user clicks/focuses on the textView
            if isShowingPlaceholder && textView.string == parent.placeholder {
                textView.string = ""
                textView.textColor = .labelColor
                isShowingPlaceholder = false
                parent.text = ""
            }
        }
        
        func textView(_ textView: NSTextView, doCommandBy commandSelector: Selector) -> Bool {
            // Clear placeholder when user starts typing (before textDidChange is called)
            if isShowingPlaceholder && textView.string == parent.placeholder {
                textView.string = ""
                textView.textColor = .labelColor
                isShowingPlaceholder = false
                parent.text = ""
            }
            
            if commandSelector == #selector(NSResponder.insertNewline(_:)) {
                // Handle Enter key - call onSubmit if provided
                if let onSubmit = parent.onSubmit {
                    DispatchQueue.main.async {
                        onSubmit()
                    }
                    return true // Prevent default newline behavior
                }
                return false // Let default behavior handle it
            }
            return false
        }
        
        
        private func updateFormatting(_ textView: NSTextView) {
            let text = textView.string
            if text.isEmpty || text == parent.placeholder || isShowingPlaceholder { return }
            
            updateAttributedText(textView, text: text)
        }
        
        private func updateAttributedText(_ textView: NSTextView, text: String) {
            let attributedString = NSMutableAttributedString(string: text)
            let fullRange = NSRange(location: 0, length: text.count)
            
            // Set default attributes
            attributedString.addAttributes([
                .font: NSFont.systemFont(ofSize: 14),
                .foregroundColor: NSColor.labelColor
            ], range: fullRange)
            
            // Find and format mentions
            let pattern = "@([A-Z0-9.]+)"
            if let regex = try? NSRegularExpression(pattern: pattern, options: []) {
                let matches = regex.matches(in: text, options: [], range: fullRange)
                for match in matches {
                    // Format mention as bold blue
                    attributedString.addAttributes([
                        .font: NSFont.boldSystemFont(ofSize: 14),
                        .foregroundColor: NSColor.systemBlue
                    ], range: match.range)
                }
            }
            
            // Preserve cursor position
            let selectedRange = textView.selectedRange()
            textView.textStorage?.setAttributedString(attributedString)
            
            // Restore cursor position if it's still valid
            if selectedRange.location <= text.count {
                textView.setSelectedRange(selectedRange)
            }
        }
    }
}

