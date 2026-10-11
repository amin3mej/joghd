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
        spine: [String]
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
        lines.append("</metadata>")
        lines.append("<manifest>")
        for item in manifest {
            lines.append(
                "<item id=\"\(item.id)\" href=\"\(item.href)\" "
                    + "media-type=\"application/xhtml+xml\"/>"
            )
        }
        lines.append("</manifest>")
        lines.append("<spine>")
        for idref in spine {
            lines.append("<itemref idref=\"\(idref)\"/>")
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

    static func zip(@Builder _ build: () -> [(String, String)]) -> Data {
        write(build())
    }

    private static func write(_ entries: [(String, String)]) -> Data {
        var output = Data()
        var directory = Data()
        for (path, contents) in entries {
            let name = Data(path.utf8)
            let file = Data(contents.utf8)
            let checksum = CRC32.compute(file)
            let offset = UInt32(output.count)

            append(Format.localSignature, to: &output)
            append(Format.version, to: &output)
            append(UInt16(0), to: &output)
            append(Format.storedMethod, to: &output)
            append(UInt16(0), to: &output)
            append(UInt16(0), to: &output)
            append(checksum, to: &output)
            append(UInt32(file.count), to: &output)
            append(UInt32(file.count), to: &output)
            append(UInt16(name.count), to: &output)
            append(UInt16(0), to: &output)
            output.append(name)
            output.append(file)

            append(Format.directorySignature, to: &directory)
            append(Format.version, to: &directory)
            append(Format.version, to: &directory)
            append(UInt16(0), to: &directory)
            append(Format.storedMethod, to: &directory)
            append(UInt16(0), to: &directory)
            append(UInt16(0), to: &directory)
            append(checksum, to: &directory)
            append(UInt32(file.count), to: &directory)
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
        append(Format.endSignature, to: &output)
        append(UInt16(0), to: &output)
        append(UInt16(0), to: &output)
        append(UInt16(entries.count), to: &output)
        append(UInt16(entries.count), to: &output)
        append(UInt32(directory.count), to: &output)
        append(directoryOffset, to: &output)
        append(UInt16(0), to: &output)
        return output
    }

    private static func append<T: FixedWidthInteger>(_ value: T, to data: inout Data) {
        withUnsafeBytes(of: value.littleEndian) { data.append(contentsOf: $0) }
    }
}
