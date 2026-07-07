import Foundation

struct PlaceRef: Codable, Equatable, Hashable {
    var name: String
    var address: String?
    var latitude: Double?
    var longitude: Double?
    var externalId: String?
}

struct LinkRef: Codable, Equatable, Hashable, Identifiable {
    var id: String = UUID().uuidString
    var title: String?
    var url: String
}

struct Entry: Codable, Identifiable, Equatable {
    var id: String
    var userId: String
    var date: Date
    var categoryId: String
    var archivedCategoryName: String?
    var title: String
    var body: String
    var rating: Int?
    var isWishlist: Bool
    var coverAssetId: String?
    var assetIds: [String]
    var pros: [String]
    var cons: [String]
    var tips: [String]
    var count: Int?
    var place: PlaceRef?
    var links: [LinkRef]
    var metadata: [String: String]
    var collectionIds: [String]
    var createdAt: Date
    var updatedAt: Date
    var deletedAt: Date?

    var isDeleted: Bool { deletedAt != nil }

    static func new(userId: String, date: Date, categoryId: String) -> Entry {
        let now = Date()
        return Entry(
            id: UUID().uuidString,
            userId: userId,
            date: date,
            categoryId: categoryId,
            archivedCategoryName: nil,
            title: "",
            body: "",
            rating: nil,
            isWishlist: false,
            coverAssetId: nil,
            assetIds: [],
            pros: [],
            cons: [],
            tips: [],
            count: nil,
            place: nil,
            links: [],
            metadata: [:],
            collectionIds: [],
            createdAt: now,
            updatedAt: now,
            deletedAt: nil
        )
    }
}

/// 카테고리별 metadata 입력 필드 정의 (Product Spec 7장)
struct MetadataField: Identifiable {
    var id: String { key }
    let key: String
    let label: String
    let keyboardNumeric: Bool

    init(_ key: String, _ label: String, numeric: Bool = false) {
        self.key = key
        self.label = label
        self.keyboardNumeric = numeric
    }

    static func fields(for mainType: CategoryMainType) -> [MetadataField] {
        switch mainType {
        case .food:
            return [
                MetadataField("menuName", "메뉴 이름"),
                MetadataField("price", "가격", numeric: true),
                MetadataField("restaurantName", "가게 이름"),
                MetadataField("visitType", "방문 형태 (매장/포장/배달)"),
                MetadataField("repurchaseIntent", "재구매 의사"),
                MetadataField("spiceLevel", "맵기")
            ]
        case .exercise:
            return [
                MetadataField("workoutType", "운동 종류"),
                MetadataField("durationMin", "운동 시간(분)", numeric: true),
                MetadataField("distanceKm", "거리(km)", numeric: true),
                MetadataField("weightKg", "무게(kg)", numeric: true),
                MetadataField("reps", "횟수(reps)", numeric: true),
                MetadataField("sets", "세트 수", numeric: true),
                MetadataField("calories", "칼로리", numeric: true)
            ]
        case .movieTv:
            return [
                MetadataField("originalTitle", "원제"),
                MetadataField("platform", "플랫폼"),
                MetadataField("watchedStatus", "시청 상태"),
                MetadataField("watchedEpisode", "본 에피소드"),
                MetadataField("director", "감독"),
                MetadataField("cast", "출연")
            ]
        case .book:
            return [
                MetadataField("author", "저자"),
                MetadataField("publisher", "출판사"),
                MetadataField("pagesRead", "읽은 페이지", numeric: true),
                MetadataField("totalPages", "전체 페이지", numeric: true),
                MetadataField("quote", "인용문"),
                MetadataField("readingStatus", "독서 상태")
            ]
        case .music:
            return [
                MetadataField("artist", "아티스트"),
                MetadataField("album", "앨범"),
                MetadataField("track", "곡"),
                MetadataField("mood", "무드"),
                MetadataField("listenedOn", "들은 플랫폼"),
                MetadataField("favoriteLyricShort", "좋았던 가사")
            ]
        case .place:
            return [
                MetadataField("visitPurpose", "방문 목적"),
                MetadataField("weather", "날씨"),
                MetadataField("crowdLevel", "혼잡도"),
                MetadataField("transportation", "이동 수단"),
                MetadataField("revisitIntent", "재방문 의사")
            ]
        case .fandom:
            return [
                MetadataField("fandomTarget", "덕질 대상"),
                MetadataField("eventName", "이벤트 이름"),
                MetadataField("contentType", "콘텐츠 종류"),
                MetadataField("merch", "굿즈"),
                MetadataField("episode", "에피소드")
            ]
        case .daily, .custom:
            return []
        }
    }
}
