import SwiftUI

enum NestTypography {
    static let nowHeading = Font.caption.weight(.black)
    static let fieldLabel = Font.caption2.weight(.bold)
    static let fieldValue = Font.body
    static let nextActionValueControl = Font.title2.weight(.bold)
    static let nextActionValueExpressive = Font.title.weight(.semibold)
    static let reassurance = Font.footnote
    static let confirmation = Font.subheadline.weight(.semibold)
    static let captureTitle = Font.title2.weight(.bold)
    static let reviewIdea = Font.body
    static let reviewStateLabel = Font.caption2.weight(.black)
    static let reviewTimestamp = Font.caption2
    static let emptyStateTitle = Font.title3.weight(.semibold)
}

extension View {
    func nestShadow(enabled: Bool = true) -> some View {
        self.shadow(
            color: enabled ? Color.nestInk.opacity(0.06) : .clear,
            radius: 8,
            x: 0,
            y: 4
        )
    }
}