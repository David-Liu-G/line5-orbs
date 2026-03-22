import SpriteKit

struct Particle {
    var position: CGPoint
    var velocity: CGVector
    var size: CGFloat
    var life: CGFloat
    var maxLife: CGFloat
    var color: UIColor
    var lightColor: UIColor
    var gravity: CGFloat
    var rotation: CGFloat
    var rotSpeed: CGFloat
    var isStar: Bool
}

class ParticleManager {
    private var particles: [Particle] = []
    private let container: SKNode
    private var shapeNodes: [SKShapeNode] = []
    private let maxNodes = 300

    init(parent: SKNode) {
        container = SKNode()
        container.zPosition = 50
        parent.addChild(container)

        // Pre-create reusable nodes
        for _ in 0..<maxNodes {
            let node = SKShapeNode(circleOfRadius: 3)
            node.strokeColor = .clear
            node.isHidden = true
            container.addChild(node)
            shapeNodes.append(node)
        }
    }

    func spawnSelect(at pos: CGPoint, colorIndex: Int) {
        let bc = BallColor.all[colorIndex]
        for i in 0..<24 {
            let angle = (CGFloat.pi * 2 * CGFloat(i)) / 24 + CGFloat.random(in: -0.3...0.3)
            let speed: CGFloat = CGFloat.random(in: 40...120)
            particles.append(Particle(
                position: pos,
                velocity: CGVector(dx: cos(angle) * speed, dy: sin(angle) * speed),
                size: CGFloat.random(in: 2...5),
                life: CGFloat.random(in: 0.4...0.7),
                maxLife: CGFloat.random(in: 0.4...0.7),
                color: bc.primary,
                lightColor: bc.light,
                gravity: 20,
                rotation: CGFloat.random(in: 0...(.pi * 2)),
                rotSpeed: CGFloat.random(in: -2...2),
                isStar: Bool.random()
            ))
        }
    }

    func spawnExplosion(at pos: CGPoint, colorIndex: Int) {
        let bc = BallColor.all[colorIndex]
        for i in 0..<35 {
            let angle = (CGFloat.pi * 2 * CGFloat(i)) / 35 + CGFloat.random(in: -0.3...0.3)
            let speed: CGFloat = CGFloat.random(in: 80...200)
            particles.append(Particle(
                position: pos,
                velocity: CGVector(dx: cos(angle) * speed, dy: sin(angle) * speed),
                size: CGFloat.random(in: 2.5...6),
                life: CGFloat.random(in: 0.5...0.9),
                maxLife: CGFloat.random(in: 0.5...0.9),
                color: bc.primary,
                lightColor: bc.light,
                gravity: -30,
                rotation: CGFloat.random(in: 0...(.pi * 2)),
                rotSpeed: CGFloat.random(in: -3...3),
                isStar: Bool.random()
            ))
        }
    }

    func spawnTrail(at pos: CGPoint, colorIndex: Int) {
        let bc = BallColor.all[colorIndex]
        for _ in 0..<8 {
            let offset = CGPoint(x: CGFloat.random(in: -8...8), y: CGFloat.random(in: -8...8))
            particles.append(Particle(
                position: CGPoint(x: pos.x + offset.x, y: pos.y + offset.y),
                velocity: CGVector(
                    dx: CGFloat.random(in: -30...30),
                    dy: CGFloat.random(in: 20...60)
                ),
                size: CGFloat.random(in: 2...4),
                life: CGFloat.random(in: 0.3...0.5),
                maxLife: CGFloat.random(in: 0.3...0.5),
                color: bc.primary,
                lightColor: bc.light,
                gravity: 30,
                rotation: CGFloat.random(in: 0...(.pi * 2)),
                rotSpeed: CGFloat.random(in: -2...2),
                isStar: Bool.random()
            ))
        }
    }

    func spawnAura(at pos: CGPoint, colorIndex: Int) {
        let bc = BallColor.all[colorIndex]
        for _ in 0..<3 {
            let angle = CGFloat.random(in: 0...(.pi * 2))
            let dist: CGFloat = CGFloat.random(in: 12...20)
            particles.append(Particle(
                position: CGPoint(x: pos.x + cos(angle) * dist, y: pos.y + sin(angle) * dist),
                velocity: CGVector(dx: cos(angle) * 15, dy: sin(angle) * 15 + 20),
                size: CGFloat.random(in: 1.5...3),
                life: CGFloat.random(in: 0.3...0.5),
                maxLife: CGFloat.random(in: 0.3...0.5),
                color: bc.primary,
                lightColor: bc.light,
                gravity: 30,
                rotation: CGFloat.random(in: 0...(.pi * 2)),
                rotSpeed: CGFloat.random(in: -1...1),
                isStar: true
            ))
        }
    }

    func update(dt: TimeInterval) {
        let dtF = CGFloat(dt)

        // Update particles
        var i = 0
        while i < particles.count {
            particles[i].life -= dtF
            if particles[i].life <= 0 {
                particles.remove(at: i)
                continue
            }
            particles[i].position.x += particles[i].velocity.dx * dtF
            particles[i].position.y += particles[i].velocity.dy * dtF
            particles[i].velocity.dy += particles[i].gravity * dtF
            particles[i].velocity.dx *= (1 - 2 * dtF)
            particles[i].rotation += particles[i].rotSpeed * dtF
            i += 1
        }

        // Render to shape nodes
        for j in 0..<maxNodes {
            if j < particles.count {
                let p = particles[j]
                let node = shapeNodes[j]
                node.isHidden = false
                node.position = p.position
                let alpha = p.life / p.maxLife
                let s = p.size * (0.5 + alpha * 0.5)
                node.setScale(s / 3)
                node.fillColor = p.lightColor.withAlphaComponent(alpha * 0.9)
                node.glowWidth = s * 0.5
                node.zRotation = p.rotation
            } else {
                shapeNodes[j].isHidden = true
            }
        }
    }
}
