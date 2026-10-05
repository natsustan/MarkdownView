import SwiftUI

@available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
struct RoundLinkUnderlineAttribute: TextAttribute {
    let color: Color
}

@available(iOS 18.0, macOS 15.0, tvOS 18.0, watchOS 11.0, visionOS 2.0, *)
struct RoundLinkUnderlineRenderer: TextRenderer {
    func draw(layout: Text.Layout, in context: inout GraphicsContext) {
        for line in layout {
            context.draw(line)
            let lineRect = line.typographicBounds.rect
            for run in line {
                guard let underline = run[RoundLinkUnderlineAttribute.self] else { continue }
                let rect = run.typographicBounds.rect
                let diameter = max(0.7, lineRect.height / 24)
                let radius = diameter / 2
                let y = lineRect.maxY - radius
                var dots = Path()
                for x in stride(from: rect.minX + radius, through: rect.maxX - radius, by: diameter * 2.8) {
                    dots.addEllipse(in: CGRect(x: x - radius, y: y - radius, width: diameter, height: diameter))
                }
                context.fill(dots, with: .color(underline.color))
            }
        }
    }
}
