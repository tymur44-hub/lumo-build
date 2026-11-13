import Foundation
import Compression

enum ImportError: LocalizedError {
    case message(String)

    var errorDescription: String? {
        switch self {
        case .message(let m): return m
        }
    }
}

/// Минимальный ZIP-ридер (файл .xlsx — это ZIP-архив с XML внутри).
/// Без сторонних библиотек: распаковка через системный Compression.
struct ZipArchive {
    struct Entry {
        let method: UInt16
        let compressedSize: Int
        let uncompressedSize: Int
        let localOffset: Int
    }

    private let bytes: [UInt8]
    private var entries: [String: Entry] = [:]

    var names: [String] { Array(entries.keys) }

    init(data: Data) throws {
        bytes = [UInt8](data)
        guard bytes.count > 22 else {
            throw ImportError.message("Файл пустой или повреждён.")
        }

        // Ищем конец центрального каталога с конца файла
        var eocd = -1
        var i = bytes.count - 22
        let lower = max(0, bytes.count - 22 - 65_535)
        while i >= lower {
            if u32(i) == 0x0605_4b50 { eocd = i; break }
            i -= 1
        }
        guard eocd >= 0 else {
            throw ImportError.message("Не удалось прочитать файл Excel. Сохраните его заново как .xlsx или .csv.")
        }

        let count = Int(u16(eocd + 10))
        var p = Int(u32(eocd + 16))
        for _ in 0..<count {
            guard p + 46 <= bytes.count, u32(p) == 0x0201_4b50 else { break }
            let method = u16(p + 10)
            let compressed = Int(u32(p + 20))
            let uncompressed = Int(u32(p + 24))
            let nameLen = Int(u16(p + 28))
            let extraLen = Int(u16(p + 30))
            let commentLen = Int(u16(p + 32))
            let local = Int(u32(p + 42))
            guard p + 46 + nameLen <= bytes.count else { break }
            let name = String(decoding: bytes[(p + 46)..<(p + 46 + nameLen)], as: UTF8.self)
            entries[name] = Entry(method: method, compressedSize: compressed, uncompressedSize: uncompressed, localOffset: local)
            p += 46 + nameLen + extraLen + commentLen
        }
    }

    func contains(_ name: String) -> Bool { entries[name] != nil }

    func extract(_ name: String) -> Data? {
        guard let e = entries[name] else { return nil }
        let lo = e.localOffset
        guard lo + 30 <= bytes.count, u32(lo) == 0x0403_4b50 else { return nil }
        let start = lo + 30 + Int(u16(lo + 26)) + Int(u16(lo + 28))
        guard start + e.compressedSize <= bytes.count else { return nil }
        let source = Array(bytes[start..<(start + e.compressedSize)])

        switch e.method {
        case 0:
            return Data(source)
        case 8:
            guard e.uncompressedSize > 0 else { return Data() }
            let capacity = e.uncompressedSize
            var output = [UInt8](repeating: 0, count: capacity)
            let written = output.withUnsafeMutableBufferPointer { dst -> Int in
                source.withUnsafeBufferPointer { src -> Int in
                    guard let d = dst.baseAddress, let s = src.baseAddress else { return 0 }
                    // COMPRESSION_ZLIB в Apple — это «сырой» DEFLATE, как в ZIP
                    return compression_decode_buffer(d, capacity, s, source.count, nil, COMPRESSION_ZLIB)
                }
            }
            guard written > 0 else { return nil }
            return Data(output.prefix(written))
        default:
            return nil
        }
    }

    private func u16(_ o: Int) -> UInt16 {
        UInt16(bytes[o]) | (UInt16(bytes[o + 1]) << 8)
    }

    private func u32(_ o: Int) -> UInt32 {
        UInt32(bytes[o])
            | (UInt32(bytes[o + 1]) << 8)
            | (UInt32(bytes[o + 2]) << 16)
            | (UInt32(bytes[o + 3]) << 24)
    }
}
