import SwiftUI
import ClubItShared

struct ExploreView: View {
    @Environment(AppSession.self) private var appSession
    
    enum ExploreTab: Int, CaseIterable, Identifiable {
        case events = 0
        case announcement = 1
        
        var id: Int { rawValue }
        
        var title: String {
            switch self {
            case .events: return "Events"
            case .announcement: return "Announcement"
            }
        }
    }
    
    @State private var showCreateAnnouncementSheet = false
    @State private var editingAnnouncement: Announcement? = nil
    @State private var scope: EventScope = .allEvents
    @State private var selectedTab: ExploreTab
    
    init(selectedTab: ExploreTab = .events) {
        _selectedTab = State(initialValue: selectedTab)
    }
    
    private var isEventsAvailable: Bool {
        appSession.organizationFeatures?.events != true
    }
    
    private var isAnnouncementsAvailable: Bool {
        appSession.organizationFeatures?.announcements != true
    }
    
    private var activeTab: ExploreTab {
        if isEventsAvailable && isAnnouncementsAvailable {
            return selectedTab
        } else if isAnnouncementsAvailable && !isEventsAvailable {
            return .announcement
        } else {
            return .events
        }
    }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                // Only show segmented control picker if BOTH subtabs are available
                if isEventsAvailable && isAnnouncementsAvailable {
                    Picker("", selection: $selectedTab) {
                        Text(ExploreTab.events.title).tag(ExploreTab.events)
                        Text(ExploreTab.announcement.title).tag(ExploreTab.announcement)
                    }
                    .pickerStyle(.segmented)
                }
                
                let currentTab = activeTab
                
                ZStack(alignment: .bottomTrailing) {
                    VStack(spacing: 12) {
                        switch currentTab {
                        case .announcement:
                            AnnouncementView(
                                announcements: appSession.announcementStore.announcements,
                                onEdit: { announcement in
                                    print("DEBUG: [ExploreView] Requested edit for announcement: \(announcement.id)")
                                    editingAnnouncement = announcement
                                },
                                onDelete: { announcement in
                                    print("DEBUG: [ExploreView] Requested delete for announcement: \(announcement.id)")
                                    Task {
                                        do {
                                            try await appSession.announcementStore.deleteAnnouncement(announcement)
                                        } catch {
                                            print("❌ ERROR DELETING ANNOUNCEMENT: \(error)")
                                        }
                                    }
                                }
                            )
                        case .events:
                            EventView(scope: $scope, eventStore: appSession.eventStore)
                        }
                    }
                    
                    // Plus FAB button for creating announcements or events
                    if (currentTab == .announcement && canCreateAnnouncement) || (currentTab == .events && canCreateEvent) {
                        Group {
                            if currentTab == .announcement {
                                Button {
                                    print("DEBUG: [ExploreView] Presenting create announcement sheet")
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
            .navigationTitle(appSession.exploreTabTitle)
            .toolbarTitleDisplayMode(.inlineLarge)
            .sheet(isPresented: $showCreateAnnouncementSheet) {
                CreateAnnouncementView { title, content, url, postedBy, groupId, organizationId in
                    print("DEBUG: [ExploreView] Create announcement closure triggered with title='\(title)'")
                    Task {
                        do {
                            try await appSession.announcementStore.addAnnouncement(
                                title: title,
                                content: content,
                                url: url,
                                postedBy: postedBy,
                                groupId: groupId,
                                organizationId: organizationId
                            )
                        } catch {
                            print("❌ ERROR ADDING ANNOUNCEMENT: \(error)")
                        }
                    }
                }
            }
            .sheet(item: $editingAnnouncement) { announcement in
                CreateAnnouncementView(announcement: announcement) { title, content, url, _, _, _ in
                    print("DEBUG: [ExploreView] Edit announcement closure triggered for id=\(announcement.id) with title='\(title)'")
                    Task {
                        do {
                            try await appSession.announcementStore.updateAnnouncement(
                                id: announcement.id,
                                title: title,
                                content: content,
                                url: url
                            )
                        } catch {
                            print("❌ ERROR UPDATING ANNOUNCEMENT: \(error)")
                        }
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
        case .subGroupLead, .groupLead, .groupSubLead:
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
        case .subGroupLead, .groupLead:
            return true
        default:
            return false
        }
    }
}

#Preview {
    ExploreView()
        .environment(MockData.session(for: .subGroupLead))
}
