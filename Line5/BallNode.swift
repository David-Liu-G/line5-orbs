import SpriteKit

class BallNode: SKSpriteNode {
    let colorIndex: Int
    private var bounceAction: SKAction?

    init(colorIndex: Int, size: CGFloat) {
        self.colorIndex = colorIndex
        let texture = BallNode.makeTexture(colorIndex: colorIndex, size: size)
        super.init(texture: texture, color: .clear, size: CGSize(width: size, height: size))
        self.zPosition = 10
    }

    required init?(coder: NSCoder) { fatalError() }

    private static func makeTexture(colorIndex: Int, size: CGFloat) -> SKTexture {
        let s = size * 2 // retina
        let renderer = UIGraphicsImageRenderer(size: CGSize(width: s, height: s))
        let image = renderer.image { ctx in
            let gc = ctx.cgContext
            let rect = CGRect(x: 0, y: 0, width: s, height: s)
            let ballColor = BallColor.all[colorIndex]

            // Main circle with radial gradient
            let colors = [ballColor.light.cgColor, ballColor.primary.cgColor]
            let locations: [CGFloat] = [0.0, 1.0]
            let colorSpace = CGColorSpaceCreateDeviceRGB()
            guard let gradient = CGGradient(colorsSpace: colorSpace, colors: colors as CFArray, locations: locations) else { return }

            gc.addEllipse(in: rect.insetBy(dx: 2, dy: 2))
            gc.clip()

            // Offset center for the anime-style highlight
            let center = CGPoint(x: s * 0.38, y: s * 0.35)
            gc.drawRadialGradient(gradient, startCenter: center, startRadius: 0, endCenter: CGPoint(x: s/2, y: s/2), endRadius: s/2, options: [])

            gc.resetClip()

            // Border
            gc.setStrokeColor(UIColor.white.withAlphaComponent(0.3).cgColor)
            gc.setLineWidth(2)
            gc.strokeEllipse(in: rect.insetBy(dx: 3, dy: 3))

            // White shine dot
            let shineX = s * 0.3
            let shineY = s * 0.28
            let shineR = s * 0.1
            gc.setFillColor(UIColor.white.withAlphaComponent(0.55).cgColor)
            gc.fillEllipse(in: CGRect(x: shineX - shineR, y: shineY - shineR, width: shineR * 2, height: shineR * 2))

            // Highlight ellipse
            gc.saveGState()
            gc.translateBy(x: s * 0.32, y: s * 0.25)
            gc.rotate(by: -.pi / 6)
            gc.setFillColor(UIColor.white.withAlphaComponent(0.45).cgColor)
            gc.fillEllipse(in: CGRect(x: -s * 0.12, y: -s * 0.06, width: s * 0.24, height: s * 0.12))
            gc.restoreGState()
        }
        return SKTexture(image: image)
    }

    // Glow effect behind ball
    func addGlow() {
        let glow = SKShapeNode(circleOfRadius: size.width * 0.55)
        glow.fillColor = BallColor.all[colorIndex].primary.withAlphaComponent(0.2)
        glow.strokeColor = .clear
        glow.zPosition = -1
        glow.name = "glow"
        glow.glowWidth = 8
        addChild(glow)
    }

    func playBounce() {
        removeAction(forKey: "bounce")
        let up = SKAction.moveBy(x: 0, y: 4, duration: 0.25)
        up.timingMode = .easeInEaseOut
        let down = up.reversed()
        let scaleUp = SKAction.scale(to: 1.08, duration: 0.25)
        scaleUp.timingMode = .easeInEaseOut
        let scaleDown = SKAction.scale(to: 1.0, duration: 0.25)
        scaleDown.timingMode = .easeInEaseOut
        let bounce = SKAction.sequence([
            SKAction.group([up, scaleUp]),
            SKAction.group([down, scaleDown])
        ])
        run(SKAction.repeatForever(bounce), withKey: "bounce")
    }

    func stopBounce() {
        removeAction(forKey: "bounce")
        setScale(1.0)
    }

    func playAppear() {
        setScale(0)
        let appear = SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 0.15),
            SKAction.scale(to: 0.9, duration: 0.1),
            SKAction.scale(to: 1.0, duration: 0.08)
        ])
        run(appear)
    }

    func playRemove(completion: @escaping () -> Void) {
        let remove = SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 1.5, duration: 0.15),
                SKAction.fadeAlpha(to: 0.5, duration: 0.15)
            ]),
            SKAction.group([
                SKAction.scale(to: 0, duration: 0.2),
                SKAction.fadeOut(withDuration: 0.2)
            ])
        ])
        run(remove) {
            self.removeFromParent()
            completion()
        }
    }
}
