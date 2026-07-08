import Foundation

/// 앱 안 정보 검색 (docs/12 A). 영화/책/음악을 검색해 기록 필드를 채운다.
/// API 키가 필요 없는 iTunes Search API를 사용한다.
/// 검색 실패나 결과 없음에도 수동 입력은 항상 가능하다.
enum ExternalSearchKind: String, CaseIterable {
    case movie
    case book
    case music

    var mediaParameter: String {
        switch self {
        case .movie: return "movie"
        case .book: return "ebook"
        case .music: return "music"
        }
    }

    var displayName: String {
        switch self {
        case .movie: return "영화/TV"
        case .book: return "책"
        case .music: return "음악"
        }
    }

    static func from(mainType: CategoryMainType) -> ExternalSearchKind? {
        switch mainType {
        case .movieTv: return .movie
        case .book: return .book
        case .music: return .music
        default: return nil
        }
    }
}

struct ExternalSearchResult: Identifiable, Equatable {
    let id: String
    let title: String
    let creator: String     // 감독/저자/아티스트
    let collection: String? // 앨범 등
    let artworkUrl: URL?
    let kind: ExternalSearchKind
}

enum ExternalSearchService {
    struct ITunesResponse: Decodable {
        let results: [ITunesItem]
    }

    struct ITunesItem: Decodable {
        let trackId: Int?
        let collectionId: Int?
        let trackName: String?
        let collectionName: String?
        let artistName: String?
        let artworkUrl100: String?
    }

    static func search(_ query: String, kind: ExternalSearchKind) async throws -> [ExternalSearchResult] {
        let trimmed = query.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return [] }

        var components = URLComponents(string: "https://itunes.apple.com/search")!
        components.queryItems = [
            URLQueryItem(name: "term", value: trimmed),
            URLQueryItem(name: "media", value: kind.mediaParameter),
            URLQueryItem(name: "country", value: "KR"),
            URLQueryItem(name: "limit", value: "20")
        ]
        guard let url = components.url else { return [] }

        let (data, _) = try await URLSession.shared.data(from: url)
        let response = try JSONDecoder().decode(ITunesResponse.self, from: data)

        return response.results.compactMap { item in
            guard let title = item.trackName ?? item.collectionName else { return nil }
            let identifier = item.trackId ?? item.collectionId ?? title.hashValue
            return ExternalSearchResult(
                id: "\(kind.rawValue)-\(identifier)",
                title: title,
                creator: item.artistName ?? "",
                collection: item.collectionName,
                artworkUrl: item.artworkUrl100.flatMap { URL(string: $0) },
                kind: kind
            )
        }
    }
}
