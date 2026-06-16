import SwiftUI

struct EventManagementApprovalClubsView: View {
    @Environment(AppSession.self) var appSession
    @State private var selectedFilter: ApprovalFilter = .all
    
    enum ApprovalFilter: String, CaseIterable {
        case all = "All"
        case upcoming = "Upcoming"
        case pending = "Pending"
        case approved = "Approved"
        case rejected = "Rejected"
        case overdue = "Overdue"
    }
    
    private func getStatus(for eventId: UUID) -> ApprovalFilter {
        let event = appSession.eventStore.events.first(where: { $0.id == eventId })
        let club = appSession.clubStore.allClubs.first(where: { $0.id == event?.clubId })
        let eventManagementTeamID = UUID(uuidString: "b02ff9cf-dce8-4be9-8fc6-a0d15c03ddad")!
        let facultyId = club?.facultyId ?? eventManagementTeamID

        let pendingResources = appSession.approvalStore.resources.filter { 
            $0.eventId == eventId && $0.status == .pending 
        }
        let allVenueApprovals = appSession.approvalStore.approvals.filter { $0.eventId == eventId && $0.type == .venue }
        let pendingVenues = allVenueApprovals.isEmpty ? [Approval(id: UUID(), type: .venue, senderId: UUID(), receiverId: facultyId, eventId: eventId, approvalRelatedId: eventId, status: .pending, remarks: [], createdAt: Date(), updatedAt: nil)] : allVenueApprovals.filter { 
            $0.status == .pending && ($0.receiverId == appSession.currentUser?.id || $0.receiverId == facultyId)
        }
        let pendingBudgets = appSession.approvalStore.budgets.filter { 
            $0.eventId == eventId && $0.status == .pending 
        }
        let pendingEvents = appSession.approvalStore.approvals.filter {
            $0.eventId == eventId && $0.type == .event && $0.status == .pending && ($0.receiverId == appSession.currentUser?.id || $0.receiverId == facultyId)
        }
        
        let totalPending: Int
        let isRejected: Bool
        
        if appSession.currentRole == .president {
            totalPending = pendingBudgets.count
            isRejected = appSession.approvalStore.budgets.contains { $0.eventId == eventId && $0.status == .rejected }
        } else if appSession.currentRole == .faculty {
            totalPending = pendingResources.count + pendingVenues.count + pendingEvents.count
            isRejected = appSession.approvalStore.approvals.contains { $0.eventId == eventId && $0.status == .rejected && ($0.receiverId == appSession.currentUser?.id || $0.receiverId == facultyId) } ||
                         appSession.approvalStore.resources.contains { $0.eventId == eventId && $0.status == .rejected }
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
        if filter == .upcoming {
            return allEvents.filter { $0.startDate >= Calendar.current.startOfDay(for: Date()) }.count
        }
        if filter == .overdue {
            return allEvents.filter { event in
                let isPast = event.startDate < Calendar.current.startOfDay(for: Date())
                return isPast && getStatus(for: event.id) == .pending
            }.count
        }
        return allEvents.filter { getStatus(for: $0.id) == filter }.count
    }
    
    var body: some View {
        let allEventsWithApprovals = appSession.eventStore.events.filter { event in
            let club = appSession.clubStore.allClubs.first(where: { $0.id == event.clubId })
            
            // Sequential role-based filtering: only show events that have approvals assigned to the current user/role
            if appSession.currentRole == .president {
                // President should only see the event if budget approvals exist for them
                return appSession.approvalStore.approvals.contains { 
                    $0.eventId == event.id && 
                    $0.type == .budget && 
                    $0.receiverId == appSession.currentUser?.id 
                }
            } else if appSession.currentRole == .faculty {
                // Faculty (EMT) should only see the event if event/resource/venue approvals exist for them
                let eventManagementTeamID = UUID(uuidString: "b02ff9cf-dce8-4be9-8fc6-a0d15c03ddad")!
                let facultyId = club?.facultyId ?? eventManagementTeamID
                return appSession.approvalStore.approvals.contains { 
                    $0.eventId == event.id && 
                    ($0.type == .event || $0.type == .resource || $0.type == .venue) && 
                    ($0.receiverId == appSession.currentUser?.id || $0.receiverId == facultyId)
                }
            } else if appSession.currentRole == .vicePresident {
                // VP should only see the event if event draft approvals exist for them
                return appSession.approvalStore.approvals.contains { 
                    $0.eventId == event.id && 
                    $0.type == .event && 
                    $0.receiverId == appSession.currentUser?.id 
                }
            }
            
            // Fallback for other roles (e.g. Lead or Student views all relevant items)
            let hasEvents = appSession.approvalStore.approvals.contains { $0.eventId == event.id }
            let hasResources = appSession.approvalStore.resources.contains { $0.eventId == event.id }
            let hasBudgets = appSession.approvalStore.budgets.contains { $0.eventId == event.id }
            return hasEvents || hasResources || hasBudgets
        }.sorted(by: { 
            if Calendar.current.isDate($0.startDate, inSameDayAs: $1.startDate) {
                return ($0.startTime ?? Date.distantFuture) < ($1.startTime ?? Date.distantFuture)
            }
            return $0.startDate < $1.startDate
        })

        let filteredEvents = allEventsWithApprovals.filter { event in
            if selectedFilter == .all {
                return true
            }
            if selectedFilter == .upcoming {
                return event.startDate >= Calendar.current.startOfDay(for: Date())
            }
            if selectedFilter == .overdue {
                let isPast = event.startDate < Calendar.current.startOfDay(for: Date())
                return isPast && getStatus(for: event.id) == .pending
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
                            icon: selectedFilter == .pending ? "hourglass" : (selectedFilter == .approved ? "checkmark.circle" : (selectedFilter == .upcoming ? "calendar" : (selectedFilter == .overdue ? "exclamationmark.triangle" : "xmark.circle"))),
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
        let allVenueApprovals = appSession.approvalStore.approvals.filter { $0.eventId == event.id && $0.type == .venue }
        let pendingVenues = allVenueApprovals.isEmpty ? [Approval(id: UUID(), type: .venue, senderId: UUID(), receiverId: club.facultyId ?? UUID(), eventId: event.id, approvalRelatedId: event.id, status: .pending, remarks: [], createdAt: Date(), updatedAt: nil)] : allVenueApprovals.filter { 
            $0.status == .pending 
        }
        let pendingBudgets = appSession.approvalStore.budgets.filter { 
            $0.eventId == event.id && $0.status == .pending 
        }
        

        let totalPending: Int = {
            if appSession.currentRole == .president {
                return pendingBudgets.count
            } else if appSession.currentRole == .faculty {
                let facultyId = club.facultyId
                let facultyPendingEvents = pendingEvents.filter { $0.receiverId == appSession.currentUser?.id || $0.receiverId == facultyId }.count
                let facultyPendingVenues = pendingVenues.filter { $0.receiverId == appSession.currentUser?.id || $0.receiverId == facultyId }.count
                return pendingResources.count + facultyPendingVenues + facultyPendingEvents
            } else if appSession.currentRole == .vicePresident {
                return pendingEvents.filter { $0.receiverId == appSession.currentUser?.id }.count
            } else {
                return pendingResources.count + pendingVenues.count + pendingBudgets.count + pendingEvents.count
            }
        }()
        
        let isRejected: Bool = {
            if appSession.currentRole == .president {
                return appSession.approvalStore.budgets.contains { $0.eventId == event.id && $0.status == .rejected }
            } else if appSession.currentRole == .faculty {
                let facultyId = club.facultyId
                return appSession.approvalStore.approvals.contains { $0.eventId == event.id && $0.status == .rejected && ($0.receiverId == appSession.currentUser?.id || $0.receiverId == facultyId) } ||
                       appSession.approvalStore.resources.contains { $0.eventId == event.id && $0.status == .rejected }
            } else if appSession.currentRole == .vicePresident {
                return appSession.approvalStore.approvals.contains { $0.eventId == event.id && $0.type == .event && $0.receiverId == appSession.currentUser?.id && $0.status == .rejected }
            } else {
                return appSession.approvalStore.approvals.contains { $0.eventId == event.id && $0.status == .rejected } ||
                       appSession.approvalStore.resources.contains { $0.eventId == event.id && $0.status == .rejected } ||
                       appSession.approvalStore.budgets.contains { $0.eventId == event.id && $0.status == .rejected }
            }
        }()
        
        let isApproved = totalPending == 0 && !isRejected
        
        HStack(spacing: 16) {
            // Event Image
            ZStack {
                if let bannerImage = event.bannerImage, !bannerImage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    AsyncImage(url: URL(string: bannerImage)) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 60)
                                .clipShape(Circle())
                        } else if phase.error != nil {
                            ZStack {
                                Circle()
                                    .fill(isApproved ? Color.green.gradient.opacity(0.1) : (isRejected ? Color.red.gradient.opacity(0.1) : Color.orange.gradient.opacity(0.1)))
                                    .frame(width: 60, height: 60)
                                Text(String(event.name.prefix(1).uppercased()))
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(isApproved ? .green : (isRejected ? .red : .orange))
                            }
                        } else {
                            Circle()
                                .fill(Color(.systemGray5))
                                .frame(width: 60, height: 60)
                                .overlay(ProgressView())
                        }
                    }
                } else {
                    Circle()
                        .fill(isApproved ? Color.green.gradient.opacity(0.1) : (isRejected ? Color.red.gradient.opacity(0.1) : Color.orange.gradient.opacity(0.1)))
                        .frame(width: 60, height: 60)
                    Text(String(event.name.prefix(1).uppercased()))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(isApproved ? .green : (isRejected ? .red : .orange))
                }
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
                    if appSession.currentRole == .president {
                        if pendingBudgets.count > 0 {
                            IndicatorTag(icon: "indianrupeesign.circle.fill", count: pendingBudgets.count, color: .green)
                        }
                    } else if appSession.currentRole == .faculty {
                        let facultyId = club.facultyId
                        let facultyPendingEvents = pendingEvents.filter { $0.receiverId == appSession.currentUser?.id || $0.receiverId == facultyId }.count
                        let facultyPendingVenues = pendingVenues.filter { $0.receiverId == appSession.currentUser?.id || $0.receiverId == facultyId }.count
                        
                        if facultyPendingEvents > 0 {
                            IndicatorTag(icon: "calendar", count: facultyPendingEvents, color: .orange)
                        }
                        if pendingResources.count > 0 {
                            IndicatorTag(icon: "cart.fill", count: pendingResources.count, color: .blue)
                        }
                        if facultyPendingVenues > 0 {
                            IndicatorTag(icon: "mappin.and.ellipse", count: facultyPendingVenues, color: .purple)
                        }
                    } else if appSession.currentRole == .vicePresident {
                        // VPs don't have resource/budget/venue indicators
                    } else {
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
                }
                .padding(.top, 2)
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
                    Text("!")
                        .font(.title3.bold())
                        .foregroundColor(.orange)
                        .frame(width: 40, height: 40)
                        .background(Color.orange.opacity(0.1))
                        .clipShape(Circle())
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
