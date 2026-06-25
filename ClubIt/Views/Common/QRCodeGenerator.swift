import SwiftUI
import ClubItShared
import CoreImage.CIFilterBuiltins

struct QRCodeGenerator {
    let context = CIContext()
    let filter = CIFilter.qrCodeGenerator()

    func generateQRCode(from string: String) -> UIImage {
        filter.message = Data(string.utf8)

        if let outputImage = filter.outputImage {
            // Scale up the image because it's tiny by default
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            let scaledImage = outputImage.transformed(by: transform)
            
            if let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) {
                return UIImage(cgImage: cgImage)
            }
        }

        return UIImage(systemName: "xmark.circle") ?? UIImage()
    }
}
