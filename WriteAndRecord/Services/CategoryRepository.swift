import Foundation
import Combine

final class CategoryRepository: ObservableObject {
    @Published private(set) var categories: [EntryCategory] = []

    private let categoriesFile = "categories"

    init() {
        load()
    }

    func load() {
        if let stored = PersistenceStore.load([EntryCategory].self, from: categoriesFile), !stored.isEmpty {
            categories = stored
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

    /// 커스텀 카테고리 삭제(archive). 기존 Entry는 archivedCategoryName을 유지하도록 호출측에서 처리.
    func archive(_ category: EntryCategory) throws {
        guard !category.isDefault else { throw CategoryError.cannotDeleteDefault }
        var archived = category
        archived.isArchived = true
        update(archived)
    }

    func resetToDefaults() {
        categories = CategorySeed.defaultCategories()
        PersistenceStore.save(categories, to: categoriesFile)
    }
}
