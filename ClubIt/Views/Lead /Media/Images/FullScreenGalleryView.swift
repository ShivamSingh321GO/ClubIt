import SwiftUI

struct FullScreenGalleryView: View {
    let images: [ClubImage]
    @Binding var selectedIndex: Int
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSession.self) var appSession
    
    // Internal decoupled selection to guarantee initial tab loads instantly
    @State private var activeIndex: Int
    @State private var showDeleteAlert: Bool = false
    @State private var isDownloading: Bool = false
    
    init(images: [ClubImage], selectedIndex: Binding<Int>) {
        self.images = images
        self._selectedIndex = selectedIndex
        self._activeIndex = State(initialValue: selectedIndex.wrappedValue)
    }
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            TabView(selection: $activeIndex) {
                ForEach(Array(images.enumerated()), id: \.element.id) { index, image in
                    CachedFullScreenImage(media: image)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                        .tag(index)
                        .interactiveDismissDisabled()
                }
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .onChange(of: activeIndex) { _, newValue in
                selectedIndex = newValue
            }
            
            VStack {
                HStack {
                    // Close button (leading) with glassEffect
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.title3)
                            .bold()
                            .foregroundColor(.primary)
                            .padding()
                            .glassEffect(in: .circle)
                    }
                    .padding()
                    
                    Spacer()
                    
                    // Trailing Action Buttons with glassEffect
                    HStack(spacing: 16) {
                        // Download/Share button (all roles)
                        Button {
                            guard activeIndex >= 0 && activeIndex < images.count else { return }
                            downloadImage(image: images[activeIndex])
                        } label: {
                            Group {
                                if isDownloading {
                                    ProgressView()
                                        .tint(.primary)
                                        .padding()
                                        .glassEffect(in: .circle)
                                } else {
                                    Image(systemName: "arrow.down")
                                        .font(.title3)
                                        .bold()
                                        .foregroundColor(.primary)
                                        .padding()
                                        .glassEffect(in: .circle)
                                }
                            }
                        }
                        .disabled(isDownloading)
                        
                        // Delete button (Club Lead only)
                        if appSession.currentRole == .clubLead {
                            Button {
                                showDeleteAlert = true
                            } label: {
                                Image(systemName: "trash.fill")
                                    .font(.title3)
                                    .bold()
                                    .foregroundColor(.red)
                                    .padding()
                                    .glassEffect(in: .circle)
                            }
                        }
                    }
                    .padding()
                }
                Spacer()
            }
        }
        .alert("Delete Image", isPresented: $showDeleteAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Delete", role: .destructive) {
                guard activeIndex >= 0 && activeIndex < images.count else { return }
                let currentImage = images[activeIndex]
                
                // 1. Remove from image cache
                ImageCacheManager.shared.removeImage(for: currentImage.fileUrl)
                
                // 2. Optimistically remove locally and dismiss immediately to solve latency/lag
                appSession.clubImageStore.deleteImageOptimistically(currentImage)
                dismiss()
                
                // 3. Perform backend cleanup asynchronously in the background
                Task {
                    do {
                        try await appSession.clubImageStore.deleteImage(currentImage)
                    } catch {
                        print("DEBUG: Background deletion failed: \(error)")
                    }
                }
            }
        } message: {
            Text("Are you sure you want to permanently delete this image from the club gallery?")
        }
        .onAppear {
            activeIndex = selectedIndex
        }
    }
    
    private func getTopViewController() -> UIViewController? {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = windowScene.windows.first?.rootViewController else {
            return nil
        }
        var topVC = rootVC
        while let presented = topVC.presentedViewController {
            topVC = presented
        }
        return topVC
    }
    
    private func downloadImage(image: ClubImage) {
        isDownloading = true
        Task {
            var imageToShare: UIImage? = nil
            
            // Try local data first
            if let data = image.imageData, let uiImage = UIImage(data: data) {
                imageToShare = uiImage
            } else if image.fileUrl.hasPrefix("http") {
                // Use cached image from ImageCacheManager (instant if pre-fetched)
                imageToShare = await ImageCacheManager.shared.loadImage(from: image.fileUrl)
            } else {
                imageToShare = UIImage(named: image.fileUrl)
            }
            
            guard let finalImage = imageToShare else {
                await MainActor.run { isDownloading = false }
                return
            }
            
            await MainActor.run {
                isDownloading = false
                let activityVC = UIActivityViewController(activityItems: [finalImage], applicationActivities: nil)
                if let topVC = getTopViewController() {
                    if let popoverController = activityVC.popoverPresentationController {
                        popoverController.sourceView = topVC.view
                        popoverController.sourceRect = CGRect(x: topVC.view.bounds.midX, y: topVC.view.bounds.midY, width: 0, height: 0)
                        popoverController.permittedArrowDirections = []
                    }
                    
                    topVC.present(activityVC, animated: true)
                }
            }
        }
    }
}

/// A dedicated view that eagerly loads and retains the image for fullscreen display.
/// Unlike MediaImageView, this ensures the image stays loaded even when off-screen in a TabView.
private struct CachedFullScreenImage: View {
    let media: ClubImage
    @State private var uiImage: UIImage? = nil
    @State private var isLoading: Bool = true
    
    var body: some View {
        Group {
            if let image = uiImage {
                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
            } else if isLoading {
                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.2)
            } else {
                Image(systemName: "photo")
                    .font(.largeTitle)
                    .foregroundColor(.gray)
            }
        }
        .task {
            await loadImage()
        }
    }
    
    private func loadImage() async {
        // 1. Local data
        if let data = media.imageData, let img = UIImage(data: data) {
            uiImage = img
            isLoading = false
            return
        }
        
        // 2. Remote URL — use cache
        if media.fileUrl.hasPrefix("http://") || media.fileUrl.hasPrefix("https://") {
            if let img = await ImageCacheManager.shared.loadImage(from: media.fileUrl) {
                uiImage = img
            }
            isLoading = false
            return
        }
        
        // 3. Local asset
        uiImage = UIImage(named: media.fileUrl)
        isLoading = false
    }
}

#Preview {
    let images = (1...5).map { index in
        ClubImage(
            clubId: UUID(),
            eventId: UUID(),
            type: .image,
            title: "Gallery Image \(index)",
            fileUrl: index % 2 == 0 ? "image1" : "image2",
            uploadedBy: UUID(),
            createdAt: Date()
        )
    }
    let session = AppSession()
    session.currentRole = .clubLead
    
    return FullScreenGalleryView(images: images, selectedIndex: .constant(0))
        .environment(session)
}
