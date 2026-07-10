import Foundation
import Combine

final class CategoryRepository: ObservableObject {
    @Published private(set) var categories: [EntryCategory] = []

    private let categoriesFile = "categories"

    init() {
        load()
    }

    func load() {
        if var stored = PersistenceStore.load([EntryCategory].self, from: categoriesFile), !stored.isEmpty {
            // 기본 카테고리는 사용자가 색을 고르지 않으므로,
            // 디자인 팔레트가 바뀌면 저장된 색/아이콘을 최신 기본값으로 동기화한다.
            var changed = false
            for index in stored.indices where stored[index].isDefault {
                let mainType = stored[index].mainType
                if stored[index].colorHex != mainType.defaultColorHex {
                    stored[index].colorHex = mainType.defaultColorHex
                    changed = true
                }
                if stored[index].icon != mainType.defaultIcon {
                    stored[index].icon = mainType.defaultIcon
                    changed = true
                }
            }
            categories = stored
            if changed {
                PersistenceStore.save(categories, to: categoriesFile)
            }
        } else {
            // 앱 첫 실행: 기본 카테고리 seed
            categories = CategorySeed.defaultCategories()
            PersistenceStore.save(categories, to: categoriesFile)
        }
    }

    var activeCategories: [EntryCategory] {
        categories.filter { !$0.isArchived }
    }

    var mainCategories: [EntryCategory] {
        activeCategories.filter { $0.isMain }
    }

    func subcategories(of parent: EntryCategory) -> [EntryCategory] {
        activeCategories.filter { $0.parentId == parent.id }
    }

    func category(id: String) -> EntryCategory? {
        categories.first { $0.id == id }
    }

    func displayName(forEntry entry: Entry) -> String {
        category(id: entry.categoryId)?.name ?? entry.archivedCategoryName ?? "삭제된 카테고리"
    }

    func colorHex(forEntry entry: Entry) -> String {
        category(id: entry.categoryId)?.colorHex ?? CategoryMainType.custom.defaultColorHex
    }

    enum CategoryError: Error, LocalizedError {
        case duplicateName
        case cannotDeleteDefault

        var errorDescription: String? {
            switch self {
            case .duplicateName: return "같은 그룹에 이미 같은 이름의 카테고리가 있어요."
            case .cannotDeleteDefault: return "기본 카테고리는 삭제할 수 없어요. 대신 숨길 수 있어요."
            }
        }
    }

    func addCustomCategory(name: String, icon: String, colorHex: String, parentId: String?) throws -> EntryCategory {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        let siblings = categories.filter { $0.parentId == parentId && !$0.isArchived }
        guard !siblings.contains(where: { $0.name == trimmed }) else {
            throw CategoryError.duplicateName
        }
        let now = Date()
        let parentMainType = parentId.flatMap { category(id: $0)?.mainType } ?? .custom
        let newCategory = EntryCategory(
            id: UUID().uuidString,
            name: trimmed,
            mainType: parentMainType,
            parentId: parentId,
            icon: icon,
            colorHex: colorHex,
            isDefault: false,
            isArchived: false,
            templateId: nil,
            createdAt: now,
            updatedAt: now
        )
        categories.append(newCategory)
        PersistenceStore.save(categories, to: categoriesFile)
        return newCategory
    }

    func update(_ category: EntryCategory) {
        guard let index = categories.firstIndex(where: { $0.id == category.id }) else { return }
        var updated = category
        updated.updatedAt = Date()
        categories[index] = updated
        PersistenceStore.save(categories, to: categoriesFile)
    }

    func moveCategories(parentId: String?, fromOffsets: IndexSet, toOffset: Int) {
        var siblings = categories.filter { !$0.isArchived && $0.parentId == parentId }
        moveItems(in: &siblings, fromOffsets: fromOffsets, toOffset: toOffset)

        var reordered = categories
        var movedIterator = siblings.makeIterator()
        for index in reordered.indices where !reordered[index].isArchived && reordered[index].parentId == parentId {
            if let nextCategory = movedIterator.next() {
                reordered[index] = nextCategory
            }
        }

        categories = reordered
        PersistenceStore.save(categories, to: categoriesFile)
    }

    private func moveItems(in categories: inout [EntryCategory], fromOffsets: IndexSet, toOffset: Int) {
        let movedCategories = fromOffsets.sorted().map { categories[$0] }
        for offset in fromOffsets.sorted(by: >) {
            categories.remove(at: offset)
        }
        let adjustedDestination = toOffset - fromOffsets.filter { $0 < toOffset }.count
        categories.insert(contentsOf: movedCategories, at: adjustedDestination)
    }

    /// 커스텀 카테고리 삭제(archive). 기존 Entry는 archivedCategoryName을 유지하도록 호출측에서 처리.
    func archive(_ category: EntryCategory) throws {
        guard !category.isDefault else { throw CategoryError.cannotDeleteDefault }
        var archived = category
        archived.isArchived = true
        update(archived)
    }

    /// 숨긴(archived) 카테고리 목록.
    var archivedCategories: [EntryCategory] {
        categories.filter { $0.isArchived }
    }

    /// 기본 카테고리는 삭제 대신 숨김/복원 (Functional Spec 7장).
    func setArchived(_ category: EntryCategory, archived: Bool) {
        var updated = category
        updated.isArchived = archived
        update(updated)
    }

    func resetToDefaults() {
        categories = CategorySeed.defaultCategories()
        PersistenceStore.save(categories, to: categoriesFile)
    }

    /// 백업에서 복원. 백업에 카테고리가 없으면 기본값으로 되돌린다.
    func restore(categories newCategories: [EntryCategory]) {
        categories = newCategories.isEmpty ? CategorySeed.defaultCategories() : newCategories
        PersistenceStore.save(categories, to: categoriesFile)
    }
}
