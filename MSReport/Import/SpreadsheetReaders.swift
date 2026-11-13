import Foundation

private func localName(_ name: String) -> String {
    if let i = name.lastIndex(of: ":") { return String(name[name.index(after: i)...]) }
    return name
}

// MARK: - XLSX

enum XLSXReader {
    /// Возвращает лист с наибольшим числом строк.
    static func read(data: Data) throws -> [[String]] {
        let zip = try ZipArchive(data: data)
        let shared = zip.extract("xl/sharedStrings.xml").map(SharedStringsParser.parse) ?? []
        let sheets = zip.names
            .filter { $0.hasPrefix("xl/worksheets/") && $0.hasSuffix(".xml") }
            .sorted()
        guard !sheets.isEmpty else {
            throw ImportError.message("В файле не нашлось листов с данными.")
        }
        var best: [[String]] = []
        for path in sheets {
            guard let xml = zip.extract(path) else { continue }
            let rows = SheetParser.parse(xml, shared: shared)
            if rows.count > best.count { best = rows }
        }
        return best
    }
}

private final class SharedStringsParser: NSObject, XMLParserDelegate {
    private var strings: [String] = []
    private var current = ""
    private var inItem = false
    private var inText = false
    private var skipDepth = 0

    static func parse(_ data: Data) -> [String] {
        let delegate = SharedStringsParser()
        let parser = XMLParser(data: data)
        parser.delegate = delegate
        parser.parse()
        return delegate.strings
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?,
                qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        switch localName(elementName) {
        case "si": inItem = true; current = ""
        case "t": inText = true
        case "rPh": skipDepth += 1
        default: break
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?,
                qualifiedName qName: String?) {
        switch localName(elementName) {
        case "si": strings.append(current); inItem = false
        case "t": inText = false
        case "rPh": skipDepth -= 1
        default: break
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if inItem && inText && skipDepth == 0 { current += string }
    }
}

private final class SheetParser: NSObject, XMLParserDelegate {
    private let shared: [String]
    private var cells: [Int: [Int: String]] = [:]
    private var rowIndex = 0
    private var lastRow = -1
    private var colCursor = 0
    private var cellRef: String?
    private var cellType: String?
    private var value = ""
    private var inValue = false

    init(shared: [String]) {
        self.shared = shared
    }

    static func parse(_ data: Data, shared: [String]) -> [[String]] {
        let delegate = SheetParser(shared: shared)
        let parser = XMLParser(data: data)
        parser.delegate = delegate
        parser.parse()
        return delegate.result()
    }

    private func result() -> [[String]] {
        cells.keys.sorted().map { r in
            let row = cells[r] ?? [:]
            let width = (row.keys.max() ?? -1) + 1
            return (0..<width).map { row[$0] ?? "" }
        }
    }

    private static func columnIndex(_ ref: String) -> Int? {
        var n = 0
        var found = false
        for ch in ref.uppercased() {
            guard let a = ch.asciiValue, a >= 65, a <= 90 else { break }
            n = n * 26 + Int(a - 64)
            found = true
        }
        return found ? n - 1 : nil
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?,
                qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        switch localName(elementName) {
        case "row":
            if let r = attributeDict["r"], let n = Int(r) { rowIndex = n - 1 } else { rowIndex = lastRow + 1 }
            colCursor = 0
        case "c":
            cellRef = attributeDict["r"]
            cellType = attributeDict["t"]
            value = ""
        case "v":
            inValue = true
        case "t":
            if cellType == "inlineStr" { inValue = true }
        default:
            break
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?,
                qualifiedName qName: String?) {
        switch localName(elementName) {
        case "v", "t":
            inValue = false
        case "c":
            let col = cellRef.flatMap(SheetParser.columnIndex) ?? colCursor
            colCursor = col + 1
            var text = value
            if cellType == "s", let i = Int(value), i >= 0, i < shared.count {
                text = shared[i]
            } else if cellType == "b" {
                text = value == "1" ? "ИСТИНА" : "ЛОЖЬ"
            }
            text = text.trimmingCharacters(in: .whitespacesAndNewlines)
            if !text.isEmpty { cells[rowIndex, default: [:]][col] = text }
        case "row":
            lastRow = rowIndex
        default:
            break
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if inValue { value += string }
    }
}

// MARK: - XML Spreadsheet 2003 (часто так выгружает iiko под видом .xls)

final class XMLSpreadsheetParser: NSObject, XMLParserDelegate {
    private var rows: [[String]] = []
    private var row: [String] = []
    private var text = ""
    private var inData = false
    private var tableDone = false

    static func parse(_ data: Data) -> [[String]] {
        let delegate = XMLSpreadsheetParser()
        let parser = XMLParser(data: data)
        parser.delegate = delegate
        parser.parse()
        return delegate.rows
    }

    func parser(_ parser: XMLParser, didStartElement elementName: String, namespaceURI: String?,
                qualifiedName qName: String?, attributes attributeDict: [String: String] = [:]) {
        switch localName(elementName) {
        case "Row":
            row = []
        case "Cell":
            if let idx = attributeDict["ss:Index"] ?? attributeDict["Index"], let n = Int(idx) {
                while row.count < n - 1 { row.append("") }
            }
            text = ""
        case "Data":
            inData = true
        default:
            break
        }
    }

    func parser(_ parser: XMLParser, didEndElement elementName: String, namespaceURI: String?,
                qualifiedName qName: String?) {
        switch localName(elementName) {
        case "Data":
            inData = false
        case "Cell":
            row.append(text.trimmingCharacters(in: .whitespacesAndNewlines))
        case "Row":
            if !tableDone { rows.append(row) }
        case "Table":
            tableDone = true
        default:
            break
        }
    }

    func parser(_ parser: XMLParser, foundCharacters string: String) {
        if inData { text += string }
    }
}

// MARK: - HTML-таблица (некоторые кассы и ОФД отдают .xls, который на деле HTML)

enum HTMLTableReader {
    private static let rowRx = try? NSRegularExpression(
        pattern: "<tr[^>]*>(.*?)</tr>", options: [.caseInsensitive, .dotMatchesLineSeparators])
    private static let cellRx = try? NSRegularExpression(
        pattern: "<t[dh][^>]*>(.*?)</t[dh]>", options: [.caseInsensitive, .dotMatchesLineSeparators])
    private static let tagRx = try? NSRegularExpression(pattern: "<[^>]+>", options: [])

    static func read(_ html: String) -> [[String]] {
        guard let rowRx, let cellRx else { return [] }
        let ns = html as NSString
        var rows: [[String]] = []
        for m in rowRx.matches(in: html, range: NSRange(location: 0, length: ns.length)) {
            let rowHTML = ns.substring(with: m.range(at: 1))
            let rns = rowHTML as NSString
            let cells = cellRx.matches(in: rowHTML, range: NSRange(location: 0, length: rns.length)).map {
                clean(rns.substring(with: $0.range(at: 1)))
            }
            if !cells.isEmpty { rows.append(cells) }
        }
        return rows
    }

    private static func clean(_ s: String) -> String {
        var t = s
        if let tagRx {
            t = tagRx.stringByReplacingMatches(in: t, range: NSRange(location: 0, length: (t as NSString).length), withTemplate: " ")
        }
        let entities = ["&nbsp;": " ", "&amp;": "&", "&lt;": "<", "&gt;": ">", "&quot;": "\"", "&#39;": "'", "&#160;": " "]
        for (k, v) in entities { t = t.replacingOccurrences(of: k, with: v) }
        return t
            .components(separatedBy: .whitespacesAndNewlines)
            .filter { !$0.isEmpty }
            .joined(separator: " ")
    }
}

// MARK: - CSV

enum CSVReader {
    static func read(text: String) -> [[String]] {
        var t = text
        if t.hasPrefix("\u{FEFF}") { t.removeFirst() }

        // Разделитель: что чаще встречается в начале файла
        let head = String(t.prefix(4_000))
        let candidates: [Character] = [";", "\t", ","]
        let delimiter = candidates.max { a, b in
            head.filter { $0 == a }.count < head.filter { $0 == b }.count
        } ?? ";"
        let d = delimiter.unicodeScalars.first ?? ";"

        var rows: [[String]] = []
        var row: [String] = []
        var field = String.UnicodeScalarView()
        var inQuotes = false
        let scalars = Array(t.unicodeScalars)
        var i = 0

        func endRow() {
            row.append(String(field))
            field = String.UnicodeScalarView()
            if row.contains(where: { !$0.trimmingCharacters(in: .whitespaces).isEmpty }) {
                rows.append(row.map { $0.trimmingCharacters(in: .whitespaces) })
            }
            row = []
        }

        while i < scalars.count {
            let c = scalars[i]
            if inQuotes {
                if c == "\"" {
                    if i + 1 < scalars.count && scalars[i + 1] == "\"" {
                        field.append("\"")
                        i += 1
                    } else {
                        inQuotes = false
                    }
                } else {
                    field.append(c)
                }
            } else if c == "\"" {
                inQuotes = true
            } else if c == d {
                row.append(String(field))
                field = String.UnicodeScalarView()
            } else if c == "\n" || c == "\r" {
                if c == "\r" && i + 1 < scalars.count && scalars[i + 1] == "\n" { i += 1 }
                endRow()
            } else {
                field.append(c)
            }
            i += 1
        }
        if !field.isEmpty || !row.isEmpty { endRow() }
        return rows
    }
}

enum TextDecoder {
    static func decode(_ data: Data) -> String? {
        if data.starts(with: [0xFF, 0xFE]) || data.starts(with: [0xFE, 0xFF]) {
            return String(data: data, encoding: .utf16)
        }
        if let s = String(data: data, encoding: .utf8) { return s }
        return String(data: data, encoding: .windowsCP1251)
    }
}
