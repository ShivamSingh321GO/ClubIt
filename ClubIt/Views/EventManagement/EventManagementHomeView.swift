import SwiftUI
import ClubItShared

struct EventManagementHomeView: View {
    @Environment(AppSession.self) var appSession
    
    var body: some View {
        NavigationStack {
            ZStack(alignment: .bottomTrailing) {
                ZStack {
                ScrollView(showsIndicators: false) {
                if let user = appSession.currentUser {
                    VStack(alignment: .leading, spacing: 28) {
                        
                        // Approval Management Section
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(spacing: 6) {
                                Text("Approval Management")
                                NavigationLink(destination: EventManagementApprovalSubgroupsView()) {
                                    Image(systemName: "chevron.right")
                                }
                            }
                            .font(.title2)
                            .bold()
                            
                            if user.role == .groupSubLead {
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
                }
                .refreshable {
                    await appSession.refreshData()
                }
                
                if appSession.isRefreshing && appSession.eventStore.events.isEmpty {
                    VStack {
                        ProgressView()
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(12)
                        Text("Loading data...")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color.black.opacity(0.1))
                    .transition(.opacity)
                }
                } // Close inner ZStack
                
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
        .task {
            await appSession.refreshData()
        }
    }
}

#Preview {
    EventManagementHomeView()
        .environment(MockData.session(for: .groupSubLead))
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
                        if let subgroup = appSession.subgroupStore.allSubgroups.first(where: { $0.id == event.subgroupId }) {
                            NavigationLink(destination: EventManagementApprovalDetailView(subgroup: subgroup, event: event)) {
                                EventManagementEventApprovalCard(event: event, subgroup: subgroup)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
}
