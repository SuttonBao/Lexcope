import Foundation
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// Original vector mark: two pages/leaves and a memory seed. No display server needed.
let canvas = CGContext(data: nil, width: 1024, height: 1024, bitsPerComponent: 8,
                       bytesPerRow: 0, space: CGColorSpaceCreateDeviceRGB(),
                       bitmapInfo: CGImageAlphaInfo.noneSkipLast.rawValue)!
canvas.setFillColor(CGColor(red: 0.96, green: 0.95, blue: 0.90, alpha: 1))
canvas.fill(CGRect(x: 0, y: 0, width: 1024, height: 1024))
canvas.setFillColor(CGColor(red: 0.19, green: 0.39, blue: 0.32, alpha: 1))
canvas.move(to: CGPoint(x: 484, y: 250))
canvas.addCurve(to: CGPoint(x: 245, y: 625), control1: CGPoint(x: 250, y: 300), control2: CGPoint(x: 235, y: 440))
canvas.addCurve(to: CGPoint(x: 484, y: 250), control1: CGPoint(x: 460, y: 620), control2: CGPoint(x: 490, y: 420))
canvas.fillPath()
canvas.move(to: CGPoint(x: 540, y: 250))
canvas.addCurve(to: CGPoint(x: 779, y: 718), control1: CGPoint(x: 540, y: 510), control2: CGPoint(x: 560, y: 680))
canvas.addCurve(to: CGPoint(x: 540, y: 250), control1: CGPoint(x: 800, y: 470), control2: CGPoint(x: 800, y: 315))
canvas.fillPath()
canvas.setFillColor(CGColor(red: 0.73, green: 0.52, blue: 0.25, alpha: 1))
canvas.fillEllipse(in: CGRect(x: 364, y: 720, width: 88, height: 88))
let destination = CGImageDestinationCreateWithURL(URL(fileURLWithPath: CommandLine.arguments[1]) as CFURL,
                                                 UTType.png.identifier as CFString, 1, nil)!
CGImageDestinationAddImage(destination, canvas.makeImage()!, nil)
precondition(CGImageDestinationFinalize(destination))
