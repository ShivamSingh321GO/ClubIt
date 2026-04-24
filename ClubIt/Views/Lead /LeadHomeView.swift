import SwiftUI

struct LeadHomeView: View {
    @Environment(AppSession.self) var appSession
    @State private var selectedEventId: UUID? = nil

    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                if let user = appSession.currentUser {
                    VStack(alignment: .leading, spacing: 24) {
                        HStack {
                            Text("All Tasks")
                            NavigationLink(destination: TasksListView(user: user)) {
                                Image(systemName: "chevron.right")
                            }
                        }
                        .font(.title2)
                        .bold()
                        
                        HomeTasksModule(user: user)
                        
                        HStack {
                            Text("Approval Requests")
                            NavigationLink(destination: ApprovalsListView(user: user)) {
                                Image(systemName: "chevron.right")
                            }
                        }
                        .font(.title2)
                        .bold()
                        
                        HomeApprovalsModule(user: user) { id in
                            selectedEventId = id
                        }

                        
//                        HStack {
//                            Text("Upcoming events")
//                            
//                            NavigationLink(destination: ExploreView(selectedTab: .events)) {
//                                Image(systemName: "chevron.right")
//                            }
//                            
//                            Spacer()
//                            
//                            NavigationLink(destination: CalendarView()) {
//                                Image(systemName: "calendar")
//                            }
//                        }
//                        .font(.title2)
//                        .bold()
//                        
//                        UpcomingEventsModule(user: user)
                    }
                    .padding(.horizontal)
                    .navigationTitle("Home")
                    .toolbarTitleDisplayMode(.inlineLarge)
                    .navigationDestination(item: $selectedEventId) { id in
                        EventApprovalsDetailView(eventId: id)
                    }
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
        }
    }
}

// MARK: - Modules
struct HomeApprovalsModule: View {
    @Environment(AppSession.self) var appSession
    let user: User
    let onSelect: (UUID) -> Void

    
    var body: some View {
        let sentApprovals = appSession.approvalStore.approvals.filter { approval in
            approval.senderId == user.id &&
            approval.type == .event &&
            appSession.eventStore.events.contains(where: { $0.id == approval.eventId })
        }
        
        VStack(alignment: .leading, spacing: 16) {
            if sentApprovals.isEmpty {
                Text("No recent approval requests")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
//                    .background(.ultraThinMaterial)
//                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .glassEffect(in: .rect(cornerRadius: 20))
//                    .overlay(
//                        RoundedRectangle(cornerRadius: 16)
//                            .stroke(Color.primary.opacity(0.1), lineWidth: 1)
//                    )
            } else {
                VStack(spacing: 16) {
                    ForEach(sentApprovals.prefix(2), id: \.id) { approval in
                        if let event = appSession.eventStore.events.first(where: { $0.id == approval.eventId }) {
                            ApprovalSummaryCard(
                                title: event.name,
                                subtitle: "Created by you • \(formatDate(event.createdAt))",
                                action: { onSelect(approval.eventId) }
                            )
                        }
                    }
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}


#Preview {
    let session = AppSession()
    session.currentUser = MockData.clubLeadUser
    
    return LeadHomeView()
        .environment(session)
}
