import SwiftUI

struct MediaImageView: View {
    let media: ClubImage
    var contentMode: ContentMode = .fill
    
    @State private var loadedImage: UIImage? = nil
    @State private var isLoading: Bool = false
    @State private var hasFailed: Bool = false
    
    var body: some View {
        Group {
            if let data = media.imageData, let uiImage = UIImage(data: data) {
                // Local data takes priority (just-uploaded images)
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else if let uiImage = loadedImage {
                // Cached / downloaded image
                Image(uiImage: uiImage)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            } else if hasFailed {
                // Error state
                ZStack {
                    Color(.secondarySystemBackground)
                    Image(systemName: "photo")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }
            } else if isRemoteURL {
                // Loading state for remote URLs
                ZStack {
                    Color(.secondarySystemBackground)
                    ProgressView()
                }
                .onAppear { loadRemoteImage() }
            } else {
                // Fallback to local asset name
                Image(media.fileUrl)
                    .resizable()
                    .aspectRatio(contentMode: contentMode)
            }
        }
    }
    
    private var isRemoteURL: Bool {
        media.fileUrl.hasPrefix("http://") || media.fileUrl.hasPrefix("https://")
    }
    
    private func loadRemoteImage() {
        // Check the cache synchronously first (instant display)
        if let cached = ImageCacheManager.shared.cachedImage(for: media.fileUrl) {
            loadedImage = cached
            return
        }
        
        guard !isLoading else { return }
        isLoading = true
        
        Task {
            if let image = await ImageCacheManager.shared.loadImage(from: media.fileUrl) {
                await MainActor.run {
                    loadedImage = image
                    isLoading = false
                }
            } else {
                await MainActor.run {
                    hasFailed = true
                    isLoading = false
                }
            }
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
