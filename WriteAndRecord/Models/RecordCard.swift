import Foundation

struct RecordCard: Codable, Identifiable, Equatable {
    var id: String
    var entryId: String
    var templateId: String
    var imagePath: String?
    var createdAt: Date
}

enum RecordCardTemplate: String, CaseIterable, Identifiable {
    case minimalPhoto
    case blogSnippet
    case ratingReview
    case wishlist
    case placeMemory
    case textDiary

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .minimalPhoto: return "Minimal Photo"
        case .blogSnippet: return "Blog Snippet"
        case .ratingReview: return "Rating Review"
        case .wishlist: return "Wishlist"
        case .placeMemory: return "Place Memory"
        case .textDiary: return "Text Diary"
        }
    }

    var iconName: String {
        switch self {
        case .minimalPhoto: return "photo"
        case .blogSnippet: return "text.alignleft"
        case .ratingReview: return "star"
        case .wishlist: return "bookmark"
        case .placeMemory: return "mappin.and.ellipse"
        case .textDiary: return "book.closed"
        }
    }
}
