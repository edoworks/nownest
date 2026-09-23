import SwiftUI

extension Color {
    static let nestCanvas = Color("NestCanvas")
    static let nestSurface = Color("NestSurface")
    static let nestSurfaceRaised = Color("NestSurfaceRaised")
    static let nestInk = Color("NestInk")
    static let nestInkMuted = Color("NestInkMuted")
    static let nestHoney = Color("NestHoney")
    static let nestHoneyInk = Color(red: 0.157, green: 0.137, blue: 0.114)
    static let nestHoneyLight = Color("NestHoneyLight")
    static let nestGinger = Color("NestGinger")
    static let nestSage = Color("NestSage")
    static let nestDanger = Color.red
}

enum NestMetrics {
    static let spacingUnit: CGFloat = 4
    static let spacing8: CGFloat = 8
    static let spacing12: CGFloat = 12
    static let spacing16: CGFloat = 16
    static let spacing24: CGFloat = 24
    static let spacing32: CGFloat = 32

    static let cornerPrimary: CGFloat = 24
    static let cornerPaper: CGFloat = 16
}
