//
//  _MarkdownText.swift
//  MarkdownView
//
//  Created by Yanan Li on 2025/10/20.
//

import SwiftUI

/// A view that displays parsed HTML asynchronously.
///
/// Convert HTML into  `AttributedString` asynchronously to avoid `AttributeGraph` crash.
struct _MarkdownText: View {
    var text: AttributedString
    @State private var attributedString: RenderedState?
    @Environment(\.markdownRendererConfiguration) private var configuration
    
    init(_ text: AttributedString) {
        self.text = text
    }

    var body: some View {
        Group {
            if let attributedString {
                renderedText(Self.visibleText(input: text, rendered: attributedString))
            } else {
                renderedText(text)
            }
        }
        .task(id: text) {
            var attributedString = text
            for run in text.runs.reversed() where (run.isHTML ?? false) {
                let range = run.range

                if let htmlAttrString = try? AttributedString(
                    NSAttributedString(
                        data: Data(String(text.characters[range]).utf8),
                        options: [
                            .documentType: NSAttributedString.DocumentType.html
                        ],
                        documentAttributes: nil
                    )
                ) {
                    attributedString.replaceSubrange(range, with: htmlAttrString)
                }
            }

            // Streaming updates can start a new render before an older render finishes.
            // Avoid committing work SwiftUI already cancelled for a superseded input.
            guard !Task.isCancelled else { return }
            self.attributedString = RenderedState(input: text, output: attributedString)
        }
    }

    @ViewBuilder
    private func renderedText(_ text: AttributedString) -> some View {
        if #available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *) {
            roundLinkUnderlineText(text)
                .textRenderer(RoundLinkUnderlineRenderer())
        } else {
            Text(text)
        }
    }

    @available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
    private func roundLinkUnderlineText(_ text: AttributedString) -> Text {
        guard configuration.roundLinkUnderlines,
              text.runs.contains(where: { $0.link != nil && $0.underlineStyle == configuration.linkUnderlineStyle })
        else { return Text(text) }
        var result = Text("")
        for run in text.runs {
            var content = AttributedString(text[run.range])
            if run.link != nil, run.underlineStyle == configuration.linkUnderlineStyle {
                // Core Text's dot pattern produces short rectangular strokes. Keep
                // the native link attributes and draw circular dots below each run.
                content.underlineStyle = nil
                let segment = Text(content).customAttribute(RoundLinkUnderlineAttribute(
                    color: configuration.linkUnderlineColor ?? run.foregroundColor ?? .primary
                ))
                result = Text("\(result)\(segment)")
            } else {
                result = Text("\(result)\(Text(content))")
            }
        }
        return result
    }

    static func visibleText(input: AttributedString, rendered: RenderedState) -> AttributedString {
        // `renderedState` is asynchronous cache state. During streaming, an older
        // partial input can finish after the latest input and briefly live in
        // `@State`. Only use the cached output when it was produced from the
        // exact input currently being displayed; otherwise fall back to `input`
        // so the visible text cannot regress while the next render catches up.
        guard rendered.input == input else { return input }
        return rendered.output
    }

    struct RenderedState {
        /// The source markdown text that produced `output`.
        var input: AttributedString

        /// The same content after asynchronous HTML runs have been converted.
        var output: AttributedString
    }
}
