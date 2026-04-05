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
        BallColor(primary: UIColor(hex: 0xff2d55), light: UIColor(hex: 0xff8fa5)), // red
        BallColor(primary: UIColor(hex: 0x007aff), light: UIColor(hex: 0x80bcff)), // blue
        BallColor(primary: UIColor(hex: 0x34c759), light: UIColor(hex: 0x8de8a5)), // green
        BallColor(primary: UIColor(hex: 0xffcc00), light: UIColor(hex: 0xffe680)), // yellow
        BallColor(primary: UIColor(hex: 0xaf52de), light: UIColor(hex: 0xd5a4ee)), // purple
        BallColor(primary: UIColor(hex: 0xff9500), light: UIColor(hex: 0xffc780)), // orange
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
