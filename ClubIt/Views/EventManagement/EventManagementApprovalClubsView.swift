import SwiftUI

struct EventManagementApprovalClubsView: View {
    @Environment(AppSession.self) var appSession
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                let allEventsWithPending = appSession.eventStore.events.filter { event in
                    let hasPendingEvents = appSession.approvalStore.approvals.contains { $0.eventId == event.id && $0.status == .pending }
                    let hasPendingResources = appSession.approvalStore.resources.contains { $0.eventId == event.id && $0.status == .pending }
                    let hasPendingBudgets = appSession.approvalStore.budgets.contains { $0.eventId == event.id && $0.status == .pending }
                    return hasPendingEvents || hasPendingResources || hasPendingBudgets
                }.sorted(by: { $0.startDate > $1.startDate })
                
                if allEventsWithPending.isEmpty {
                    FacultyEmptyStateView(icon: "calendar.badge.exclamationmark", title: "No Pending Approvals", message: "There are no events currently requiring your approval.")
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(allEventsWithPending) { event in
                            if let club = appSession.clubStore.allClubs.first(where: { $0.id == event.clubId }) {
                                NavigationLink(destination: EventManagementApprovalDetailView(club: club, event: event)) {
                                    EventManagementEventApprovalCard(event: event, club: club)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Approval Management")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct EventManagementEventApprovalCard: View {
    @Environment(AppSession.self) var appSession
    let event: Event
    let club: Club
    
    var body: some View {
        let pendingResources = appSession.approvalStore.resources.filter { 
            $0.eventId == event.id && $0.status == .pending 
        }
        let pendingEvents = appSession.approvalStore.approvals.filter { 
            $0.eventId == event.id && $0.type == .event && $0.status == .pending 
        }
        let pendingVenues = appSession.approvalStore.approvals.filter { 
            $0.eventId == event.id && $0.type == .venue && $0.status == .pending 
        }
        let pendingBudgets = appSession.approvalStore.budgets.filter { 
            $0.eventId == event.id && $0.status == .pending 
        }
        
        let totalPending = pendingEvents.count + pendingResources.count + pendingVenues.count + pendingBudgets.count
        
        HStack(spacing: 16) {
            // Club Logo/Initials
            ZStack {
                Circle()
                    .fill(Color.orange.gradient.opacity(0.1))
                    .frame(width: 60, height: 60)
                
                Text(String(club.name.prefix(1)))
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.orange)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(event.name)
                    .font(.headline)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                
                Text(club.name)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.5)
                
                HStack(spacing: 8) {
                    if pendingEvents.count > 0 {
                        IndicatorTag(icon: "calendar", count: pendingEvents.count, color: .orange)
                    }
                    if pendingResources.count > 0 {
                        IndicatorTag(icon: "cart.fill", count: pendingResources.count, color: .blue)
                    }
                    if pendingVenues.count > 0 {
                        IndicatorTag(icon: "mappin.and.ellipse", count: pendingVenues.count, color: .purple)
                    }
                    if pendingBudgets.count > 0 {
                        IndicatorTag(icon: "indianrupeesign.circle.fill", count: pendingBudgets.count, color: .green)
                    }
                }
                .padding(.top, 4)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 6) {
                Text("\(totalPending)")
                    .font(.subheadline.bold())
                    .foregroundColor(totalPending > 0 ? .orange : .secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(totalPending > 0 ? Color.orange.opacity(0.1) : Color.secondary.opacity(0.1))
                    .clipShape(Capsule())
                
                Text("Pending")
                    .font(.caption2.bold())
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
            }
            
            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundColor(.secondary.opacity(0.3))
        }
        .padding(16)
        .glassEffect(in: .rect(cornerRadius: 24))
        .contentShape(.rect)
    }
}

struct IndicatorTag: View {
    let icon: String
    let count: Int
    let color: Color
    
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text("\(count)")
                .font(.system(size: 10, weight: .bold))
        }
        .foregroundColor(color)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(color.opacity(0.1))
        .clipShape(Capsule())
    }
}

#Preview {
    NavigationStack {
        EventManagementApprovalClubsView()
            .environment(MockData.session(for: .faculty))
    }
}
