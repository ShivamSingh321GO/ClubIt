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
                            Text("Tasks")
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
                    ForEach(sentApprovals.sorted(by: { $0.createdAt > $1.createdAt })) { approval in
                        if let event = appSession.eventStore.events.first(where: { $0.id == approval.eventId }) {
                            NavigationLink(destination: EventApprovalsDetailView(eventId: event.id)) {
                                LeadApprovalEventCard(event: event, approval: approval)
                            }
                            .buttonStyle(.plain)
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

struct LeadApprovalEventCard: View {
    @Environment(AppSession.self) var appSession
    let event: Event
    let approval: Approval
    
    var body: some View {
        let pendingResources = appSession.approvalStore.resources.filter { 
            $0.eventId == event.id && $0.status == .pending 
        }
        let pendingVenues = appSession.approvalStore.approvals.filter { 
            $0.eventId == event.id && $0.type == .venue && $0.status == .pending 
        }
        let pendingBudgets = appSession.approvalStore.budgets.filter { 
            $0.eventId == event.id && $0.status == .pending 
        }
        
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Text(event.name)
                    .font(.headline)
                    .lineLimit(1)
                Spacer()
                Text(approval.status.rawValue.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.1))
                    .foregroundColor(statusColor)
                    .clipShape(Capsule())
            }
            
            Text(event.category.rawValue)
                .font(.caption)
                .foregroundColor(.secondary)
            
            HStack(spacing: 8) {
                if pendingResources.count > 0 {
                    LeadIndicatorTag(icon: "cart.fill", count: pendingResources.count, color: .blue)
                }
                if pendingVenues.count > 0 {
                    LeadIndicatorTag(icon: "mappin.and.ellipse", count: pendingVenues.count, color: .purple)
                }
                if pendingBudgets.count > 0 {
                    LeadIndicatorTag(icon: "indianrupeesign.circle.fill", count: pendingBudgets.count, color: .green)
                }
            }
            
            Divider().opacity(0.2)
            
            HStack {
                Image(systemName: "calendar")
                    .font(.caption)
                Text(event.startDate.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
            }
            .foregroundColor(.secondary)
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .glassEffect(in: .rect(cornerRadius: 28))
    }
    
    var statusColor: Color {
        switch approval.status {
        case .pending: return .orange
        case .approved: return .green
        case .rejected: return .red
        }
    }
}

struct LeadIndicatorTag: View {
    let icon: String
    let count: Int
    let color: Color
    
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 9))
            Text("\(count)")
                .font(.system(size: 9, weight: .bold))
        }
        .foregroundColor(color)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(color.opacity(0.1))
        .clipShape(Capsule())
    }
}


#Preview {
    let session = AppSession()
    session.currentUser = MockData.clubLeadUser
    
    return LeadHomeView()
        .environment(session)
}
