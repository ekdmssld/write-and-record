import SwiftUI
import Photos

/// MediaAsset(PHAsset localIdentifier 참조)의 썸네일을 로드해서 표시.
/// 권한이 없거나 원본이 삭제된 경우 placeholder를 보여준다.
struct AssetThumbnailView: View {
    let asset: MediaAsset
    var placeholderColorHex: String = "#9A9A9A"

    @EnvironmentObject private var photoService: PhotoLibraryService
    @State private var image: UIImage?

    var body: some View {
        GeometryReader { geo in
            Group {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                } else {
                    ZStack {
                        AppColors.category(placeholderColorHex).opacity(0.15)
                        Image(systemName: "photo")
                            .foregroundStyle(AppColors.textMuted)
                    }
                }
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .clipped()
            .onAppear {
                loadThumbnail(size: CGSize(width: geo.size.width * 2, height: geo.size.height * 2))
            }
        }
    }

    private func loadThumbnail(size: CGSize) {
        guard image == nil,
              let localId = asset.localIdentifier,
              let phAsset = photoService.fetchAsset(localIdentifier: localId) else { return }
        photoService.requestThumbnail(for: phAsset, size: size) { loaded in
            DispatchQueue.main.async {
                self.image = loaded
            }
        }
    }
}
