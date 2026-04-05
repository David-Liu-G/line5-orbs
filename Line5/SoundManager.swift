import SpriteKit

class SoundManager {
    static let shared = SoundManager()

    let select = SKAction.playSoundFileNamed("select.wav", waitForCompletion: false)
    let move = SKAction.playSoundFileNamed("move.wav", waitForCompletion: false)
    let clear = SKAction.playSoundFileNamed("clear.wav", waitForCompletion: false)
    let swap = SKAction.playSoundFileNamed("swap.wav", waitForCompletion: false)
    let spawn = SKAction.playSoundFileNamed("spawn.wav", waitForCompletion: false)
    let gameOver = SKAction.playSoundFileNamed("gameover.wav", waitForCompletion: false)

    private init() {}
}
