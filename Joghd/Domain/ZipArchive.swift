import Compression
import Foundation

struct ZipArchive {
    private struct Entry {
        let method: UInt16
        let compressedSize: Int
        let uncompressedSize: Int
        let localOffset: Int
    }

    private static let endOfDirectorySignature: UInt32 = 0x0605_4B50
    private static let directorySignature: UInt32 = 0x0201_4B50
    private static let localSignature: UInt32 = 0x0403_4B50
    private static let storedMethod: UInt16 = 0
    private static let deflatedMethod: UInt16 = 8
    private static let endOfDirectoryMinimumSize = 22
    private static let maximumCommentLength = 0xFFFF
    private static let directoryEntryMinimumSize = 46
    private static let localHeaderMinimumSize = 30
    private static let entryCountOffset = 10
    private static let directoryOffsetOffset = 16
    private static let methodOffset = 10
    private static let compressedSizeOffset = 20
    private static let uncompressedSizeOffset = 24
    private static let nameLengthOffset = 28
    private static let extraLengthOffset = 30
    private static let commentLengthOffset = 32
    private static let localOffsetOffset = 42
    private static let localNameLengthOffset = 26
    private static let localExtraLengthOffset = 28
    private static let maximumCompressionRatio = 200
    private static let maximumEntrySize = 67_108_864

    private let data: Data
    private let entries: [String: Entry]

    init(data: Data) throws {
        self.data = data
        self.entries = try Self.readEntries(in: data)
    }

    private static func readEntries(in data: Data) throws -> [String: Entry] {
        guard let end = endOfDirectory(in: data) else {
            throw BookParsingError.malformedEpub
        }
        let count = Int(readUInt16(data, at: end + entryCountOffset))
        var offset = Int(readUInt32(data, at: end + directoryOffsetOffset))
        var result: [String: Entry] = [:]

        for _ in 0..<count {
            guard readUInt32(data, at: offset) == directorySignature else {
                throw BookParsingError.malformedEpub
            }
            let method = readUInt16(data, at: offset + methodOffset)
            let compressedSize = Int(readUInt32(data, at: offset + compressedSizeOffset))
            let uncompressedSize = Int(readUInt32(data, at: offset + uncompressedSizeOffset))
            let nameLength = Int(readUInt16(data, at: offset + nameLengthOffset))
            let extraLength = Int(readUInt16(data, at: offset + extraLengthOffset))
            let commentLength = Int(readUInt16(data, at: offset + commentLengthOffset))
            let localOffset = Int(readUInt32(data, at: offset + localOffsetOffset))
            let nameStart = offset + directoryEntryMinimumSize
            guard nameStart + nameLength <= data.count else {
                throw BookParsingError.malformedEpub
            }
            let rawName = data[nameStart..<(nameStart + nameLength)]
            guard let name = String(bytes: rawName, encoding: .utf8) else {
                throw BookParsingError.malformedEpub
            }

            result[name] = Entry(
                method: method,
                compressedSize: compressedSize,
                uncompressedSize: uncompressedSize,
                localOffset: localOffset
            )
            offset = nameStart + nameLength + extraLength + commentLength
        }
        return result
    }

    private static func endOfDirectory(in data: Data) -> Int? {
        let minimum = endOfDirectoryMinimumSize
        guard data.count >= minimum else {
            return nil
        }
        let lowest = max(0, data.count - minimum - maximumCommentLength)
        var offset = data.count - minimum
        while offset >= lowest {
            if readUInt32(data, at: offset) == endOfDirectorySignature {
                return offset
            }
            offset -= 1
        }
        return nil
    }

    private static func readUInt16(_ data: Data, at offset: Int) -> UInt16 {
        readInteger(data, at: offset)
    }

    private static func readUInt32(_ data: Data, at offset: Int) -> UInt32 {
        readInteger(data, at: offset)
    }

    private static func readInteger<T: FixedWidthInteger>(_ data: Data, at offset: Int) -> T {
        let size = MemoryLayout<T>.size
        guard offset >= 0, offset + size <= data.count else {
            return 0
        }
        let value = data[offset..<(offset + size)].withUnsafeBytes { buffer in
            buffer.loadUnaligned(as: T.self)
        }
        return T(littleEndian: value)
    }

    private static func inflate(_ source: Data, size: Int) -> Data? {
        guard size > 0 else {
            return Data()
        }
        var output = Data(count: size)
        let written = output.withUnsafeMutableBytes { destination -> Int in
            source.withUnsafeBytes { input -> Int in
                guard let destinationBytes = destination.bindMemory(to: UInt8.self).baseAddress,
                    let inputBytes = input.bindMemory(to: UInt8.self).baseAddress
                else {
                    return 0
                }
                return compression_decode_buffer(
                    destinationBytes,
                    size,
                    inputBytes,
                    source.count,
                    nil,
                    COMPRESSION_ZLIB
                )
            }
        }
        guard written == size else {
            return nil
        }
        return output
    }

    func data(for path: String) throws -> Data? {
        guard let entry = entries[path] else {
            return nil
        }
        return try extract(entry)
    }

    private func extract(_ entry: Entry) throws -> Data {
        guard entry.uncompressedSize <= Self.maximumEntrySize,
            entry.uncompressedSize <= entry.compressedSize * Self.maximumCompressionRatio
        else {
            throw BookParsingError.malformedEpub
        }
        let offset = entry.localOffset
        guard Self.readUInt32(data, at: offset) == Self.localSignature else {
            throw BookParsingError.malformedEpub
        }
        let nameLength = Int(Self.readUInt16(data, at: offset + Self.localNameLengthOffset))
        let extraLength = Int(Self.readUInt16(data, at: offset + Self.localExtraLengthOffset))
        let start = offset + Self.localHeaderMinimumSize + nameLength + extraLength
        guard start >= 0, start + entry.compressedSize <= data.count else {
            throw BookParsingError.malformedEpub
        }
        let compressed = data.subdata(in: start..<(start + entry.compressedSize))

        if entry.method == Self.storedMethod {
            return compressed
        }
        if entry.method == Self.deflatedMethod {
            guard let inflated = Self.inflate(compressed, size: entry.uncompressedSize) else {
                throw BookParsingError.malformedEpub
            }
            return inflated
        }
        throw BookParsingError.malformedEpub
    }
}
