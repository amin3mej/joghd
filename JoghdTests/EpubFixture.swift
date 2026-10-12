import Compression
import Foundation

enum EpubFixture {
    final class BundleToken {}

    @resultBuilder
    enum Builder {
        static func buildBlock(_ entries: (String, String)...) -> [(String, String)] {
            entries
        }
    }

    private enum Format {
        static let localSignature: UInt32 = 0x0403_4B50
        static let directorySignature: UInt32 = 0x0201_4B50
        static let endSignature: UInt32 = 0x0605_4B50
        static let version: UInt16 = 20
        static let storedMethod: UInt16 = 0
        static let deflatedMethod: UInt16 = 8
        static let compressionBufferMultiplier = 2
        static let compressionBufferPadding = 64
    }

    private enum CRC32 {
        private static let polynomial: UInt32 = 0xEDB8_8320
        private static let initial: UInt32 = 0xFFFF_FFFF
        private static let bitsPerByte = 8

        static func compute(_ data: Data) -> UInt32 {
            var crc = initial
            for byte in data {
                crc ^= UInt32(byte)
                for _ in 0..<bitsPerByte {
                    crc = (crc & 1) != 0 ? (crc >> 1) ^ polynomial : crc >> 1
                }
            }
            return crc ^ initial
        }
    }

    static var container: String {
        var lines: [String] = []
        lines.append("<?xml version=\"1.0\" encoding=\"UTF-8\"?>")
        lines.append(
            "<container version=\"1.0\" xmlns=\"urn:oasis:names:tc:opendocument:xmlns:container\">"
        )
        lines.append("<rootfiles>")
        lines.append(
            "<rootfile full-path=\"OEBPS/content.opf\" "
                + "media-type=\"application/oebps-package+xml\"/>"
        )
        lines.append("</rootfiles>")
        lines.append("</container>")
        return lines.joined(separator: "\n")
    }

    static func package(
        title: String? = "The Book",
        author: String? = "The Author",
        manifest: [(id: String, href: String)],
        spine: [String],
        nonLinear: [String] = [],
        properties: [String: String] = [:],
        metaCoverID: String? = nil
    ) -> String {
        var lines: [String] = []
        lines.append("<?xml version=\"1.0\" encoding=\"UTF-8\"?>")
        lines.append(
            "<package xmlns=\"http://www.idpf.org/2007/opf\" version=\"3.0\" "
                + "unique-identifier=\"bookid\">"
        )
        lines.append("<metadata xmlns:dc=\"http://purl.org/dc/elements/1.1/\">")
        if let title {
            lines.append("<dc:title>\(title)</dc:title>")
        }
        if let author {
            lines.append("<dc:creator>\(author)</dc:creator>")
        }
        if let metaCoverID {
            lines.append("<meta name=\"cover\" content=\"\(metaCoverID)\"/>")
        }
        lines.append("</metadata>")
        lines.append("<manifest>")
        for item in manifest {
            var attributes = "id=\"\(item.id)\" href=\"\(item.href)\""
            if let itemProperties = properties[item.id] {
                attributes += " properties=\"\(itemProperties)\""
            }
            lines.append("<item \(attributes) media-type=\"application/xhtml+xml\"/>")
        }
        lines.append("</manifest>")
        lines.append("<spine>")
        for idref in spine {
            if nonLinear.contains(idref) {
                lines.append("<itemref idref=\"\(idref)\" linear=\"no\"/>")
            } else {
                lines.append("<itemref idref=\"\(idref)\"/>")
            }
        }
        lines.append("</spine>")
        lines.append("</package>")
        return lines.joined(separator: "\n")
    }

    static func chapter(title: String?, body: String) -> String {
        var lines: [String] = []
        lines.append("<?xml version=\"1.0\" encoding=\"UTF-8\"?>")
        lines.append("<html xmlns=\"http://www.w3.org/1999/xhtml\">")
        if let title {
            lines.append("<head><title>\(title)</title></head>")
        } else {
            lines.append("<head></head>")
        }
        lines.append("<body>")
        lines.append(body)
        lines.append("</body>")
        lines.append("</html>")
        return lines.joined(separator: "\n")
    }

    static func zip(deflated: Bool = false, @Builder _ build: () -> [(String, String)]) -> Data {
        write(build().map { ($0.0, Data($0.1.utf8)) }, deflated: deflated)
    }

    static func zipBytes(deflated: Bool = false, _ entries: [(String, Data)]) -> Data {
        write(entries, deflated: deflated)
    }

    private static func write(_ entries: [(String, Data)], deflated: Bool) -> Data {
        var output = Data()
        var directory = Data()
        for (path, file) in entries {
            let name = Data(path.utf8)
            let payload = deflated ? deflate(file) : file
            let method = deflated ? Format.deflatedMethod : Format.storedMethod
            let checksum = CRC32.compute(file)
            let offset = UInt32(output.count)

            append(Format.localSignature, to: &output)
            append(Format.version, to: &output)
            append(UInt16(0), to: &output)
            append(method, to: &output)
            append(UInt16(0), to: &output)
            append(UInt16(0), to: &output)
            append(checksum, to: &output)
            append(UInt32(payload.count), to: &output)
            append(UInt32(file.count), to: &output)
            append(UInt16(name.count), to: &output)
            append(UInt16(0), to: &output)
            output.append(name)
            output.append(payload)

            append(Format.directorySignature, to: &directory)
            append(Format.version, to: &directory)
            append(Format.version, to: &directory)
            append(UInt16(0), to: &directory)
            append(method, to: &directory)
            append(UInt16(0), to: &directory)
            append(UInt16(0), to: &directory)
            append(checksum, to: &directory)
            append(UInt32(payload.count), to: &directory)
            append(UInt32(file.count), to: &directory)
            append(UInt16(name.count), to: &directory)
            append(UInt16(0), to: &directory)
            append(UInt16(0), to: &directory)
            append(UInt16(0), to: &directory)
            append(UInt16(0), to: &directory)
            append(UInt32(0), to: &directory)
            append(offset, to: &directory)
            directory.append(name)
        }

        let directoryOffset = UInt32(output.count)
        output.append(directory)
        appendEndOfDirectory(
            count: UInt16(entries.count),
            size: UInt32(directory.count),
            offset: directoryOffset,
            to: &output
        )
        return output
    }

    private static func appendEndOfDirectory(
        count: UInt16, size: UInt32, offset: UInt32, to output: inout Data
    ) {
        append(Format.endSignature, to: &output)
        append(UInt16(0), to: &output)
        append(UInt16(0), to: &output)
        append(count, to: &output)
        append(count, to: &output)
        append(size, to: &output)
        append(offset, to: &output)
        append(UInt16(0), to: &output)
    }

    private static func deflate(_ source: Data) -> Data {
        var output = Data(
            count: source.count * Format.compressionBufferMultiplier
                + Format.compressionBufferPadding
        )
        let capacity = output.count
        let written = output.withUnsafeMutableBytes { destination in
            source.withUnsafeBytes { input in
                guard let destinationBytes = destination.bindMemory(to: UInt8.self).baseAddress,
                    let inputBytes = input.bindMemory(to: UInt8.self).baseAddress
                else {
                    return 0
                }
                return compression_encode_buffer(
                    destinationBytes,
                    capacity,
                    inputBytes,
                    source.count,
                    nil,
                    COMPRESSION_ZLIB
                )
            }
        }
        precondition(written > 0)
        return output.prefix(written)
    }

    private static func append<T: FixedWidthInteger>(_ value: T, to data: inout Data) {
        withUnsafeBytes(of: value.littleEndian) { data.append(contentsOf: $0) }
    }
}
