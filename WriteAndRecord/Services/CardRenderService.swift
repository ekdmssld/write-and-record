import SwiftUI
import UIKit

/// RecordCard 이미지 렌더링 (1080x1350 PNG).
enum CardRenderService {
    @MainActor
    static func renderImage(template: RecordCardTemplate, context: RecordCardContext) -> UIImage? {
        let view = RecordCardView(template: template, context: context)
        let renderer = ImageRenderer(content: view)
        renderer.scale = 3.0 // 360x450 * 3 = 1080x1350
        renderer.proposedSize = ProposedViewSize(RecordCardView.baseSize)
        return renderer.uiImage
    }

    /// share sheet용 임시 PNG 파일. 사진 권한 없이도 공유 가능해야 한다.
    static func writeTempPNG(_ image: UIImage) -> URL? {
        guard let data = image.pngData() else { return nil }
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("WriteAndRecord-card-\(UUID().uuidString.prefix(8)).png")
        do {
            try data.write(to: url, options: [.atomic])
            return url
        } catch {
            return nil
        }
    }
}
