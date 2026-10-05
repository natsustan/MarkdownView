//
//  UnderlineLinkModifier.swift
//  MarkdownView
//

import SwiftUI

extension SwiftUI.View {
    /// Adds an underline decoration to links in the Markdown content.
    ///
    /// - Parameters:
    ///   - isActive: Whether links should be underlined. Defaults to `true`.
    ///   - pattern: The underline pattern for text links. Defaults to a solid underline.
    ///   - color: The underline color. Defaults to the link's text color.
    nonisolated public func markdownLinksUnderlined(
        _ isActive: Bool = true,
        pattern: Text.LineStyle.Pattern = .solid,
        color: Color? = nil
    ) -> some View {
        transformEnvironment(\.markdownRendererConfiguration) { configuration in
            configuration.underlineLinks = isActive
            configuration.linkUnderlineStyle = .init(pattern: pattern, color: color)
            configuration.roundLinkUnderlines = isActive
                && Text.LineStyle(pattern: pattern) == Text.LineStyle(pattern: .dot)
            configuration.linkUnderlineColor = color
        }
    }

    /// Appends an inline suffix to text links without replacing them with separate views.
    ///
    /// The suffix keeps its own font and color attributes, opens the same destination,
    /// and is not underlined. Include any desired spacing in the suffix itself.
    /// Custom link renderers keep control of their labels.
    nonisolated public func markdownLinkSuffix(_ suffix: AttributedString?) -> some View {
        transformEnvironment(\.markdownRendererConfiguration) { configuration in
            configuration.linkSuffix = suffix
        }
    }
}
