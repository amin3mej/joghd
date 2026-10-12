import CoreGraphics
import Foundation
import ImageIO
import UniformTypeIdentifiers

enum BookCoverThumbnail {
    static let maximumPixelSize = 800
    private static let compressionQuality: CGFloat = 0.8

    static func make(from data: Data) -> Data? {
        guard let source = CGImageSourceCreateWithData(data as CFData, nil) else {
            return nil
        }
        var options: [CFString: Any] = [:]
        options[kCGImageSourceCreateThumbnailFromImageAlways] = true
        options[kCGImageSourceCreateThumbnailWithTransform] = true
        options[kCGImageSourceThumbnailMaxPixelSize] = maximumPixelSize
        guard
            let image = CGImageSourceCreateThumbnailAtIndex(source, 0, options as CFDictionary)
        else {
            return nil
        }
        return encode(image)
    }

    private static func encode(_ image: CGImage) -> Data? {
        let output = NSMutableData()
        guard
            let destination = CGImageDestinationCreateWithData(
                output as CFMutableData,
                UTType.jpeg.identifier as CFString,
                1,
                nil
            )
        else {
            return nil
        }
        let options: [CFString: Any] = [
            kCGImageDestinationLossyCompressionQuality: compressionQuality
        ]
        CGImageDestinationAddImage(destination, image, options as CFDictionary)
        guard CGImageDestinationFinalize(destination) else {
            return nil
        }
        return output as Data
    }
}
