import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

enum CoverFixture {
    private static let bitsPerComponent = 8
    private static let red: CGFloat = 0.2
    private static let green: CGFloat = 0.4
    private static let blue: CGFloat = 0.8
    private static let opaque: CGFloat = 1

    static func imageData(width: Int, height: Int, format: UTType = .png) -> Data {
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard
            let context = CGContext(
                data: nil,
                width: width,
                height: height,
                bitsPerComponent: bitsPerComponent,
                bytesPerRow: 0,
                space: colorSpace,
                bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
            ),
            let image = makeImage(in: context, width: width, height: height)
        else {
            return Data()
        }
        return encode(image, format: format)
    }

    private static func makeImage(in context: CGContext, width: Int, height: Int) -> CGImage? {
        context.setFillColor(CGColor(red: red, green: green, blue: blue, alpha: opaque))
        context.fill(CGRect(x: 0, y: 0, width: width, height: height))
        return context.makeImage()
    }

    private static func encode(_ image: CGImage, format: UTType) -> Data {
        let output = NSMutableData()
        guard
            let destination = CGImageDestinationCreateWithData(
                output as CFMutableData,
                format.identifier as CFString,
                1,
                nil
            )
        else {
            return Data()
        }
        CGImageDestinationAddImage(destination, image, nil)
        guard CGImageDestinationFinalize(destination) else {
            return Data()
        }
        return output as Data
    }

    static func pixelSize(of data: Data) -> (width: Int, height: Int)? {
        guard
            let source = CGImageSourceCreateWithData(data as CFData, nil),
            let properties = CGImageSourceCopyPropertiesAtIndex(source, 0, nil)
                as? [CFString: Any],
            let width = properties[kCGImagePropertyPixelWidth] as? Int,
            let height = properties[kCGImagePropertyPixelHeight] as? Int
        else {
            return nil
        }
        return (width, height)
    }
}
