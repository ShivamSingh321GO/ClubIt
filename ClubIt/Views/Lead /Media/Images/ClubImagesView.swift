import SwiftUI

struct ClubImagesView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSession.self) var appSession
    
    @State private var isGalleryPresented: Bool = false
    @State private var selectedImageIndex: Int = 0
    @State private var currentGalleryImages: [ClubImage] = []
    @State private var isAddSectionPresented: Bool = false
    
    let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]
    
    var body: some View {
        let filteredSections = appSession.clubImageStore.sections.compactMap { section -> ClubImageSection? in
            let clubImages = section.images.filter { $0.clubId == appSession.clubStore.club.id }
            if clubImages.isEmpty { return nil }
            return ClubImageSection(
                id: section.id,
                title: section.title,
                images: clubImages,
                remainingCount: max(0, clubImages.count - 6)
            )
        }
        
        GeometryReader { geometry in
            let availableWidth = geometry.size.width
            let itemWidth: CGFloat = {
                guard availableWidth.isFinite, availableWidth > 52 else {
                    return 0
                }
                return (availableWidth - 52) / 3
            }()
            
            if filteredSections.isEmpty {
                VStack {
                    Spacer()
                    ContentUnavailableView(
                        "No Gallery Yet",
                        systemImage: "photo.on.rectangle",
                        description: Text("Only members of this club can see these images.")
                    )
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        ForEach(filteredSections) { section in
                            VStack(alignment: .leading, spacing: 12) {
                                NavigationLink(destination: ClubImageDetailView(section: section)) {
                                    HStack {
                                        Text(section.title)
                                            .font(.title2)
                                            .bold()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.title2)
                                            .bold()
                                            .foregroundColor(.goldenBrown)
                                        
                                        Spacer()
                                    }
                                }
                                .buttonStyle(.plain)
                                
                                LazyVGrid(columns: columns, spacing: 10) {
                                    ForEach(Array(section.images.prefix(6).enumerated()), id: \.offset) { index, media in
                                        ZStack {
                                            Button {
                                                currentGalleryImages = section.images
                                                selectedImageIndex = index
                                                isGalleryPresented = true
                                            } label: {
                                                MediaImageView(media: media)
                                                    .scaledToFill()
                                                    .frame(width: itemWidth, height: itemWidth)
                                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                            }
                                            .buttonStyle(.plain)
                                            
                                            if index == 5 && section.remainingCount > 0 {
                                                NavigationLink(destination: ClubImageDetailView(section: section)) {
                                                    ZStack {
                                                        Color.black.opacity(0.4)
                                                        
                                                        Text("+\(section.remainingCount)")
                                                            .font(.title2)
                                                            .fontWeight(.bold)
                                                            .foregroundColor(.white)
                                                    }
                                                    .frame(width: itemWidth, height: itemWidth)
                                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                                }
                                                .buttonStyle(.plain)
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                    .padding(16)
                }
            }
        }
        .navigationTitle("Images")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $isGalleryPresented) {
            FullScreenGalleryView(images: currentGalleryImages, selectedIndex: $selectedImageIndex)
        }
        .sheet(isPresented: $isAddSectionPresented) {
            AddImageSectionView()
        }
        .toolbar {
            if appSession.currentRole == .clubLead {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        isAddSectionPresented = true
                    } label: {
                        Image(systemName: "plus")
                            .font(.headline)
                            .fontWeight(.semibold)
                    }
                }
            }
        }
    }
}

#Preview {
    let session = AppSession()
    session.clubImageStore = ClubImageStore()
    
    return NavigationStack {
        ClubImagesView()
            .environment(session)
    }
}
