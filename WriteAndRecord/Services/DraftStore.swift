import Foundation

/// 편집 중인 기록의 autosave draft.
/// 저장 실패/앱 강제 종료 시에도 입력 내용을 잃지 않는다.
struct EntryDraft: Codable {
    /// 기존 기록 편집이면 entryId, 새 기록이면 nil.
    var entryId: String?
    var entry: Entry
    var savedAt: Date
}

enum DraftStore {
    private static let draftFile = "entryDraft"

    static func save(_ entry: Entry, editingEntryId: String?) {
        let draft = EntryDraft(entryId: editingEntryId, entry: entry, savedAt: Date())
        PersistenceStore.save(draft, to: draftFile)
    }

    static func load() -> EntryDraft? {
        PersistenceStore.load(EntryDraft.self, from: draftFile)
    }

    static func clear() {
        PersistenceStore.delete(draftFile)
    }
}
