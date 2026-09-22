import SwiftUI

struct NestMotif: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        let w = rect.width
        let h = rect.height
        let cx = rect.midX
        let cy = rect.midY

        path.move(to: CGPoint(x: cx - w * 0.3, y: cy + h * 0.25))
        path.addQuadCurve(to: CGPoint(x: cx, y: cy - h * 0.3), control: CGPoint(x: cx - w * 0.2, y: cy - h * 0.15))
        path.addQuadCurve(to: CGPoint(x: cx + w * 0.3, y: cy + h * 0.25), control: CGPoint(x: cx + w * 0.2, y: cy - h * 0.15))
        path.addQuadCurve(to: CGPoint(x: cx, y: cy + h * 0.05), control: CGPoint(x: cx + w * 0.15, y: cy + h * 0.2))
        path.addQuadCurve(to: CGPoint(x: cx - w * 0.3, y: cy + h * 0.25), control: CGPoint(x: cx - w * 0.15, y: cy + h * 0.2))
        path.closeSubpath()

        return path
    }
}