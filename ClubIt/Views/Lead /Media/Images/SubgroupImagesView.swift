import SwiftUI
import ClubItShared

enum GalleryTab: String, CaseIterable, Identifiable {
    case active = "Active"
    case archive = "Archive"
    var id: String { self.rawValue }
}

enum ImageDateFilter: String, CaseIterable, Identifiable {
    case all = "All Time"
    case week = "Last 7 Days"
    case month = "Last 30 Days"
    case year = "Last 12 Months"
    
    var id: String { self.rawValue }
    
    var icon: String {
        switch self {
        case .all: return "calendar"
        case .week: return "calendar.badge.clock"
        case .month: return "calendar.badge.exclamationmark"
        case .year: return "calendar.badge.plus"
        }
    }
}

enum ArchiveDateFilter: String, CaseIterable, Identifiable {
    case all = "All Archive"
    case oneToTwoYears = "1-2 Years Ago"
    case olderThanTwoYears = "Older than 2 Years"
    
    var id: String { self.rawValue }
}

struct SubgroupImagesView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(AppSession.self) var appSession
    
    @State private var isGalleryPresented: Bool = false
    @State private var selectedImageIndex: Int = 0
    @State private var currentGalleryImages: [SubgroupImage] = []
    @State private var isAddSectionPresented: Bool = false
    
    @State private var selectedTab: GalleryTab = .active
    @State private var selectedDateFilter: ImageDateFilter = .all
    @State private var selectedArchiveDateFilter: ArchiveDateFilter = .all
    
    let columns = [
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10),
        GridItem(.flexible(), spacing: 10)
    ]
    
    var body: some View {
        let oneYearAgo = Calendar.current.date(byAdding: .year, value: -1, to: Date()) ?? Date()
        
        let filteredSections = appSession.subgroupImageStore.sections.compactMap { section -> SubgroupImageSection? in
            let subgroupImages = section.images.filter { image in
                // 1. Subgroup match
                guard image.subgroupId == appSession.subgroupStore.subgroup.id else { return false }
                
                // 2. Archive check (older than 1 year is archive)
                let isArchived = image.createdAt < oneYearAgo
                if selectedTab == .active && isArchived { return false }
                if selectedTab == .archive && !isArchived { return false }
                
                // 3. Date-wise filter
                let calendar = Calendar.current
                if selectedTab == .active {
                    switch selectedDateFilter {
                    case .all:
                        break
                    case .week:
                        let weekAgo = calendar.date(byAdding: .day, value: -7, to: Date()) ?? Date()
                        if image.createdAt < weekAgo { return false }
                    case .month:
                        let monthAgo = calendar.date(byAdding: .month, value: -1, to: Date()) ?? Date()
                        if image.createdAt < monthAgo { return false }
                    case .year:
                        let yearAgo = calendar.date(byAdding: .year, value: -1, to: Date()) ?? Date()
                        if image.createdAt < yearAgo { return false }
                    }
                } else {
                    switch selectedArchiveDateFilter {
                    case .all:
                        break
                    case .oneToTwoYears:
                        let twoYearsAgo = calendar.date(byAdding: .year, value: -2, to: Date()) ?? Date()
                        if image.createdAt < twoYearsAgo { return false }
                    case .olderThanTwoYears:
                        let twoYearsAgo = calendar.date(byAdding: .year, value: -2, to: Date()) ?? Date()
                        if image.createdAt >= twoYearsAgo { return false }
                    }
                }
                
                return true
            }
            
            if subgroupImages.isEmpty { return nil }
            return SubgroupImageSection(
                id: section.id,
                title: section.title,
                images: subgroupImages,
                remainingCount: max(0, subgroupImages.count - 6)
            )
        }
        
        let totalActiveImagesCount = appSession.subgroupImageStore.sections.flatMap {
            $0.images.filter { $0.subgroupId == appSession.subgroupStore.subgroup.id && $0.createdAt >= oneYearAgo }
        }.count
        
        let totalArchiveImagesCount = appSession.subgroupImageStore.sections.flatMap {
            $0.images.filter { $0.subgroupId == appSession.subgroupStore.subgroup.id && $0.createdAt < oneYearAgo }
        }.count
        
        VStack(spacing: 0) {
            // Tab Picker
            Picker("Gallery Mode", selection: $selectedTab) {
                ForEach(GalleryTab.allCases) { tab in
                    Text(tab.rawValue).tag(tab)
                }
            }
            .pickerStyle(.segmented)
            .padding(.horizontal, 16)
            .padding(.top, 12)
            .padding(.bottom, 12)
            
            // Filter Bar
            let hasImages = (selectedTab == .active ? totalActiveImagesCount : totalArchiveImagesCount) > 0
            if hasImages {
                HStack {
                    if selectedTab == .active {
                        Menu {
                            Picker("Filter Date", selection: $selectedDateFilter) {
                                ForEach(ImageDateFilter.allCases) { filter in
                                    Label(filter.rawValue, systemImage: filter.icon).tag(filter)
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: selectedDateFilter.icon)
                                Text(selectedDateFilter.rawValue)
                                Image(systemName: "chevron.down").font(.caption)
                            }
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .glassEffect(in: .rect(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    } else {
                        Menu {
                            Picker("Archive Range", selection: $selectedArchiveDateFilter) {
                                ForEach(ArchiveDateFilter.allCases) { filter in
                                    Text(filter.rawValue).tag(filter)
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: "archivebox")
                                Text(selectedArchiveDateFilter.rawValue)
                                Image(systemName: "chevron.down").font(.caption)
                            }
                            .font(.subheadline)
                            .foregroundColor(.primary)
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .glassEffect(in: .rect(cornerRadius: 12))
                        }
                        .buttonStyle(.plain)
                    }
                    
                    Spacer()
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
            }
            
            GeometryReader { geometry in
                let availableWidth = geometry.size.width
                let itemWidth: CGFloat = {
                    guard availableWidth.isFinite, availableWidth > 52 else {
                        return 0
                    }
                    return (availableWidth - 52) / 3
                }()
                
                if selectedTab == .active && totalActiveImagesCount == 0 {
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
                } else if selectedTab == .archive && totalArchiveImagesCount == 0 {
                    VStack {
                        Spacer()
                        ContentUnavailableView(
                            "Archive Empty",
                            systemImage: "archivebox",
                            description: Text("Images older than one year will automatically appear here.")
                        )
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if filteredSections.isEmpty {
                    VStack {
                        Spacer()
                        ContentUnavailableView(
                            "No Matches Found",
                            systemImage: "magnifyingglass",
                            description: Text("Try adjusting your date filters.")
                        )
                        Spacer()
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else {
                    ScrollView(showsIndicators: false) {
                        VStack(alignment: .leading, spacing: 24) {
                            ForEach(filteredSections) { section in
                                VStack(alignment: .leading, spacing: 12) {
                                    NavigationLink(destination: SubgroupImageDetailView(section: section, isArchive: selectedTab == .archive)) {
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
                                                    NavigationLink(destination: SubgroupImageDetailView(section: section, isArchive: selectedTab == .archive)) {
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
        }
        .navigationTitle(selectedTab == .active ? "Images" : "Archive")
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
