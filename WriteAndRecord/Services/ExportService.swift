import Foundation

/// 개인 데이터 JSON export (P0 필수: 데이터 유실 방지).
enum ExportService {
    struct ExportBundle: Codable {
        var exportedAt: Date
        var appVersion: String
        var schemaVersion: Int
        var profile: UserProfile?
        var categories: [EntryCategory]
        var entries: [Entry]
        var mediaAssets: [MediaAsset]
        var collections: [EntryCollection]
        var recordCards: [RecordCard]
    }

    static func makeExportFile(
        profile: UserProfile?,
        categories: [EntryCategory],
        entries: [Entry],
        mediaAssets: [MediaAsset],
        collections: [EntryCollection],
        recordCards: [RecordCard]
    ) -> URL? {
        let bundle = ExportBundle(
            exportedAt: Date(),
            appVersion: BuildConfiguration.appVersionString,
            schemaVersion: PersistenceStore.currentSchemaVersion,
            profile: profile,
            categories: categories,
            entries: entries,
            mediaAssets: mediaAssets,
            collections: collections,
            recordCards: recordCards
        )
        guard let data = try? PersistenceStore.makeEncoder().encode(bundle) else { return nil }

        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        let fileName = "WriteAndRecord-export-\(formatter.string(from: Date())).json"
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(fileName)
        do {
            try data.write(to: url, options: [.atomic])
            return url
        } catch {
            return nil
        }
    }

    // MARK: - Import / Restore (docs/13 백로그 P1)

    enum ImportError: Error, LocalizedError {
        case unreadable
        case invalidFormat
        case newerSchema(Int)

        var errorDescription: String? {
            switch self {
            case .unreadable: return "파일을 읽지 못했어요."
            case .invalidFormat: return "Write & Record 백업 파일이 아니에요."
            case .newerSchema(let version):
                return "더 새로운 버전의 백업이에요 (v\(version)). 앱을 업데이트해 주세요."
            }
        }
    }

    /// 백업 JSON을 읽어 ExportBundle로 파싱한다. 적용 전 확인용으로만 사용.
    static func readBundle(from url: URL) throws -> ExportBundle {
        let needsScopedAccess = url.startAccessingSecurityScopedResource()
        defer {
            if needsScopedAccess {
                url.stopAccessingSecurityScopedResource()
            }
        }
        guard let data = try? Data(contentsOf: url) else {
            throw ImportError.unreadable
        }
        guard let bundle = try? PersistenceStore.makeDecoder().decode(ExportBundle.self, from: data) else {
            throw ImportError.invalidFormat
        }
        guard bundle.schemaVersion <= PersistenceStore.currentSchemaVersion else {
            throw ImportError.newerSchema(bundle.schemaVersion)
        }
        return bundle
    }
}
