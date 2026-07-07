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
}
