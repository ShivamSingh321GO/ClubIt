import SwiftUI
import PhotosUI

struct ClubImageDetailView: View {
    let section: ClubImageSection
    
    @Environment(AppSession.self) var appSession
    
    @State private var isGalleryPresented: Bool = false
    @State private var selectedImageIndex: Int = 0
    @State private var selectedItems: [PhotosPickerItem] = []

    private var liveSection: ClubImageSection {
        appSession.clubImageStore.sections.first(where: { $0.id == section.id }) ?? section
    }
    
    let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]
    
    var body: some View {
        GeometryReader { geometry in
            imageGridView(availableWidth: geometry.size.width)
        }
        .navigationTitle(liveSection.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            if appSession.currentRole == .clubLead {
                ToolbarItem(placement: .navigationBarTrailing) {
                    PhotosPicker(selection: $selectedItems, matching: .images, photoLibrary: .shared()) {
                        Image(systemName: "plus")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                }
            }
        }
        .onChange(of: selectedItems) { _, newValue in
            handlePhotoSelection(newValue)
        }
        .fullScreenCover(isPresented: $isGalleryPresented) {
            FullScreenGalleryView(images: liveSection.images, selectedIndex: $selectedImageIndex)
                .environment(appSession)
        }
    }
    
    @ViewBuilder
    private func imageGridView(availableWidth: CGFloat) -> some View {
        if availableWidth > 52 {
            let itemWidth = (availableWidth - 52) / 3
            ScrollView(showsIndicators: false) {
                LazyVGrid(columns: columns, spacing: 10) {
                    let images = liveSection.images
                    ForEach(Array(images.enumerated()), id: \.element.id) { index, media in
                        Button(action: {
                            selectedImageIndex = index
                            isGalleryPresented = true
                        }) {
                            MediaImageView(media: media)
                                .scaledToFill()
                                .frame(width: itemWidth, height: itemWidth)
                                .cornerRadius(12)
                                .clipped()
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(16)
            }
            .refreshable {
                try? await appSession.clubImageStore.fetchImages(clubId: appSession.clubStore.club.id)
            }
        } else {
            Color.clear
        }
    }
    
    private func handlePhotoSelection(_ items: [PhotosPickerItem]) {
        Task {
            let clubId = appSession.clubStore.club.id
            let userId = appSession.currentUser?.id ?? UUID()
            
            for item in items {
                if let data = try? await item.loadTransferable(type: Data.self) {
                    do {
                        try await appSession.clubImageStore.addImage(
                            title: liveSection.title,
                            imageData: data,
                            clubId: clubId,
                            uploadedBy: userId
                        )
                    } catch {
                        print("DEBUG: Failed to add image to section: \(error)")
                    }
                }
            }
            selectedItems = []
        }
    }
}

#Preview {
    let euphoricImages = (1...10).map { _ in
        ClubImage(
            clubId: UUID(),
            eventId: UUID(),
            type: .image,
            title: "Euphoria Fest",
            fileUrl: "image1",
            uploadedBy: UUID(),
            createdAt: Date()
        )
    }
    let section = ClubImageSection(title: "Euphoria Fest", images: euphoricImages, remainingCount: 0)
    let session = AppSession()
    
    NavigationStack {
        ClubImageDetailView(section: section)
            .environment(session)
    }
}
