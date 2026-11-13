import Foundation
import UniformTypeIdentifiers

/// Открывает файл выгрузки и превращает его в таблицу.
enum FileLoader {
    static var allowedTypes: [UTType] {
        var types: [UTType] = [.commaSeparatedText, .tabSeparatedText, .spreadsheet, .plainText, .html, .xml]
        if let xlsx = UTType(filenameExtension: "xlsx") { types.insert(xlsx, at: 0) }
        if let xls = UTType(filenameExtension: "xls") { types.append(xls) }
        return types
    }

    static func load(url: URL) throws -> RawTable {
        let access = url.startAccessingSecurityScopedResource()
        defer { if access { url.stopAccessingSecurityScopedResource() } }

        let data = try Data(contentsOf: url)
        let grid: [[String]]

        if data.starts(with: [0x50, 0x4B]) {
            grid = try XLSXReader.read(data: data)
        } else if data.starts(with: [0xD0, 0xCF, 0x11, 0xE0]) {
            throw ImportError.message("Это старый формат Excel (.xls). Откройте файл в Excel или Numbers и сохраните как .xlsx или .csv.")
        } else {
            guard let text = TextDecoder.decode(data) else {
                throw ImportError.message("Не удалось прочитать текст файла.")
            }
            let head = String(text.prefix(4_000)).lowercased()
            if head.contains("urn:schemas-microsoft-com:office:spreadsheet") || head.contains("<workbook") {
                grid = XMLSpreadsheetParser.parse(data)
            } else if head.contains("<table") || head.contains("<html") {
                grid = HTMLTableReader.read(text)
            } else {
                grid = CSVReader.read(text: text)
            }
        }

        let table = ColumnDetector.locateHeader(grid)
        guard !table.rows.isEmpty else {
            throw ImportError.message("В файле не нашлось строк с данными.")
        }
        return table
    }
}

/// Находит строку заголовков и угадывает, что в каком столбце.
enum ColumnDetector {

    static func locateHeader(_ grid: [[String]]) -> RawTable {
        let nonEmpty = grid.filter { row in
            row.contains { cell in !cell.trimmingCharacters(in: .whitespaces).isEmpty }
        }
        guard !nonEmpty.isEmpty else { return RawTable(headers: [], rows: []) }

        // Над таблицей часто бывает шапка отчёта — ищем строку, больше всего похожую на заголовки
        var best = 0
        var bestScore = 0
        for (i, row) in nonEmpty.prefix(25).enumerated() {
            let score = Set(row.compactMap { role(for: $0) }).count
            if score > bestScore {
                bestScore = score
                best = i
            }
        }

        let width = nonEmpty.map(\.count).max() ?? 0
        let headerRow = nonEmpty[best] + Array(repeating: "", count: max(0, width - nonEmpty[best].count))
        let headers = headerRow.enumerated().map { i, h -> String in
            let t = h.trimmingCharacters(in: .whitespacesAndNewlines)
            return t.isEmpty ? "Столбец \(i + 1)" : t
        }
        return RawTable(headers: headers, rows: Array(nonEmpty.dropFirst(best + 1)))
    }

    static func detect(headers: [String]) -> [ColumnRole: Int] {
        var candidates: [ColumnRole: [Int]] = [:]
        for (i, h) in headers.enumerated() {
            if let r = role(for: h) { candidates[r, default: []].append(i) }
        }
        var result: [ColumnRole: Int] = [:]
        for (role, indices) in candidates {
            if role == .amount, indices.count > 1 {
                let preferredWords = ["со скид", "с учетом", "с учётом", "итог", "оплач", "выручк"]
                let preferred = indices.first { i in
                    let h = headers[i].lowercased()
                    return preferredWords.contains { h.contains($0) }
                }
                result[role] = preferred ?? indices.first
            } else {
                result[role] = indices.first
            }
        }
        return result
    }

    static func role(for header: String) -> ColumnRole? {
        let h = header.lowercased().trimmingCharacters(in: .whitespacesAndNewlines)
        guard !h.isEmpty, h.count < 60 else { return nil }
        func has(_ words: String...) -> Bool { words.contains { h.contains($0) } }

        if has("себестоим", "cost") { return .cost }
        if has("скидк", "discount") && !has("со скид", "с учетом", "с учётом", "без скид") { return .discount }
        if has("точк", "магазин", "филиал", "заведен", "подразделен", "предприят", "кофейн", "store", "location") { return .store }
        if (has("чек") && !has("средн", "кол")) || has("номер заказа", "№ заказа", "receipt", "order id") { return .check }
        if has("дата", "date") || (has("день") && !has("недел")) { return .date }
        if has("время", "час", "time", "hour") { return .time }
        if has("категор", "групп", "раздел", "category", "group") { return .category }
        if has("цена", "price") { return .price }
        if has("кол-во", "колич", "qty", "quantity") || h == "кол" || h == "шт" { return .quantity }
        if has("сумм", "выручк", "итог", "оплач", "стоимост", "amount", "total", "revenue") { return .amount }
        if has("наимен", "товар", "блюд", "позици", "номенкл", "продукт", "назван", "item", "product", "name") { return .item }
        return nil
    }
}
