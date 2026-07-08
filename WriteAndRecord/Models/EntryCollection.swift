import Foundation

struct EntryCollection: Codable, Identifiable, Equatable {
    var id: String
    var name: String
    var description: String?
    var coverAssetId: String?
    var entryIds: [String]
    var sortOrder: Int
    var createdAt: Date
    var updatedAt: Date
}
