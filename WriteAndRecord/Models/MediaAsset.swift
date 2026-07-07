import Foundation

enum MediaAssetType: String, Codable {
    case photo
    case video
}

struct MediaAsset: Codable, Identifiable, Equatable, Hashable {
    var id: String
    var localIdentifier: String?
    var type: MediaAssetType
    var dateTaken: Date?
    var width: Int
    var height: Int
    var thumbnailPath: String?
    var localPath: String?
    var remoteUrl: String?
    var createdAt: Date
}
