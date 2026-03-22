import UIKit

let gridRows = 8
let gridCols = 8
let numColors = 6
let ballsPerTurn = 3
let lineMin = 5

let directions: [(dr: Int, dc: Int)] = [
    (0, 1), (1, 0), (1, 1), (1, -1)
]

struct BallColor {
    let primary: UIColor
    let light: UIColor

    static let all: [BallColor] = [
        BallColor(primary: UIColor(hex: 0xe91e8c), light: UIColor(hex: 0xffb0dd)), // pink
        BallColor(primary: UIColor(hex: 0x3d7cf5), light: UIColor(hex: 0xa0c8ff)), // blue
        BallColor(primary: UIColor(hex: 0x2ecc71), light: UIColor(hex: 0x85e89d)), // green
        BallColor(primary: UIColor(hex: 0xf5c842), light: UIColor(hex: 0xfff09e)), // yellow
        BallColor(primary: UIColor(hex: 0x9b4dca), light: UIColor(hex: 0xd9a0ff)), // purple
        BallColor(primary: UIColor(hex: 0x00d4aa), light: UIColor(hex: 0x80ffee)), // teal
    ]
}

extension UIColor {
    convenience init(hex: Int, alpha: CGFloat = 1.0) {
        self.init(
            red: CGFloat((hex >> 16) & 0xFF) / 255.0,
            green: CGFloat((hex >> 8) & 0xFF) / 255.0,
            blue: CGFloat(hex & 0xFF) / 255.0,
            alpha: alpha
        )
    }
}
