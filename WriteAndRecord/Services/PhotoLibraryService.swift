import Foundation
import Photos
import UIKit

enum PhotoPermission {
    case notDetermined
    case authorized
    case limited
    case denied

    static func from(_ status: PHAuthorizationStatus) -> PhotoPermission {
        switch status {
        case .authorized: return .authorized
        case .limited: return .limited
        case .notDetermined: return .notDetermined
        default: return .denied
        }
    }
}

/// Photos framework 접근을 한 곳에 격리한다.
final class PhotoLibraryService: ObservableObject {
    @Published var permission: PhotoPermission

    private let imageManager = PHCachingImageManager()

    init() {
        permission = PhotoPermission.from(PHPhotoLibrary.authorizationStatus(for: .readWrite))
    }

    func refreshPermission() {
        permission = PhotoPermission.from(PHPhotoLibrary.authorizationStatus(for: .readWrite))
    }

    func requestPermission() async {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        await MainActor.run {
            self.permission = PhotoPermission.from(status)
        }
    }

    /// 선택한 날짜(로컬 타임존 00:00~23:59)의 사진.
    func fetchAssets(on date: Date?) -> [PHAsset] {
        let options = PHFetchOptions()
        options.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
        if let date {
            let calendar = Calendar.current
            let start = calendar.startOfDay(for: date)
            let end = calendar.date(byAdding: .day, value: 1, to: start) ?? start
            options.predicate = NSPredicate(
                format: "creationDate >= %@ AND creationDate < %@",
                start as NSDate, end as NSDate
            )
        }
        let result = PHAsset.fetchAssets(with: .image, options: options)
        var assets: [PHAsset] = []
        assets.reserveCapacity(result.count)
        result.enumerateObjects { asset, _, _ in
            assets.append(asset)
        }
        return assets
    }

    func fetchAsset(localIdentifier: String) -> PHAsset? {
        PHAsset.fetchAssets(withLocalIdentifiers: [localIdentifier], options: nil).firstObject
    }

    func requestThumbnail(for asset: PHAsset, size: CGSize, completion: @escaping (UIImage?) -> Void) {
        let options = PHImageRequestOptions()
        options.deliveryMode = .opportunistic
        options.isNetworkAccessAllowed = true // iCloud 사진 대응
        options.resizeMode = .fast
        imageManager.requestImage(
            for: asset,
            targetSize: size,
            contentMode: .aspectFill,
            options: options
        ) { image, _ in
            completion(image)
        }
    }

    func requestFullImage(for asset: PHAsset, completion: @escaping (UIImage?) -> Void) {
        let options = PHImageRequestOptions()
        options.deliveryMode = .highQualityFormat
        options.isNetworkAccessAllowed = true
        imageManager.requestImage(
            for: asset,
            targetSize: CGSize(width: 1600, height: 1600),
            contentMode: .aspectFit,
            options: options
        ) { image, _ in
            completion(image)
        }
    }

    func makeMediaAsset(from phAsset: PHAsset) -> MediaAsset {
        MediaAsset(
            id: UUID().uuidString,
            localIdentifier: phAsset.localIdentifier,
            type: phAsset.mediaType == .video ? .video : .photo,
            dateTaken: phAsset.creationDate,
            width: phAsset.pixelWidth,
            height: phAsset.pixelHeight,
            thumbnailPath: nil,
            localPath: nil,
            remoteUrl: nil,
            createdAt: Date()
        )
    }

    /// 카드 이미지를 사진 앱에 저장.
    func saveImageToPhotos(_ image: UIImage) async -> Bool {
        let status = await PHPhotoLibrary.requestAuthorization(for: .addOnly)
        guard status == .authorized || status == .limited else { return false }
        return await withCheckedContinuation { continuation in
            PHPhotoLibrary.shared().performChanges({
                PHAssetChangeRequest.creationRequestForAsset(from: image)
            }) { success, _ in
                continuation.resume(returning: success)
            }
        }
    }
}
