import SwiftUI

enum SophiePose {
    case resting
    case guarding
    case tucked
}

struct SophieMark: View {
    let pose: SophiePose
    var size: CGFloat = 28

    var body: some View {
        GeometryReader { proxy in
            Canvas { context, size in
                drawSophie(in: context, size: size, pose: pose)
            }
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private func drawSophie(in context: GraphicsContext, size: CGSize, pose: SophiePose) {
        let ginger = Color.nestGinger
        let honey = Color.nestHoney
        let ink = Color.nestInk

        let bodyRect = CGRect(x: size.width * 0.25, y: size.height * 0.4, width: size.width * 0.5, height: size.height * 0.45)
        let headRect = CGRect(x: size.width * 0.4, y: size.height * 0.18, width: size.width * 0.32, height: size.height * 0.32)

        context.fill(Path(ellipseIn: bodyRect), with: .color(ginger))
        context.fill(Path(ellipseIn: headRect), with: .color(ginger))

        let earPath = Path { p in
            p.move(to: CGPoint(x: size.width * 0.45, y: size.height * 0.25))
            p.addLine(to: CGPoint(x: size.width * 0.42, y: size.height * 0.12))
            p.addLine(to: CGPoint(x: size.width * 0.52, y: size.height * 0.22))
            p.closeSubpath()
        }
        context.fill(earPath, with: .color(ginger))

        let eyeRect = CGRect(x: size.width * 0.5, y: size.height * 0.3, width: size.width * 0.05, height: size.height * 0.06)
        context.fill(Path(ellipseIn: eyeRect), with: .color(ink))

        switch pose {
        case .resting:
            let tailPath = Path { p in
                p.move(to: CGPoint(x: size.width * 0.7, y: size.height * 0.6))
                p.addQuadCurve(to: CGPoint(x: size.width * 0.88, y: size.height * 0.45), control: CGPoint(x: size.width * 0.82, y: size.height * 0.5))
            }
            context.stroke(tailPath, with: .color(honey), lineWidth: size.width * 0.06)
        case .guarding:
            let pawRect = CGRect(x: size.width * 0.32, y: size.height * 0.75, width: size.width * 0.12, height: size.height * 0.1)
            context.fill(Path(ellipseIn: pawRect), with: .color(ginger))
            let pawRect2 = CGRect(x: size.width * 0.56, y: size.height * 0.75, width: size.width * 0.12, height: size.height * 0.1)
            context.fill(Path(ellipseIn: pawRect2), with: .color(ginger))
        case .tucked:
            let ballRect = CGRect(x: size.width * 0.3, y: size.height * 0.5, width: size.width * 0.4, height: size.height * 0.4)
            context.fill(Path(ellipseIn: ballRect), with: .color(ginger.opacity(0.7)))
        }
    }
}

#Preview {
    HStack {
        SophieMark(pose: .resting)
        SophieMark(pose: .guarding)
        SophieMark(pose: .tucked)
    }
    .padding()
}