import SwiftUI

struct NestIllustration: View {
    var size: CGFloat = 120

    var body: some View {
        Canvas { context, size in
            drawNest(in: context, size: size)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private func drawNest(in context: GraphicsContext, size: CGSize) {
        let w = size.width
        let h = size.height
        let cx = w / 2
        let cy = h / 2

        let twigColor = Color.nestGinger
        let honeyColor = Color.nestHoney
        let honeyLight = Color.nestHoneyLight
        let sageColor = Color.nestSage

        let nestRect = CGRect(x: cx - w * 0.35, y: cy - h * 0.1, width: w * 0.7, height: h * 0.45)
        context.fill(Path(ellipseIn: nestRect), with: .color(twigColor.opacity(0.8)))

        let innerRect = CGRect(x: cx - w * 0.25, y: cy - h * 0.05, width: w * 0.5, height: h * 0.3)
        context.fill(Path(ellipseIn: innerRect), with: .color(honeyColor.opacity(0.3)))

        let twigAngles: [Double] = [-0.6, -0.3, 0.0, 0.3, 0.6, 0.9, 1.2]
        for angle in twigAngles {
            let rad = angle * .pi / 3.5
            let x1 = cx + cos(rad) * w * 0.32
            let y1 = cy + sin(rad) * h * 0.18
            let x2 = cx + cos(rad) * w * 0.42
            let y2 = cy + sin(rad) * h * 0.24

            var twigPath = Path()
            twigPath.move(to: CGPoint(x: x1, y: y1))
            twigPath.addLine(to: CGPoint(x: x2, y: y2))
            context.stroke(twigPath, with: .color(twigColor), lineWidth: w * 0.025)
        }

        let egg1Rect = CGRect(x: cx - w * 0.12, y: cy - h * 0.08, width: w * 0.14, height: h * 0.18)
        context.fill(Path(ellipseIn: egg1Rect), with: .color(honeyLight))

        let egg2Rect = CGRect(x: cx + w * 0.02, y: cy - h * 0.06, width: w * 0.13, height: h * 0.17)
        context.fill(Path(ellipseIn: egg2Rect), with: .color(honeyLight.opacity(0.8)))

        let egg3Rect = CGRect(x: cx - w * 0.04, y: cy + h * 0.02, width: w * 0.12, height: h * 0.15)
        context.fill(Path(ellipseIn: egg3Rect), with: .color(honeyLight.opacity(0.6)))

        let leafRect = CGRect(x: cx + w * 0.25, y: cy - h * 0.25, width: w * 0.12, height: h * 0.08)
        var leafPath = Path(ellipseIn: leafRect)
        context.fill(leafPath, with: .color(sageColor.opacity(0.7)))
        context.stroke(leafPath, with: .color(sageColor), lineWidth: 1)

        let leaf2Rect = CGRect(x: cx - w * 0.35, y: cy - h * 0.2, width: w * 0.1, height: h * 0.07)
        var leaf2Path = Path(ellipseIn: leaf2Rect)
        context.fill(leaf2Path, with: .color(sageColor.opacity(0.5)))
    }
}

struct TuckedNoteIllustration: View {
    var size: CGFloat = 80

    var body: some View {
        Canvas { context, size in
            drawTuckedNote(in: context, size: size)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private func drawTuckedNote(in context: GraphicsContext, size: CGSize) {
        let w = size.width
        let h = size.height
        let cx = w / 2
        let cy = h / 2

        let paperColor = Color.nestSurfaceRaised
        let honeyColor = Color.nestHoney
        let sageColor = Color.nestSage
        let inkColor = Color.nestInk

        let noteRect = CGRect(x: cx - w * 0.3, y: cy - h * 0.2, width: w * 0.5, height: h * 0.35)
        let notePath = Path(roundedRect: noteRect, cornerRadius: 6)
        context.fill(notePath, with: .color(paperColor))
        context.stroke(notePath, with: .color(inkColor.opacity(0.1)), lineWidth: 1)

        let line1Rect = CGRect(x: cx - w * 0.2, y: cy - h * 0.1, width: w * 0.3, height: 3)
        context.fill(Path(roundedRect: line1Rect, cornerRadius: 1.5), with: .color(inkColor.opacity(0.2)))

        let line2Rect = CGRect(x: cx - w * 0.2, y: cy - h * 0.03, width: w * 0.22, height: 3)
        context.fill(Path(roundedRect: line2Rect, cornerRadius: 1.5), with: .color(inkColor.opacity(0.15)))

        let checkRect = CGRect(x: cx + w * 0.12, y: cy - h * 0.05, width: w * 0.12, height: h * 0.12)
        var checkPath = Path()
        checkPath.move(to: CGPoint(x: checkRect.minX, y: checkRect.midY))
        checkPath.addLine(to: CGPoint(x: checkRect.midX, y: checkRect.maxY))
        checkPath.addLine(to: CGPoint(x: checkRect.maxX, y: checkRect.minY))
        context.stroke(checkPath, with: .color(sageColor), lineWidth: w * 0.03)

        let sparkPath = Path { p in
            p.move(to: CGPoint(x: cx + w * 0.28, y: cy - h * 0.22))
            p.addLine(to: CGPoint(x: cx + w * 0.32, y: cy - h * 0.14))
            p.addLine(to: CGPoint(x: cx + w * 0.28, y: cy - h * 0.18))
            p.addLine(to: CGPoint(x: cx + w * 0.24, y: cy - h * 0.14))
            p.closeSubpath()
        }
        context.fill(sparkPath, with: .color(honeyColor))
    }
}

#Preview {
    VStack(spacing: 40) {
        NestIllustration(size: 140)
        TuckedNoteIllustration(size: 100)
    }
    .padding(40)
}