import SwiftUI

struct ExploreView: View {
    
    @Environment(AppSession.self) private var appSession
    
    enum ExploreTab: Int, CaseIterable, Identifiable {
        case announcement = 0
        case events = 1
        
        var id: Int { rawValue }
        
        var title: String {
            switch self {
            case .announcement: return "Announcement"
            case .events: return "Events"
            }
        }
    }
    
    @State private var showCreateAnnouncementSheet = false
    @State private var scope: EventScope = .allEvents
    @State private var selectedTab: ExploreTab
    
    init(selectedTab: ExploreTab = .announcement) {
        _selectedTab = State(initialValue: selectedTab)
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                
                Picker("", selection: $selectedTab) {
                    ForEach(ExploreTab.allCases) { tab in
                        Text(tab.title).tag(tab)
                    }
                }
                .pickerStyle(.segmented)
                
                ZStack(alignment: .bottomTrailing) {
                    VStack(spacing: 12) {
                        Group {
                            switch selectedTab {
                            case .announcement:
                                AnnouncementView(announcements: appSession.announcementStore.announcements)
                            case .events:
                                EventView(scope: $scope, eventStore: appSession.eventStore)
                            }
                        }
                    }
                    
                    if (selectedTab == .announcement && canCreateAnnouncement) || (selectedTab == .events && canCreateEvent) {
                        Group {
                            if selectedTab == .announcement {
                                Button {
                                    showCreateAnnouncementSheet = true
                                } label: {
                                    Image(systemName: "plus")
                                        .font(.title2.bold())
                                        .foregroundStyle(.primary)
                                        .frame(width: 56, height: 56)
                                        .glassEffect(in: .circle)
                                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                                }
                            } else {
                                NavigationLink {
                                    CreateNewEventView { _ in }
                                } label: {
                                    Image(systemName: "plus")
                                        .font(.title2.bold())
                                        .foregroundStyle(.primary)
                                        .frame(width: 56, height: 56)
                                        .glassEffect(in: .circle)
                                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                                }
                            }
                        }
                        .padding(.trailing, 16)
                        .padding(.bottom, 16)
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.top, 8)
            .navigationTitle("Explore")
            .toolbarTitleDisplayMode(.inlineLarge)
            .toolbar {
                // Toolbar menu/buttons removed as they are now in the FAB
            }
            .sheet(isPresented: $showCreateAnnouncementSheet) {
                CreateAnnouncementView { title, content, url, postedBy, clubId in
                    Task {
                        try? await appSession.announcementStore.addAnnouncement(
                            title: title,
                            content: content,
                            url: url,
                            postedBy: postedBy,
                            clubId: clubId
                        )
                    }
                }
            }
        }
    }
    
    private var canCreateAnnouncement: Bool {
        guard let role = appSession.currentRole else {
            return false
        }
        
        switch role {
        case .clubLead, .president, .vicePresident, .faculty:
            return true
        default:
            return false
        }
    }
    
    private var canCreateEvent: Bool {
        guard let role = appSession.currentRole else {
            return false
        }
        
        switch role {
        case .clubLead, .president:
            return true
        default:
            return false
        }
    }
}

#Preview {
    ExploreView()
        .environment(MockData.session(for: .clubLead))
}
