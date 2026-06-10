import SwiftUI

struct EventManagementApprovalClubsView: View {
    @Environment(AppSession.self) var appSession
    @State private var selectedFilter: ApprovalFilter = .all
    
    enum ApprovalFilter: String, CaseIterable {
        case all = "All"
        case pending = "Pending"
        case approved = "Approved"
        case rejected = "Rejected"
    }
    
    private func getStatus(for eventId: UUID) -> ApprovalFilter {
        let pendingResources = appSession.approvalStore.resources.filter { 
            $0.eventId == eventId && $0.status == .pending 
        }
        let pendingVenues = appSession.approvalStore.approvals.filter { 
            $0.eventId == eventId && $0.type == .venue && $0.status == .pending 
        }
        let pendingBudgets = appSession.approvalStore.budgets.filter { 
            $0.eventId == eventId && $0.status == .pending 
        }
        
        let totalPending: Int
        let isRejected: Bool
        
        if appSession.currentUser?.role == .president {
            totalPending = pendingBudgets.count
            isRejected = appSession.approvalStore.budgets.contains { $0.eventId == eventId && $0.status == .rejected }
        } else {
            totalPending = pendingResources.count + pendingVenues.count + pendingBudgets.count
            isRejected = appSession.approvalStore.approvals.contains { $0.eventId == eventId && $0.status == .rejected } ||
                         appSession.approvalStore.resources.contains { $0.eventId == eventId && $0.status == .rejected } ||
                         appSession.approvalStore.budgets.contains { $0.eventId == eventId && $0.status == .rejected }
        }
        
        if isRejected {
            return .rejected
        } else if totalPending > 0 {
            return .pending
        } else {
            return .approved
        }
    }
    
    private func count(for filter: ApprovalFilter, allEvents: [Event]) -> Int {
        if filter == .all {
            return allEvents.count
        }
        return allEvents.filter { getStatus(for: $0.id) == filter }.count
    }
    
    var body: some View {
        let allEventsWithApprovals = appSession.eventStore.events.filter { event in
            // If the club has a VP, hide the event from EMT/President until the VP has approved it
            let club = appSession.clubStore.allClubs.first(where: { $0.id == event.clubId })
            if let vpId = club?.vicePresidentId, appSession.currentUser?.role != .vicePresident {
                let vpApproval = appSession.approvalStore.approvals.first(where: { 
                    $0.eventId == event.id && 
                    $0.type == .event && 
                    $0.receiverId == vpId 
                })
                if vpApproval?.status != .approved {
                    return false
                }
            }
            
            let hasEvents = appSession.approvalStore.approvals.contains { $0.eventId == event.id }
            let hasResources = appSession.approvalStore.resources.contains { $0.eventId == event.id }
            let hasBudgets = appSession.approvalStore.budgets.contains { $0.eventId == event.id }
            return hasEvents || hasResources || hasBudgets
        }.sorted(by: { $0.createdAt > $1.createdAt })

        let filteredEvents = allEventsWithApprovals.filter { event in
            if selectedFilter == .all {
                return true
            }
            return getStatus(for: event.id) == selectedFilter
        }
        
        VStack(spacing: 0) {
            if !allEventsWithApprovals.isEmpty {
                // Filter Bar
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(ApprovalFilter.allCases, id: \.self) { filter in
                            ManagementFilterPill(
                                title: "\(filter.rawValue) \(count(for: filter, allEvents: allEventsWithApprovals))",
                                isSelected: selectedFilter == filter,
                                action: {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        selectedFilter = filter
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical, 8)
            }
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    if allEventsWithApprovals.isEmpty {
                        FacultyEmptyStateView(icon: "calendar.badge.exclamationmark", title: "No Approvals", message: "There are no events currently requiring or having received approval.")
                    } else if filteredEvents.isEmpty {
                        FacultyEmptyStateView(
                            icon: selectedFilter == .pending ? "hourglass" : (selectedFilter == .approved ? "checkmark.circle" : "xmark.circle"),
                            title: "No \(selectedFilter.rawValue) Approvals",
                            message: "There are no events currently matching the selected filter."
                        )
                    } else {
                        LazyVStack(spacing: 16) {
                            ForEach(filteredEvents) { event in
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
        }
        .navigationTitle("Approval Management")
        .navigationBarTitleDisplayMode(.inline)
    }
}

// MARK: - Subcomponents
fileprivate struct ManagementFilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .bold()
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accent : Color.secondary.opacity(0.1))
                .foregroundColor(isSelected ? .white : .secondary)
                .clipShape(RoundedRectangle(cornerRadius: 20))
        }
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
        
        let totalPending = appSession.currentUser?.role == .president ? pendingBudgets.count : (pendingResources.count + pendingVenues.count + pendingBudgets.count)
        
        let isRejected = appSession.currentUser?.role == .president ? 
            appSession.approvalStore.budgets.contains { $0.eventId == event.id && $0.status == .rejected } :
            (appSession.approvalStore.approvals.contains { $0.eventId == event.id && $0.status == .rejected } ||
             appSession.approvalStore.resources.contains { $0.eventId == event.id && $0.status == .rejected } ||
             appSession.approvalStore.budgets.contains { $0.eventId == event.id && $0.status == .rejected })
        
        let isApproved = totalPending == 0 && !isRejected
        
        HStack(spacing: 16) {
            // Club Logo/Initials
            ZStack {
                Circle()
                    .fill(isApproved ? Color.green.gradient.opacity(0.1) : (isRejected ? Color.red.gradient.opacity(0.1) : Color.orange.gradient.opacity(0.1)))
                    .frame(width: 60, height: 60)
                
                Text(String(club.name.prefix(1)))
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(isApproved ? .green : (isRejected ? .red : .orange))
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(event.name)
                    .font(.headline)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Text(club.name)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    if appSession.currentUser?.role != .president {
                        if pendingEvents.count > 0 {
                            IndicatorTag(icon: "calendar", count: pendingEvents.count, color: .orange)
                        }
                        if pendingResources.count > 0 {
                            IndicatorTag(icon: "cart.fill", count: pendingResources.count, color: .blue)
                        }
                        if pendingVenues.count > 0 {
                            IndicatorTag(icon: "mappin.and.ellipse", count: pendingVenues.count, color: .purple)
                        }
                    }
                    if pendingBudgets.count > 0 {
                        IndicatorTag(icon: "indianrupeesign.circle.fill", count: pendingBudgets.count, color: .green)
                    }
                }
                .padding(.top, 4)
            }
            
            Spacer()
            
            VStack(alignment: .center, spacing: 6) {
                if isApproved {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.title3)
                        .foregroundColor(.green)
                    Text("Approved")
                        .font(.caption2.bold())
                        .foregroundColor(.green)
                        .textCase(.uppercase)
                } else if isRejected {
                    Image(systemName: "xmark.seal.fill")
                        .font(.title3)
                        .foregroundColor(.red)
                    Text("Rejected")
                        .font(.caption2.bold())
                        .foregroundColor(.red)
                        .textCase(.uppercase)
                } else {
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
            }
            .fixedSize(horizontal: true, vertical: false)

            
//            Image(systemName: "chevron.right")
//                .font(.caption.bold())
//                .foregroundColor(.secondary.opacity(0.3))
        }
        .padding(16)
        .glassEffect(in: .rect(cornerRadius: 24))
        .contentShape(.rect)
    }
}


#Preview {
    NavigationStack {
        EventManagementApprovalClubsView()
            .environment(MockData.session(for: .faculty))
    }
}
