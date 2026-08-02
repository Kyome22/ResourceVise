import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

extension CGImage {
    static func dummy() -> CGImage {
        let context = CGContext(
            data: nil,
            width: 1,
            height: 1,
            bitsPerComponent: 8,
            bytesPerRow: 4,
            space: CGColorSpaceCreateDeviceRGB(),
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        )!
        return context.makeImage()!
    }

    func pngData() -> Data {
        let data = NSMutableData()
        let destination = CGImageDestinationCreateWithData(
            data as CFMutableData,
            UTType.png.identifier as CFString,
            1,
            nil
        )!
        CGImageDestinationAddImage(destination, self, nil)
        CGImageDestinationFinalize(destination)
        return data as Data
    }
}

extension CGImageSource {
    static func dummy() -> CGImageSource {
        CGImageSourceCreateWithData(CGImage.dummy().pngData() as CFData, nil)!
    }
}
