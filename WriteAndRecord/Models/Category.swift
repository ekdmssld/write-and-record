import Foundation

enum CategoryMainType: String, Codable, CaseIterable {
    case daily
    case food
    case fandom
    case exercise
    case movieTv
    case book
    case music
    case place
    case custom

    var displayName: String {
        switch self {
        case .daily: return "일상"
        case .food: return "음식/메뉴"
        case .fandom: return "덕질"
        case .exercise: return "운동"
        case .movieTv: return "영화/TV"
        case .book: return "책"
        case .music: return "음악"
        case .place: return "장소"
        case .custom: return "커스텀"
        }
    }

    /// 세이지·린넨 팔레트 기반 카테고리 색.
    var defaultColorHex: String {
        switch self {
        case .daily: return "#F7D8CC"    // soft peach milk
        case .food: return "#EFD7CF"     // peach protein
        case .fandom: return "#DDBAAE"   // blush beet, muted
        case .exercise: return "#818263" // savory sage
        case .movieTv: return "#A4AAAA"  // metallic silver
        case .book: return "#DCD4C1"     // oat latte
        case .music: return "#C2C395"    // avocado smooth
        case .place: return "#CCC2C1"    // pale silver
        case .custom: return "#EADFD6"   // blanched almond
        }
    }

    var defaultIcon: String {
        switch self {
        case .daily: return "sun.max"
        case .food: return "fork.knife"
        case .fandom: return "sparkles"
        case .exercise: return "figure.run"
        case .movieTv: return "film"
        case .book: return "book"
        case .music: return "music.note"
        case .place: return "mappin.and.ellipse"
        case .custom: return "tag"
        }
    }
}

struct EntryCategory: Codable, Identifiable, Equatable, Hashable {
    var id: String
    var name: String
    var mainType: CategoryMainType
    var parentId: String?
    var icon: String
    var colorHex: String
    var isDefault: Bool
    var isArchived: Bool
    var templateId: String?
    var createdAt: Date
    var updatedAt: Date

    var isMain: Bool { parentId == nil }
}

enum CategorySeed {
    static let subcategoryNames: [CategoryMainType: [String]] = [
        .daily: ["하루 기록", "감정", "일기", "쇼핑", "공부", "업무", "기념일", "여행", "취미"],
        .food: ["맛집", "카페", "배달", "집밥", "디저트", "술", "레시피", "재방문"],
        .fandom: ["아이돌", "배우", "애니", "게임", "굿즈", "공연", "팬미팅", "콘텐츠"],
        .exercise: ["헬스", "러닝", "요가", "필라테스", "수영", "등산", "홈트", "기록 측정"],
        .movieTv: ["영화", "드라마", "예능", "다큐", "애니", "시리즈 정주행"],
        .book: ["소설", "에세이", "자기계발", "만화", "시집", "논픽션", "인용문"],
        .music: ["곡", "앨범", "플레이리스트", "공연", "아티스트", "노래방"],
        .place: ["여행지", "동네", "전시", "숙소", "산책", "매장", "포토스팟"]
    ]

    static func defaultCategories() -> [EntryCategory] {
        let now = Date()
        var result: [EntryCategory] = []
        for mainType in CategoryMainType.allCases where mainType != .custom {
            let mainId = "default-\(mainType.rawValue)"
            result.append(EntryCategory(
                id: mainId,
                name: mainType.displayName,
                mainType: mainType,
                parentId: nil,
                icon: mainType.defaultIcon,
                colorHex: mainType.defaultColorHex,
                isDefault: true,
                isArchived: false,
                templateId: nil,
                createdAt: now,
                updatedAt: now
            ))
            for (index, subName) in (subcategoryNames[mainType] ?? []).enumerated() {
                result.append(EntryCategory(
                    id: "default-\(mainType.rawValue)-sub\(index)",
                    name: subName,
                    mainType: mainType,
                    parentId: mainId,
                    icon: mainType.defaultIcon,
                    colorHex: mainType.defaultColorHex,
                    isDefault: true,
                    isArchived: false,
                    templateId: nil,
                    createdAt: now,
                    updatedAt: now
                ))
            }
        }
        return result
    }
}
