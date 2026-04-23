import SwiftUI

struct MediaImageView: View {
    let media: ClubImage
    
    var body: some View {
        if let data = media.imageData, let uiImage = UIImage(data: data) {
            Image(uiImage: uiImage)
                .resizable()
        } else {
            // Fallback to local asset
            Image(media.fileUrl)
                .resizable()
        }
    }
}

#Preview {
    VStack {
        MediaImageView(media: ClubImage(
            clubId: UUID(),
            type: .image,
            title: "Asset Image",
            fileUrl: "image1",
            uploadedBy: UUID(),
            createdAt: Date()
        ))
        .frame(width: 100, height: 100)
        .cornerRadius(12)
        
    }
}
