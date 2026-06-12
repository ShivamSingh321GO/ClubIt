import SwiftUI

struct EventManagementHomeView: View {
    @Environment(AppSession.self) var appSession
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                ScrollView(showsIndicators: false) {
                if let user = appSession.currentUser {
                    VStack(alignment: .leading, spacing: 28) {
                        
                        // Approval Management Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(spacing: 6) {
                                Text("Approval Management")
                                NavigationLink(destination: EventManagementApprovalClubsView()) {
                                    Image(systemName: "chevron.right")
                                }
                            }
                            .font(.title2)
                            .bold()
                            
                            if user.role == .faculty {
                                if user.email == "emt" {
                                    EMTApprovalsModule(user: user)
                                } else {
                                    FacultyApprovalsModule(user: user)
                                }
                            } else {
                                PresidentApprovalsModule(user: user)
                            }
                        }
                        
                        // Venue Allocation Overview Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(spacing: 6) {
                                Text("Allocated Venues")
                                NavigationLink(destination: FacultyVenueListView()) {
                                    Image(systemName: "chevron.right")
                                }
                            }
                            .font(.title2)
                            .bold()
                            
                            HomeVenuesModule()
                        }
                        
                    }
                    .padding(.horizontal)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
                    .navigationTitle("Home")
                    .toolbarTitleDisplayMode(.inlineLarge)
                    .toolbar {
                        ToolbarItemGroup(placement: .topBarTrailing) {
                            NavigationLink {
                                LeadNotificationView()
                            } label: {
                                Image(systemName: "bell")
                            }
                            
                            NavigationLink {
                                LeadProfileView()
                            } label: {
                                Image(systemName: "person.circle")
                            }
                        }
                    }
                }
                
                NavigationLink(destination: ClubItCalendarView(standalone: true)) {
                    Image(systemName: "calendar")
                        .font(.title2.bold())
                        .foregroundStyle(.primary)
                        .frame(width: 56, height: 56)
                        .glassEffect(in: .circle)
                        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
                }
                .padding()
            }
            }
        }
    }
}

#Preview {
    EventManagementHomeView()
        .environment(MockData.session(for: .faculty))
}

struct EMTApprovalsModule: View {
    @Environment(AppSession.self) var appSession
    let user: User

    var body: some View {
        let eventsWithApprovals = appSession.eventStore.events.filter { event in
            appSession.approvalStore.approvals.contains { 
                $0.eventId == event.id && 
                $0.type == .venue && 
                $0.status == .pending
            } ||
            appSession.approvalStore.resources.contains {
                $0.eventId == event.id &&
                $0.status == .pending
            }
        }.sorted(by: { $0.startDate > $1.startDate })
        
        VStack(alignment: .leading, spacing: 16) {
            if eventsWithApprovals.isEmpty {
                Text("No venue or resource requests")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .glassEffect(in: .rect(cornerRadius: 20))
            } else {
                VStack(spacing: 16) {
                    ForEach(eventsWithApprovals.prefix(2)) { event in
                        if let club = appSession.clubStore.allClubs.first(where: { $0.id == event.clubId }) {
                            NavigationLink(destination: EventManagementApprovalDetailView(club: club, event: event)) {
                                EventManagementEventApprovalCard(event: event, club: club)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
}
