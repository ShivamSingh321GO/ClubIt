import SwiftUI
import ClubItShared

struct SubgroupImagesView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSession.self) var appSession
    
    @State private var isGalleryPresented: Bool = false
    @State private var selectedImageIndex: Int = 0
    @State private var currentGalleryImages: [SubgroupImage] = []
    @State private var isAddSectionPresented: Bool = false
    
    let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]
    
    var body: some View {
        let filteredSections = appSession.subgroupImageStore.sections.compactMap { section -> SubgroupImageSection? in
            let subgroupImages = section.images.filter { $0.subgroupId == appSession.subgroupStore.subgroup.id }
            if subgroupImages.isEmpty { return nil }
            return SubgroupImageSection(
                id: section.id,
                title: section.title,
                images: subgroupImages,
                remainingCount: max(0, subgroupImages.count - 6)
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
                        description: Text("Only members of this subgroup can see these images.")
                    )
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 24) {
                        ForEach(filteredSections) { section in
                            VStack(alignment: .leading, spacing: 12) {
                                NavigationLink(destination: SubgroupImageDetailView(section: section)) {
                                    HStack {
                                        Text(section.title)
                                            .font(.title2)
                                            .bold()
                                        
                                        Image(systemName: "chevron.right")
                                            .font(.title2)
                                            .bold()
                                            .foregroundColor(.accentColor)
                                        
                                        Spacer()
                                    }
                                }
                                .buttonStyle(.plain)
                                
                                LazyVGrid(columns: columns, spacing: 10) {
                                    ForEach(Array(section.images.prefix(6).enumerated()), id: \.element.id) { index, media in
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
                                                NavigationLink(destination: SubgroupImageDetailView(section: section)) {
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
                .refreshable {
                    try? await appSession.subgroupImageStore.fetchImages(subgroupId: appSession.subgroupStore.subgroup.id)
                }
            }
        }
        .navigationTitle("Images")
        .navigationBarTitleDisplayMode(.inline)
        .fullScreenCover(isPresented: $isGalleryPresented) {
            FullScreenGalleryView(images: currentGalleryImages, selectedIndex: $selectedImageIndex)
                .environment(appSession)
        }
        .sheet(isPresented: $isAddSectionPresented) {
            AddImageSectionView()
        }
        .toolbar {
            if appSession.currentRole == .subGroupLead {
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
    session.subgroupImageStore = SubgroupImageStore()
    
    return NavigationStack {
        SubgroupImagesView()
            .environment(session)
    }
}
