import Foundation
import Combine

/// Entry 저장 상태 머신 (Flowchart 4):
/// Editing -> DraftSaved -> Validating -> Saving -> Saved / SaveFailed
final class EntryEditorViewModel: ObservableObject {
    enum SaveState: Equatable {
        case editing
        case saving
        case saved
        case saveFailed
    }

    @Published var entry: Entry
    @Published var pendingAssets: [MediaAsset] = []
    @Published var saveState: SaveState = .editing
    @Published var hasChanges = false
    @Published var didRestoreDraft = false

    let editingEntryId: String?

    private var autosaveTimer: Timer?
    private var isConfigured = false

    init(date: Date, categoryId: String, editingEntryId: String?) {
        self.editingEntryId = editingEntryId
        self.entry = Entry.new(userId: "local-user", date: date, categoryId: categoryId)
    }

    /// EnvironmentObject는 init에서 접근할 수 없으므로 onAppear에서 주입한다.
    func configure(repository: EntryRepository, userId: String) {
        guard !isConfigured else { return }
        isConfigured = true

        if let editingEntryId, let existing = repository.entry(id: editingEntryId) {
            entry = existing
            pendingAssets = repository.assets(for: existing)
        } else {
            entry.userId = userId
        }

        restoreDraftIfMatching()
    }

    /// 앱 강제 종료로 남은 draft가 지금 여는 편집 대상과 일치하면 복원.
    private func restoreDraftIfMatching() {
        guard let draft = DraftStore.load() else { return }
        let matchesExisting = draft.entryId != nil && draft.entryId == editingEntryId
        let matchesNew = draft.entryId == nil && editingEntryId == nil
            && Calendar.current.isDate(draft.entry.date, inSameDayAs: entry.date)
            && draft.entry.categoryId == entry.categoryId
        if matchesExisting || matchesNew {
            entry = draft.entry
            didRestoreDraft = true
            hasChanges = true
        }
    }

    // MARK: - Validation (Functional Spec 8장)

    var isTitleValid: Bool { Validation.isValidEntryTitle(entry.title) }
    var isBodyValid: Bool { Validation.isValidBody(entry.body) }
    var areLinksValid: Bool { entry.links.allSatisfy { Validation.isValidURL($0.url) } }
    var isCountValid: Bool { Validation.isValidCount(entry.count) }

    var canSave: Bool {
        isTitleValid && isBodyValid && areLinksValid && isCountValid
            && Validation.isValidRating(entry.rating)
            && !entry.categoryId.isEmpty
            && saveState != .saving
    }

    // MARK: - Draft autosave (5초 debounce)

    func noteChanged() {
        hasChanges = true
        autosaveTimer?.invalidate()
        autosaveTimer = Timer.scheduledTimer(withTimeInterval: 5, repeats: false) { [weak self] _ in
            self?.saveDraftNow()
        }
    }

    func saveDraftNow() {
        guard hasChanges else { return }
        DraftStore.save(entry, editingEntryId: editingEntryId)
    }

    // MARK: - Save

    func save(to repository: EntryRepository) -> Bool {
        guard canSave else { return false }
        saveState = .saving

        entry.title = entry.title.trimmingCharacters(in: .whitespacesAndNewlines)
        entry.pros = entry.pros.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        entry.cons = entry.cons.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        entry.tips = entry.tips.filter { !$0.trimmingCharacters(in: .whitespaces).isEmpty }
        entry.metadata = entry.metadata.filter { !$0.value.trimmingCharacters(in: .whitespaces).isEmpty }
        entry.assetIds = pendingAssets.map { $0.id }
        if entry.coverAssetId == nil || !entry.assetIds.contains(entry.coverAssetId ?? "") {
            entry.coverAssetId = entry.assetIds.first
        }
        if let place = entry.place, place.name.trimmingCharacters(in: .whitespaces).isEmpty {
            entry.place = nil
        }

        let success = repository.save(entry, assets: pendingAssets)
        if success {
            DraftStore.clear()
            saveState = .saved
        } else {
            // 저장 실패 시 draft 보존 + 재시도 (Product Spec 13장)
            DraftStore.save(entry, editingEntryId: editingEntryId)
            saveState = .saveFailed
        }
        return success
    }

    func cancelAutosave() {
        autosaveTimer?.invalidate()
        autosaveTimer = nil
    }
}
