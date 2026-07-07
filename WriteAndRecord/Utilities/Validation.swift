import Foundation

enum Validation {
    static func isValidNickname(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count >= 1 && trimmed.count <= 20
    }

    static func isValidSpaceName(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count >= 1 && trimmed.count <= 30
    }

    static func isValidEntryTitle(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.count >= 1 && trimmed.count <= 80
    }

    static func isValidBody(_ text: String) -> Bool {
        text.count <= 10_000
    }

    static func isValidRating(_ rating: Int?) -> Bool {
        guard let rating else { return true }
        return (1...5).contains(rating)
    }

    static func isValidCount(_ count: Int?) -> Bool {
        guard let count else { return true }
        return count >= 1
    }

    static func isValidURL(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty,
              let url = URL(string: trimmed),
              let scheme = url.scheme?.lowercased() else { return false }
        return (scheme == "http" || scheme == "https") && url.host != nil
    }

    static func isValidListItem(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespaces)
        return !trimmed.isEmpty && trimmed.count <= 120
    }
}
