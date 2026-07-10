import Foundation
import Combine

/// 모든 Library 뷰의 단일 source of truth.
final class EntryRepository: ObservableObject {
    @Published private(set) var entries: [Entry] = []
    @Published private(set) var mediaAssets: [MediaAsset] = []
    @Published private(set) var recordCards: [RecordCard] = []
    @Published private(set) var collections: [EntryCollection] = []

    private let entriesFile = "entries"
    private let assetsFile = "mediaAssets"
    private let cardsFile = "recordCards"
    private let collectionsFile = "collections"

    init() {
        load()
    }

    func load() {
        entries = PersistenceStore.load([Entry].self, from: entriesFile) ?? []
        mediaAssets = PersistenceStore.load([MediaAsset].self, from: assetsFile) ?? []
        recordCards = PersistenceStore.load([RecordCard].self, from: cardsFile) ?? []
        collections = PersistenceStore.load([EntryCollection].self, from: collectionsFile) ?? []
    }

    /// 삭제되지 않은 기록만.
    var activeEntries: [Entry] {
        entries.filter { !$0.isDeleted }
    }

    func entry(id: String) -> Entry? {
        entries.first { $0.id == id && !$0.isDeleted }
    }

    func entries(on date: Date) -> [Entry] {
        activeEntries
            .filter { Calendar.current.isDate($0.date, inSameDayAs: date) }
            .sorted { $0.createdAt > $1.createdAt }
    }

    func entriesByDateDescending() -> [Entry] {
        activeEntries.sorted { $0.date > $1.date }
    }

    func entryCountsByDay(in month: Date) -> [Int: [Entry]] {
        let calendar = Calendar.current
        var result: [Int: [Entry]] = [:]
        for entry in activeEntries {
            guard calendar.isDate(entry.date, equalTo: month, toGranularity: .month) else { continue }
            let day = calendar.component(.day, from: entry.date)
            result[day, default: []].append(entry)
        }
        return result
    }

    @discardableResult
    func save(_ entry: Entry, assets: [MediaAsset] = []) -> Bool {
        var updated = entry
        updated.updatedAt = Date()

        var newEntries = entries
        if let index = newEntries.firstIndex(where: { $0.id == entry.id }) {
            newEntries[index] = updated
        } else {
            newEntries.append(updated)
        }

        var newAssets = mediaAssets
        for asset in assets where !newAssets.contains(where: { $0.id == asset.id }) {
            newAssets.append(asset)
        }

        guard PersistenceStore.save(newEntries, to: entriesFile) else { return false }
        PersistenceStore.save(newAssets, to: assetsFile)
        entries = newEntries
        mediaAssets = newAssets
        return true
    }

    /// soft delete.
    @discardableResult
    func delete(_ entry: Entry) -> Bool {
        guard let index = entries.firstIndex(where: { $0.id == entry.id }) else { return false }
        var deleted = entries[index]
        deleted.deletedAt = Date()
        var newEntries = entries
        newEntries[index] = deleted
        guard PersistenceStore.save(newEntries, to: entriesFile) else { return false }
        entries = newEntries
        return true
    }

    func asset(id: String) -> MediaAsset? {
        mediaAssets.first { $0.id == id }
    }

    func assets(for entry: Entry) -> [MediaAsset] {
        entry.assetIds.compactMap { asset(id: $0) }
    }

    func coverAsset(for entry: Entry) -> MediaAsset? {
        if let coverId = entry.coverAssetId, let cover = asset(id: coverId) {
            return cover
        }
        return entry.assetIds.first.flatMap { asset(id: $0) }
    }

    @discardableResult
    func saveCard(_ card: RecordCard) -> Bool {
        var newCards = recordCards
        newCards.append(card)
        guard PersistenceStore.save(newCards, to: cardsFile) else { return false }
        recordCards = newCards
        return true
    }

    // MARK: - Search / Filter

    /// 검색 정렬 (docs/05 11장).
    enum SearchSort: String, CaseIterable, Identifiable {
        case dateDesc
        case dateAsc
        case createdDesc
        case ratingDesc

        var id: String { rawValue }

        var displayName: String {
            switch self {
            case .dateDesc: return "최신 날짜순"
            case .dateAsc: return "오래된 날짜순"
            case .createdDesc: return "최근 작성순"
            case .ratingDesc: return "별점 높은순"
            }
        }
    }

    struct SearchFilter {
        var text: String = ""
        var categoryId: String?
        var minRating: Int?
        var wishlistOnly: Bool = false
        var hasPhotoOnly: Bool = false
        var hasPlaceOnly: Bool = false
        /// 날짜 범위 (둘 다 그날 포함).
        var dateFrom: Date?
        var dateTo: Date?
        var sort: SearchSort = .dateDesc

        var isEmpty: Bool {
            text.trimmingCharacters(in: .whitespaces).isEmpty
                && categoryId == nil && minRating == nil
                && !wishlistOnly && !hasPhotoOnly && !hasPlaceOnly
                && dateFrom == nil && dateTo == nil
        }
    }

    func search(_ filter: SearchFilter, categories: [EntryCategory]) -> [Entry] {
        let query = filter.text.trimmingCharacters(in: .whitespaces).lowercased()
        let calendar = Calendar.current
        let matched = activeEntries.filter { entry in
            if let categoryId = filter.categoryId {
                let matchesCategory = entry.categoryId == categoryId
                    || categories.first(where: { $0.id == entry.categoryId })?.parentId == categoryId
                if !matchesCategory { return false }
            }
            if let minRating = filter.minRating {
                guard let rating = entry.rating, rating >= minRating else { return false }
            }
            if filter.wishlistOnly && !entry.isWishlist { return false }
            if filter.hasPhotoOnly && entry.assetIds.isEmpty { return false }
            if filter.hasPlaceOnly && entry.place == nil { return false }
            if let from = filter.dateFrom, entry.date < calendar.startOfDay(for: from) { return false }
            if let to = filter.dateTo {
                let endOfDay = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: to)) ?? to
                if entry.date >= endOfDay { return false }
            }
            if !query.isEmpty {
                let categoryName = categories.first { $0.id == entry.categoryId }?.name ?? entry.archivedCategoryName ?? ""
                let haystack = [
                    entry.title,
                    entry.body,
                    categoryName,
                    entry.place?.name ?? "",
                    entry.links.map { ($0.title ?? "") + " " + $0.url }.joined(separator: " ")
                ].joined(separator: " ").lowercased()
                if !haystack.contains(query) { return false }
            }
            return true
        }

        switch filter.sort {
        case .dateDesc:
            return matched.sorted { $0.date > $1.date }
        case .dateAsc:
            return matched.sorted { $0.date < $1.date }
        case .createdDesc:
            return matched.sorted { $0.createdAt > $1.createdAt }
        case .ratingDesc:
            // 별점 없는 기록은 뒤로, 같은 별점은 최신순
            return matched.sorted {
                let lhs = $0.rating ?? -1
                let rhs = $1.rating ?? -1
                if lhs != rhs { return lhs > rhs }
                return $0.date > $1.date
            }
        }
    }

    // MARK: - Manual collections (docs/01 P2)

    /// 사용자 컬렉션. Collection.entryIds를 단일 source of truth로 사용한다.
    var manualCollections: [EntryCollection] {
        collections.sorted { $0.sortOrder < $1.sortOrder }
    }

    func collection(id: String) -> EntryCollection? {
        collections.first { $0.id == id }
    }

    @discardableResult
    func createCollection(name: String, description: String?) -> EntryCollection {
        let now = Date()
        let newCollection = EntryCollection(
            id: UUID().uuidString,
            name: name.trimmingCharacters(in: .whitespaces),
            description: description?.trimmingCharacters(in: .whitespaces),
            coverAssetId: nil,
            entryIds: [],
            sortOrder: (collections.map { $0.sortOrder }.max() ?? -1) + 1,
            createdAt: now,
            updatedAt: now
        )
        collections.append(newCollection)
        PersistenceStore.save(collections, to: collectionsFile)
        return newCollection
    }

    func updateCollection(_ collection: EntryCollection) {
        guard let index = collections.firstIndex(where: { $0.id == collection.id }) else { return }
        var updated = collection
        updated.updatedAt = Date()
        collections[index] = updated
        PersistenceStore.save(collections, to: collectionsFile)
    }

    func deleteCollection(_ collection: EntryCollection) {
        collections.removeAll { $0.id == collection.id }
        PersistenceStore.save(collections, to: collectionsFile)
    }

    func entries(in collection: EntryCollection) -> [Entry] {
        collection.entryIds.compactMap { entryId in
            activeEntries.first { $0.id == entryId }
        }
    }

    func isEntry(_ entry: Entry, in collection: EntryCollection) -> Bool {
        collection.entryIds.contains(entry.id)
    }

    func toggleEntry(_ entry: Entry, in collection: EntryCollection) {
        var updated = collection
        if let index = updated.entryIds.firstIndex(of: entry.id) {
            updated.entryIds.remove(at: index)
        } else {
            updated.entryIds.append(entry.id)
        }
        updateCollection(updated)
    }

    // MARK: - Smart collections

    var wishlistEntries: [Entry] {
        entriesByDateDescending().filter { $0.isWishlist }
    }

    var fiveStarEntries: [Entry] {
        entriesByDateDescending().filter { $0.rating == 5 }
    }

    var recentEntries: [Entry] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        return entriesByDateDescending().filter { $0.date >= cutoff }
    }

    /// 인용구/문장이 저장된 기록 (docs/12 E).
    var quoteEntries: [Entry] {
        entriesByDateDescending().filter { $0.quoteText != nil }
    }

    /// 백업에서 복원: 기록 관련 데이터를 백업 내용으로 교체한다 (docs/13 P1).
    func restore(
        entries newEntries: [Entry],
        mediaAssets newAssets: [MediaAsset],
        recordCards newCards: [RecordCard],
        collections newCollections: [EntryCollection]
    ) -> Bool {
        guard PersistenceStore.save(newEntries, to: entriesFile) else { return false }
        PersistenceStore.save(newAssets, to: assetsFile)
        PersistenceStore.save(newCards, to: cardsFile)
        PersistenceStore.save(newCollections, to: collectionsFile)
        entries = newEntries
        mediaAssets = newAssets
        recordCards = newCards
        collections = newCollections
        return true
    }

    // MARK: - Debug helpers

    func resetAllData() {
        entries = []
        mediaAssets = []
        recordCards = []
        collections = []
        PersistenceStore.delete(entriesFile)
        PersistenceStore.delete(assetsFile)
        PersistenceStore.delete(cardsFile)
        PersistenceStore.delete(collectionsFile)
    }
}
