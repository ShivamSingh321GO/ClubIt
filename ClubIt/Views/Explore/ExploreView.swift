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
                    Group {
                        switch selectedTab {
                        case .announcement:
                            AnnouncementView(announcements: appSession.globalAnnouncementStore.announcements)
                        case .events:
                            EventView(scope: $scope, eventStore: appSession.eventStore)
                        }
                    }
                    
                    if canCreateAnnouncement && selectedTab == .announcement {
                        Button {
                            showCreateAnnouncementSheet = true
                        } label: {
                            Image(systemName: "plus")
                                .font(.title.bold())
                                .foregroundColor(.white)
                                .frame(width: 56, height: 56)
                                .background(Color.orange.gradient)
                                .clipShape(Circle())
                                .shadow(color: .orange.opacity(0.3), radius: 10, x: 0, y: 5)
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
                if selectedTab == .events {
                    ToolbarItemGroup(placement: .topBarTrailing) {
                        if canCreateEvent {
                            NavigationLink {
                                CreateNewEventView { event in
                                    appSession.eventStore.addEvent(event)
                                }
                            } label: {
                                Image(systemName: "plus")
                            }
                        }
                        
                        if appSession.currentRole != .president && appSession.currentRole != .faculty {
                            Menu {
                                Button("My Events") {
                                    scope = .myEvents
                                }
                                
                                Button("All Events") {
                                    scope = .allEvents
                                }
                            } label: {
                                Image(systemName: "line.3.horizontal.decrease")
                            }
                        }
                    }
                }
            }
            .sheet(isPresented: $showCreateAnnouncementSheet) {
                CreateAnnouncementView { title, content, url, postedBy, clubId in
                    appSession.globalAnnouncementStore.addAnnouncement(
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
        case .clubLead:
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
