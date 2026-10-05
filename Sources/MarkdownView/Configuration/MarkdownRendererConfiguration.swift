//
//  MarkdownRendererConfiguration.swift
//  MarkdownView
//
//  Created by LiYanan2004 on 2024/12/11.
//

import Foundation
import SwiftUI

struct MarkdownRendererConfiguration: Hashable, AllowingModifyThroughKeyPath, Sendable {
    var preferredBaseURL: URL?
    var componentSpacing: CGFloat = 8
    
    var tintColors: [MarkdownTintableComponent : Color] = [:]
    var underlineLinks: Bool = false
    var linkUnderlineStyle: Text.LineStyle = .single
    var roundLinkUnderlines: Bool = false
    var linkUnderlineColor: Color?
    var linkSuffix: AttributedString?
    var listConfiguration: MarkdownListConfiguration = MarkdownListConfiguration()

    func resolvedMarkdownURL(for destination: String) -> URL? {
        URL(string: destination, relativeTo: preferredBaseURL)
    }

    func decoratedLinkLabel(_ label: AttributedString, url: URL) -> AttributedString {
        var attributes = AttributeContainer()
            .link(url)
            .foregroundColor(tintColors[.link] ?? .accentColor)
        attributes.underlineStyle = underlineLinks ? linkUnderlineStyle : .none
        var result = label.mergingAttributes(attributes)
        if let suffix = resolvedLinkSuffix(for: url) {
            result += suffix
        }
        return result
    }

    func resolvedLinkSuffix(for url: URL) -> AttributedString? {
        guard var suffix = linkSuffix, !suffix.characters.isEmpty else { return nil }
        suffix.link = url
        suffix.underlineStyle = .none
        return suffix
    }
}

// MARK: - SwiftUI Environment

struct MarkdownRendererConfigurationKey: EnvironmentKey {
    static let defaultValue: MarkdownRendererConfiguration = .init()
}

extension EnvironmentValues {
    var markdownRendererConfiguration: MarkdownRendererConfiguration {
        get { self[MarkdownRendererConfigurationKey.self] }
        set { self[MarkdownRendererConfigurationKey.self] = newValue }
    }
}
