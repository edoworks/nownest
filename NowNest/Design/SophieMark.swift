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
        Canvas { context, size in
            drawSophie(in: context, size: size, pose: pose)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }

    private func drawSophie(in context: GraphicsContext, size: CGSize, pose: SophiePose) {
        let w = size.width
        let h = size.height
        let ginger = Color.nestGinger
        let honey = Color.nestHoney
        let ink = Color.nestInk
        let honeyLight = Color.nestHoneyLight

        let bodyRect = CGRect(x: w * 0.22, y: h * 0.38, width: w * 0.56, height: h * 0.5)
        context.fill(Path(ellipseIn: bodyRect), with: .color(ginger))

        let bellyRect = CGRect(x: w * 0.30, y: h * 0.50, width: w * 0.40, height: h * 0.30)
        context.fill(Path(ellipseIn: bellyRect), with: .color(honeyLight.opacity(0.5)))

        let headRect = CGRect(x: w * 0.38, y: h * 0.15, width: w * 0.36, height: h * 0.34)
        context.fill(Path(ellipseIn: headRect), with: .color(ginger))

        for earOffset in [-0.08, 0.08] {
            let earRect = CGRect(
                x: w * (0.44 + earOffset),
                y: h * 0.08,
                width: w * 0.14,
                height: h * 0.16
            )
            context.fill(Path(ellipseIn: earRect), with: .color(ginger))

            let innerEarRect = CGRect(
                x: w * (0.46 + earOffset),
                y: h * 0.12,
                width: w * 0.08,
                height: h * 0.10
            )
            context.fill(Path(ellipseIn: innerEarRect), with: .color(honey.opacity(0.6)))
        }

        let eyeY = h * 0.28
        for eyeX in [w * 0.46, w * 0.58] {
            let eyeRect = CGRect(x: eyeX, y: eyeY, width: w * 0.06, height: h * 0.08)
            context.fill(Path(ellipseIn: eyeRect), with: .color(ink))

            let shineRect = CGRect(x: eyeX + w * 0.01, y: eyeY + h * 0.01, width: w * 0.025, height: h * 0.03)
            context.fill(Path(ellipseIn: shineRect), with: .color(.white.opacity(0.8)))
        }

        let noseRect = CGRect(x: w * 0.50, y: h * 0.36, width: w * 0.06, height: h * 0.04)
        context.fill(Path(ellipseIn: noseRect), with: .color(honey))

        for whiskerSide in [-1.0, 1.0] {
            var whiskerPath = Path()
            let startY = h * 0.38
            let startX = w * (0.52 + whiskerSide * 0.04)
            whiskerPath.move(to: CGPoint(x: startX, y: startY))
            whiskerPath.addLine(to: CGPoint(x: w * (0.52 + whiskerSide * 0.22), y: startY - h * 0.01))
            context.stroke(whiskerPath, with: .color(ink.opacity(0.3)), lineWidth: 0.8)

            var whiskerPath2 = Path()
            whiskerPath2.move(to: CGPoint(x: startX, y: startY + h * 0.02))
            whiskerPath2.addLine(to: CGPoint(x: w * (0.52 + whiskerSide * 0.22), y: startY + h * 0.04))
            context.stroke(whiskerPath2, with: .color(ink.opacity(0.25)), lineWidth: 0.8)
        }

        switch pose {
        case .resting:
            var tailPath = Path()
            tailPath.move(to: CGPoint(x: w * 0.74, y: h * 0.58))
            tailPath.addQuadCurve(
                to: CGPoint(x: w * 0.90, y: h * 0.40),
                control: CGPoint(x: w * 0.84, y: h * 0.48)
            )
            context.stroke(tailPath, with: .color(honey), lineWidth: w * 0.06)

            var tailTip = Path(ellipseIn: CGRect(x: w * 0.86, y: h * 0.36, width: w * 0.08, height: h * 0.08))
            context.fill(tailTip, with: .color(honey.opacity(0.7)))

        case .guarding:
            for pawX in [w * 0.30, w * 0.56] {
                let pawRect = CGRect(x: pawX, y: h * 0.78, width: w * 0.14, height: h * 0.10)
                context.fill(Path(ellipseIn: pawRect), with: .color(ginger))

                let pawInnerRect = CGRect(x: pawX + w * 0.02, y: h * 0.80, width: w * 0.10, height: h * 0.06)
                context.fill(Path(ellipseIn: pawInnerRect), with: .color(honeyLight.opacity(0.4)))
            }

            var alertEarPath = Path()
            alertEarPath.move(to: CGPoint(x: w * 0.44, y: h * 0.10))
            alertEarPath.addLine(to: CGPoint(x: w * 0.43, y: h * 0.02))
            alertEarPath.addLine(to: CGPoint(x: w * 0.50, y: h * 0.08))
            alertEarPath.closeSubpath()
            context.fill(alertEarPath, with: .color(ginger.opacity(0.8)))

        case .tucked:
            let ballRect = CGRect(x: w * 0.28, y: h * 0.48, width: w * 0.44, height: h * 0.40)
            context.fill(Path(ellipseIn: ballRect), with: .color(ginger.opacity(0.6)))

            let curlRect = CGRect(x: w * 0.50, y: h * 0.55, width: w * 0.20, height: h * 0.20)
            context.stroke(Path(ellipseIn: curlRect), with: .color(honey.opacity(0.5)), lineWidth: 2)
        }
    }
}

#Preview {
    HStack(spacing: 20) {
        SophieMark(pose: .resting, size: 60)
        SophieMark(pose: .guarding, size: 60)
        SophieMark(pose: .tucked, size: 60)
    }
    .padding()
}