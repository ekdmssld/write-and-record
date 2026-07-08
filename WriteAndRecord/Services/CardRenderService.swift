import SwiftUI
import UIKit

/// RecordCard 이미지 렌더링 (1080x1350 PNG).
enum CardRenderService {
    @MainActor
    static func renderImage(template: RecordCardTemplate, context: RecordCardContext) -> UIImage? {
        render(RecordCardView(template: template, context: context), baseSize: RecordCardView.baseSize)
    }

    /// 임의의 SwiftUI 뷰를 카드 이미지로 렌더링한다 (월간 캘린더 등).
    @MainActor
    static func render<Content: View>(_ content: Content, baseSize: CGSize, scale: CGFloat = 3.0) -> UIImage? {
        let renderer = ImageRenderer(content: content)
        renderer.scale = scale
        renderer.proposedSize = ProposedViewSize(baseSize)
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
