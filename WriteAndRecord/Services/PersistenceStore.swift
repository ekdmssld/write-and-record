import Foundation

/// Codable JSON 파일 기반 로컬 저장소.
/// Documents/WriteAndRecordData/ 아래에 항목별 json 파일을 둔다.
/// schemaVersion을 파일에 함께 기록해 추후 마이그레이션이 가능하게 한다.
struct PersistenceStore {
    static let currentSchemaVersion = 1

    struct Envelope<T: Codable>: Codable {
        var schemaVersion: Int
        var payload: T
    }

    static var dataDirectory: URL {
        let docs = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let dir = docs.appendingPathComponent("WriteAndRecordData", isDirectory: true)
        if !FileManager.default.fileExists(atPath: dir.path) {
            try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        }
        return dir
    }

    static func fileURL(_ name: String) -> URL {
        dataDirectory.appendingPathComponent("\(name).json")
    }

    static func makeEncoder() -> JSONEncoder {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        return encoder
    }

    static func makeDecoder() -> JSONDecoder {
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        return decoder
    }

    static func load<T: Codable>(_ type: T.Type, from name: String) -> T? {
        let url = fileURL(name)
        guard let data = try? Data(contentsOf: url) else { return nil }
        let decoder = makeDecoder()
        if let envelope = try? decoder.decode(Envelope<T>.self, from: data) {
            return envelope.payload
        }
        // envelope 없이 저장된 구버전 파일 호환
        return try? decoder.decode(T.self, from: data)
    }

    @discardableResult
    static func save<T: Codable>(_ value: T, to name: String) -> Bool {
        let url = fileURL(name)
        let envelope = Envelope(schemaVersion: currentSchemaVersion, payload: value)
        do {
            let data = try makeEncoder().encode(envelope)
            try data.write(to: url, options: [.atomic])
            return true
        } catch {
            // 민감 데이터(제목/본문)는 로그에 남기지 않는다.
            return false
        }
    }

    static func delete(_ name: String) {
        try? FileManager.default.removeItem(at: fileURL(name))
    }

    static func deleteAll() {
        try? FileManager.default.removeItem(at: dataDirectory)
    }
}
