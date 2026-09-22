import SwiftUI

struct NestWordmark: View {
    var fontSize: CGFloat = 17

    var body: some View {
        Text("NowNest")
            .font(.system(size: fontSize, weight: .heavy, design: .rounded))
            .tracking(-0.5)
            .foregroundStyle(Color.nestInk)
            .accessibilityAddTraits(.isHeader)
    }
}

#Preview {
    NestWordmark(fontSize: 24)
        .padding()
}