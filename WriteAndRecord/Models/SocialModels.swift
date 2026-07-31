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

/// 내 프로필의 공개 범위 (docs/10 4장). 기본값은 항상 private.
enum ProfileVisibility: String, Codable, CaseIterable, Identifiable {
    case privateOnly = "private"
    case friendsOnly
    case publicAll = "public"

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .privateOnly: return "나만 보기"
        case .friendsOnly: return "친구에게만 공개"
        case .publicAll: return "전체 공개"
        }
    }

    var explanation: String {
        switch self {
        case .privateOnly: return "검색이나 전체 탭에 표시되지 않아요."
        case .friendsOnly: return "친구에게만 프로필이 보여요."
        case .publicAll: return "전체 탭에서 누구나 프로필을 볼 수 있어요."
        }
    }

    var iconName: String {
        switch self {
        case .privateOnly: return "lock"
        case .friendsOnly: return "person.2"
        case .publicAll: return "globe"
        }
    }
}

/// 소셜에 노출되는 공개 프로필 (docs/10 6장).
struct UserPublicProfile: Codable, Identifiable, Equatable, Hashable {
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
struct SocialEntry: Codable, Identifiable, Equatable, Hashable {
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
    var coverAsset: MediaAsset?
}

/// 초대 링크 (docs/10 SocialInvite).
struct SocialInvite: Codable, Identifiable, Equatable {
    var id: String
    var inviterId: String
    var inviteCode: String
    var inviteUrl: String
    var status: String // active/used/expired/revoked
    var usedCount: Int
    var createdAt: Date
}

struct SocialReport: Codable, Identifiable {
    var id: String
    var reporterId: String
    var targetType: String // user/entry
    var targetId: String
    var reason: String
    var createdAt: Date
}

enum SocialReactionType: String, Codable {
    case like
}

/// 기록에 대한 좋아요. entryId당 사용자 1명당 1개만 존재한다.
struct SocialReaction: Codable, Identifiable, Equatable {
    var id: String
    var entryId: String
    var userId: String
    var type: SocialReactionType
    var createdAt: Date
}

/// 소셜 기록에 대한 댓글. 소프트 삭제(`deletedAt`)로 본인 댓글만 지울 수 있다.
struct SocialComment: Codable, Identifiable, Equatable {
    var id: String
    var entryId: String
    var authorId: String
    var text: String
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?

    var isDeleted: Bool { deletedAt != nil }
}
