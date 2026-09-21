import SwiftUI

struct NestCard<Content: View>: View {
    let cornerRadius: CGFloat
    let raised: Bool
    @ViewBuilder let content: () -> Content

    init(cornerRadius: CGFloat = NestMetrics.cornerPrimary, raised: Bool = false, @ViewBuilder content: @escaping () -> Content) {
        self.cornerRadius = cornerRadius
        self.raised = raised
        self.content = content
    }

    var body: some View {
        content()
            .padding(NestMetrics.spacing24)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .fill(raised ? Color.nestSurfaceRaised : Color.nestSurface)
            )
            .overlay {
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(Color.nestInk.opacity(0.08), lineWidth: 1)
            }
    }
}

struct NestPaperNote<Content: View>: View {
    @ViewBuilder let content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    var body: some View {
        content()
            .padding(NestMetrics.spacing16)
            .background(
                RoundedRectangle(cornerRadius: NestMetrics.cornerPaper)
                    .fill(Color.nestSurfaceRaised)
            )
            .overlay {
                RoundedRectangle(cornerRadius: NestMetrics.cornerPaper)
                    .stroke(Color.nestInk.opacity(0.06), lineWidth: 1)
            }
    }
}