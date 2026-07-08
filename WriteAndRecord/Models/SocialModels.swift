import Foundation

/// 기록 공개 범위 (docs/10 4장). 기본값은 항상 private.
enum EntryVisibility: String, Codable, CaseIterable, Identifiable {
    case privateOnly = "private"
    case friends
    case publicAll = "public"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .privateOnly: return "나만 보기"
        case .friends: return "친구에게 공개"
        case .publicAll: return "전체 공개"
        }
    }

    var explanation: String {
        switch self {
        case .privateOnly: return "내 공간에만 저장돼요."
        case .friends: return "친구들이 소셜에서 볼 수 있어요."
        case .publicAll: return "공개된 모든 사용자가 볼 수 있어요."
        }
    }

    var iconName: String {
        switch self {
        case .privateOnly: return "lock"
        case .friends: return "person.2"
        case .publicAll: return "globe"
        }
    }
}

/// 소셜에 노출되는 공개 프로필 (docs/10 6장).
struct UserPublicProfile: Codable, Identifiable, Equatable {
    var id: String
    var userId: String
    var nickname: String
    var avatarAssetId: String?
    var spaceName: String
    var bio: String?
    var themeId: String
    var publicProfileEnabled: Bool
    var recordCountPublic: Int
    var createdAt: Date
    var updatedAt: Date
}

enum FriendshipStatus: String, Codable {
    case pending
    case accepted
    case declined
    case canceled
    case removed
    case blocked
}

struct Friendship: Codable, Identifiable, Equatable {
    var id: String
    var requesterId: String
    var addresseeId: String
    var status: FriendshipStatus
    var requestedAt: Date
    var respondedAt: Date?
    var updatedAt: Date
}

/// 나와 특정 사용자의 관계 상태 (docs/10 9장).
enum FriendRelation {
    case notFriends
    case requestSent
    case requestReceived
    case friends
    case blocked

    var buttonTitle: String {
        switch self {
        case .notFriends: return "친구 추가"
        case .requestSent: return "요청됨"
        case .requestReceived: return "수락"
        case .friends: return "친구"
        case .blocked: return "차단됨"
        }
    }
}

/// 소셜 피드에 표시되는 기록 스냅샷.
/// 개인 Entry 전체 모델을 노출하지 않고 공개 가능한 필드만 담는다.
struct SocialEntry: Codable, Identifiable, Equatable {
    var id: String
    var authorId: String
    var date: Date
    var categoryName: String
    var categoryColorHex: String
    var title: String
    var bodyPreview: String
    var rating: Int?
    var isWishlist: Bool
    var visibility: EntryVisibility
}

struct SocialReport: Codable, Identifiable {
    var id: String
    var reporterId: String
    var targetType: String // user/entry
    var targetId: String
    var reason: String
    var createdAt: Date
}
