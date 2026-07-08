import Foundation
import Combine

/// 소셜 데이터 저장소. 서버가 없는 단계라 로컬 mock으로 동작하며,
/// 서버가 생기면 이 클래스 내부 구현만 교체한다 (docs/10 7장 원칙).
/// - 친구 관계/차단/신고는 로컬에 영구 저장된다.
/// - 공개 사용자/공개 기록은 Debug에서 mock 데이터를 노출한다.
final class SocialRepository: ObservableObject {
    @Published private(set) var publicProfiles: [UserPublicProfile] = []
    @Published private(set) var mockPublicEntries: [SocialEntry] = []
    @Published private(set) var friendships: [Friendship] = []
    @Published private(set) var blockedUserIds: Set<String> = []

    let myUserId: String

    private let friendshipsFile = "socialFriendships"
    private let blocksFile = "socialBlocks"
    private let reportsFile = "socialReports"

    init(myUserId: String = "local-user") {
        self.myUserId = myUserId
        friendships = PersistenceStore.load([Friendship].self, from: friendshipsFile) ?? []
        blockedUserIds = Set(PersistenceStore.load([String].self, from: blocksFile) ?? [])
        if FeatureFlags.enableSampleData {
            seedMockSocialData()
        }
    }

    // MARK: - Feed

    /// 전체 탭: public 기록. 차단 관계 제외 (docs/10 8장).
    func publicFeed(myEntries: [Entry], categories: [EntryCategory]) -> [SocialEntry] {
        let mine = myEntries
            .filter { ($0.visibility ?? .privateOnly) == .publicAll }
            .map { snapshot(of: $0, categories: categories) }
        let others = mockPublicEntries.filter { !blockedUserIds.contains($0.authorId) }
        return (mine + others).sorted { $0.date > $1.date }
    }

    /// 친구들 탭: 친구의 friends/public 기록.
    func friendFeed() -> [SocialEntry] {
        let friendIds = Set(friends().map { $0.userId })
        return mockPublicEntries
            .filter { friendIds.contains($0.authorId) && !blockedUserIds.contains($0.authorId) }
            .sorted { $0.date > $1.date }
    }

    func visiblePublicProfiles() -> [UserPublicProfile] {
        publicProfiles.filter { $0.publicProfileEnabled && !blockedUserIds.contains($0.userId) }
    }

    func profile(userId: String) -> UserPublicProfile? {
        publicProfiles.first { $0.userId == userId }
    }

    private func snapshot(of entry: Entry, categories: [EntryCategory]) -> SocialEntry {
        let category = categories.first { $0.id == entry.categoryId }
        return SocialEntry(
            id: entry.id,
            authorId: myUserId,
            date: entry.date,
            categoryName: category?.name ?? entry.archivedCategoryName ?? "기록",
            categoryColorHex: category?.colorHex ?? CategoryMainType.custom.defaultColorHex,
            title: entry.title,
            bodyPreview: String(entry.body.prefix(80)),
            rating: entry.rating,
            isWishlist: entry.isWishlist,
            visibility: entry.visibility ?? .privateOnly
        )
    }

    // MARK: - Friends

    func friends() -> [UserPublicProfile] {
        let acceptedIds = friendships
            .filter { $0.status == .accepted }
            .map { $0.requesterId == myUserId ? $0.addresseeId : $0.requesterId }
        return acceptedIds.compactMap { profile(userId: $0) }
            .filter { !blockedUserIds.contains($0.userId) }
    }

    func relation(with userId: String) -> FriendRelation {
        if blockedUserIds.contains(userId) { return .blocked }
        guard let friendship = activeFriendship(with: userId) else { return .notFriends }
        switch friendship.status {
        case .accepted: return .friends
        case .pending:
            return friendship.requesterId == myUserId ? .requestSent : .requestReceived
        default: return .notFriends
        }
    }

    private func activeFriendship(with userId: String) -> Friendship? {
        friendships.first {
            ($0.status == .pending || $0.status == .accepted)
                && (($0.requesterId == myUserId && $0.addresseeId == userId)
                    || ($0.requesterId == userId && $0.addresseeId == myUserId))
        }
    }

    var receivedRequests: [Friendship] {
        friendships.filter { $0.status == .pending && $0.addresseeId == myUserId }
    }

    var sentRequests: [Friendship] {
        friendships.filter { $0.status == .pending && $0.requesterId == myUserId }
    }

    func sendRequest(to userId: String) {
        guard relation(with: userId) == .notFriends else { return }
        let now = Date()
        friendships.append(Friendship(
            id: UUID().uuidString,
            requesterId: myUserId,
            addresseeId: userId,
            status: .pending,
            requestedAt: now,
            respondedAt: nil,
            updatedAt: now
        ))
        persistFriendships()
    }

    func accept(_ friendship: Friendship) {
        update(friendship, to: .accepted)
    }

    func decline(_ friendship: Friendship) {
        update(friendship, to: .declined)
    }

    func cancelRequest(_ friendship: Friendship) {
        update(friendship, to: .canceled)
    }

    func removeFriend(userId: String) {
        if let friendship = activeFriendship(with: userId) {
            update(friendship, to: .removed)
        }
    }

    private func update(_ friendship: Friendship, to status: FriendshipStatus) {
        guard let index = friendships.firstIndex(where: { $0.id == friendship.id }) else { return }
        friendships[index].status = status
        friendships[index].respondedAt = Date()
        friendships[index].updatedAt = Date()
        persistFriendships()
    }

    private func persistFriendships() {
        PersistenceStore.save(friendships, to: friendshipsFile)
    }

    // MARK: - Search / Invite

    func searchUsers(query: String) -> [UserPublicProfile] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return [] }
        return visiblePublicProfiles().filter {
            $0.nickname.localizedCaseInsensitiveContains(trimmed)
                || $0.spaceName.localizedCaseInsensitiveContains(trimmed)
        }
    }

    /// 초대 링크 공유 문구 (docs/10 10장).
    func inviteMessage(inviterNickname: String, spaceName: String) -> String {
        """
        Write & Record에서 나랑 기록을 공유해볼래?
        '\(spaceName)'으로 초대할게. - \(inviterNickname)
        """
    }

    // MARK: - Moderation

    func block(userId: String) {
        blockedUserIds.insert(userId)
        PersistenceStore.save(Array(blockedUserIds), to: blocksFile)
        // 차단은 friendship보다 우선한다.
        if let friendship = activeFriendship(with: userId) {
            update(friendship, to: .blocked)
        }
    }

    func unblock(userId: String) {
        blockedUserIds.remove(userId)
        PersistenceStore.save(Array(blockedUserIds), to: blocksFile)
    }

    func report(targetType: String, targetId: String, reason: String) {
        var reports = PersistenceStore.load([SocialReport].self, from: reportsFile) ?? []
        reports.append(SocialReport(
            id: UUID().uuidString,
            reporterId: myUserId,
            targetType: targetType,
            targetId: targetId,
            reason: reason,
            createdAt: Date()
        ))
        PersistenceStore.save(reports, to: reportsFile)
    }

    // MARK: - Mock seed (Debug)

    private func seedMockSocialData() {
        let now = Date()
        let calendar = Calendar.current
        let mockUsers: [(id: String, nickname: String, space: String, bio: String, count: Int)] = [
            ("mock-friend-1", "소윤", "소윤의 취향 노트", "영화와 카페를 좋아해요", 12),
            ("mock-friend-2", "지호", "지호의 러닝 로그", "주 3회 러닝 기록 중", 8),
            ("mock-friend-3", "하람", "하람책방", "한 달에 네 권 읽기", 21)
        ]
        publicProfiles = mockUsers.map { user in
            UserPublicProfile(
                id: "profile-\(user.id)",
                userId: user.id,
                nickname: user.nickname,
                avatarAssetId: nil,
                spaceName: user.space,
                bio: user.bio,
                themeId: ProfileTheme.defaultThemes[0].id,
                publicProfileEnabled: true,
                recordCountPublic: user.count,
                createdAt: now,
                updatedAt: now
            )
        }
        let mockEntries: [(author: String, daysAgo: Int, category: String, hex: String, title: String, body: String, rating: Int?)] = [
            ("mock-friend-1", 0, "영화", "#A9B4C8", "듄 파트2 재관람", "화면이 큰 곳에서 다시 봐도 좋았다.", 5),
            ("mock-friend-1", 2, "카페", "#D9BE7A", "골목 안 새 카페", "라떼가 진하고 자리가 조용함.", 4),
            ("mock-friend-2", 1, "러닝", "#9DB79B", "아침 5km", "페이스 6:10. 날씨 최고.", nil),
            ("mock-friend-3", 1, "책", "#C5BA9A", "미움받을 용기 다시 읽기", "밑줄 친 문장이 달라졌다.", 4),
            ("mock-friend-3", 3, "책", "#C5BA9A", "이번 달 책 정리", "네 권 완독. 다음 달은 소설 위주로.", nil)
        ]
        mockPublicEntries = mockEntries.map { entry in
            SocialEntry(
                id: UUID().uuidString,
                authorId: entry.author,
                date: calendar.date(byAdding: .day, value: -entry.daysAgo, to: now) ?? now,
                categoryName: entry.category,
                categoryColorHex: entry.hex,
                title: entry.title,
                bodyPreview: entry.body,
                rating: entry.rating,
                isWishlist: false,
                visibility: .publicAll
            )
        }
    }
}
