import Foundation
import Markdown
import SwiftUI
import Testing

@testable import MarkdownView

@Suite("Inline Link Decoration")
struct MarkdownLinkDecorationTests {
    private var configuration: MarkdownRendererConfiguration {
        var configuration = MarkdownRendererConfiguration()
        configuration.tintColors[.link] = .primary
        configuration.underlineLinks = true
        configuration.linkUnderlineStyle = .init(pattern: .dot, color: .secondary)
        configuration.roundLinkUnderlines = true
        configuration.linkUnderlineColor = .secondary
        var suffix = AttributedString("\u{00A0}↗\u{FE0E}")
        suffix.font = .caption
        suffix.foregroundColor = .secondary
        configuration.linkSuffix = suffix
        return configuration
    }

    @Test("Decorated links remain part of the surrounding inline paragraph")
    @MainActor
    func preservesInlineParagraph() throws {
        var renderer = MarkdownViewRenderer(
            configuration: configuration,
            mathContext: nil,
            elementRenderers: []
        )
        let node = renderer.visit(Document(parsing: "Before [**guide** `code`](https://example.com/guide) after."))
        let text = try #require(node.asAttributedString)

        #expect(String(text.characters) == "Before guide code\u{00A0}↗\u{FE0E} after.")
        try verifyLink(in: text)
        let bold = try #require(text.range(of: "guide"))
        #expect(text[bold].inlinePresentationIntent?.contains(.stronglyEmphasized) == true)
        let code = try #require(text.range(of: "code"))
        #expect(text[code].inlinePresentationIntent?.contains(.code) == true)
        let after = try #require(text.range(of: " after."))
        #expect(text[after].link == nil)
        #expect(text[after].underlineStyle == nil)
    }

    #if canImport(RichText)
    @Test("Text conversion keeps link destinations and the inline suffix")
    @MainActor
    func preservesTextConversion() throws {
        let content = MarkdownViewTestSupport.makeTextContent(
            markdown: "Before [guide code](https://example.com/guide) after.",
            configuration: configuration
        )
        let text = MarkdownViewTestSupport.attributedString(in: content)
        #expect(MarkdownViewTestSupport.embeddedViewCount(in: content) == 0)
        #expect(String(text.characters) == "Before guide code\u{00A0}↗\u{FE0E} after.")
        try verifyLink(in: text)
    }
    #endif

    @Test("Code and plain text never acquire link decorations")
    @MainActor
    func leavesNonLinksAlone() throws {
        var renderer = MarkdownViewRenderer(configuration: configuration, mathContext: nil, elementRenderers: [])
        let node = renderer.visit(Document(parsing: "`[guide](https://example.com)` and plain text."))
        let text = try #require(node.asAttributedString)
        #expect(String(text.characters) == "[guide](https://example.com) and plain text.")
        #expect(text.runs.allSatisfy { $0.link == nil && $0.underlineStyle == nil })
    }

    private func verifyLink(in text: AttributedString) throws {
        let label = try #require(text.range(of: "guide"))
        #expect(text[label].link?.absoluteString == "https://example.com/guide")
        #expect(text[label].underlineStyle == configuration.linkUnderlineStyle)
        #expect(text[label].foregroundColor == .primary)

        let suffix = try #require(text.range(of: "\u{00A0}↗\u{FE0E}"))
        #expect(text[suffix].link?.absoluteString == "https://example.com/guide")
        #expect(text[suffix].underlineStyle == nil)
        #expect(text[suffix].foregroundColor == .secondary)
        #expect(text[suffix].font == .caption)
    }
}
