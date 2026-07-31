import CoreImage.CIFilterBuiltins
import UIKit

/// 문자열을 QR 코드 이미지로 변환한다. CoreImage 내장 필터만 사용해 외부 의존성이 없다.
enum QRCodeGenerator {
    static func image(from string: String, pointSize: CGFloat = 200) -> UIImage? {
        let context = CIContext()
        let filter = CIFilter.qrCodeGenerator()
        filter.message = Data(string.utf8)
        filter.correctionLevel = "M"

        guard let outputImage = filter.outputImage else { return nil }

        let scale = pointSize / outputImage.extent.width
        let scaledImage = outputImage.transformed(by: CGAffineTransform(scaleX: scale, y: scale))

        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else { return nil }
        return UIImage(cgImage: cgImage)
    }
}
