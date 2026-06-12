import SwiftUI

struct FacultyApprovalsListView: View {
    @Environment(AppSession.self) var appSession
    let user: User
    @Binding var selectedEventId: UUID?
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
        let relevantApprovals = appSession.approvalStore.approvals.filter { 
            $0.receiverId == user.id && $0.type != .budget && $0.eventId == eventId
        }
        let isRejected = relevantApprovals.contains { $0.status == .rejected }
        let isPending = relevantApprovals.contains { $0.status == .pending }
        
        if isRejected { return .rejected }
        if isPending { return .pending }
        return .approved
    }
    
    private func count(for filter: ApprovalFilter, eventIds: [UUID]) -> Int {
        if filter == .all { return eventIds.count }
        if filter == .upcoming {
            return eventIds.filter { eventId in
                guard let event = appSession.eventStore.events.first(where: { $0.id == eventId }) else { return false }
                return event.startDate >= Calendar.current.startOfDay(for: Date())
            }.count
        }
        if filter == .overdue {
            return eventIds.filter { eventId in
                guard let event = appSession.eventStore.events.first(where: { $0.id == eventId }) else { return false }
                let isPast = event.startDate < Calendar.current.startOfDay(for: Date())
                return isPast && getStatus(for: eventId) == .pending
            }.count
        }
        return eventIds.filter { getStatus(for: $0) == filter }.count
    }
    
    var body: some View {
        let relevantApprovals = appSession.approvalStore.approvals.filter { 
            $0.receiverId == user.id && $0.type != .budget
        }
        
        let groupedApprovals = Dictionary(grouping: relevantApprovals, by: { $0.eventId })
        
        let allEventIds = groupedApprovals.keys.compactMap { $0 }.sorted(by: { id1, id2 in
            guard let e1 = appSession.eventStore.events.first(where: { $0.id == id1 }),
                  let e2 = appSession.eventStore.events.first(where: { $0.id == id2 }) else { return false }
            if Calendar.current.isDate(e1.startDate, inSameDayAs: e2.startDate) {
                return (e1.startTime ?? Date.distantFuture) < (e2.startTime ?? Date.distantFuture)
            }
            return e1.startDate < e2.startDate
        })
        
        let filteredEventIds = allEventIds.filter { eventId in
            if selectedFilter == .all { return true }
            if selectedFilter == .upcoming {
                guard let event = appSession.eventStore.events.first(where: { $0.id == eventId }) else { return false }
                return event.startDate >= Calendar.current.startOfDay(for: Date())
            }
            if selectedFilter == .overdue {
                guard let event = appSession.eventStore.events.first(where: { $0.id == eventId }) else { return false }
                let isPast = event.startDate < Calendar.current.startOfDay(for: Date())
                return isPast && getStatus(for: eventId) == .pending
            }
            return getStatus(for: eventId) == selectedFilter
        }
        
        VStack(spacing: 0) {
            if !groupedApprovals.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 12) {
                        ForEach(ApprovalFilter.allCases, id: \.self) { filter in
                            FacultyFilterPill(
                                title: "\(filter.rawValue) \(count(for: filter, eventIds: allEventIds))",
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
                    if groupedApprovals.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 60))
                                .foregroundColor(.green.opacity(0.5))
                            
                            Text("No Approval Requests")
                                .font(.title2.bold())
                            
                            Text("There are no event approval requests at the moment.")
                                .multilineTextAlignment(.center)
                                .foregroundColor(.secondary)
                        }
                        .padding(40)
                        .frame(maxWidth: .infinity)
                        .glassEffect(in: .rect(cornerRadius: 30))
                        .padding(.top, 40)
                    } else if filteredEventIds.isEmpty {
                        VStack(spacing: 20) {
                            Image(systemName: selectedFilter == .pending ? "hourglass" : (selectedFilter == .approved ? "checkmark.circle" : (selectedFilter == .upcoming ? "calendar" : (selectedFilter == .overdue ? "exclamationmark.triangle" : "xmark.circle"))))
                                .font(.system(size: 60))
                                .foregroundColor(.secondary)
                            
                            Text("No \(selectedFilter.rawValue) Requests")
                                .font(.title2.bold())
                            
                            Text("No requests match the selected filter.")
                                .multilineTextAlignment(.center)
                                .foregroundColor(.secondary)
                        }
                        .padding(40)
                        .frame(maxWidth: .infinity)
                        .glassEffect(in: .rect(cornerRadius: 30))
                        .padding(.top, 40)
                    } else {
                        VStack(spacing: 16) {
                            ForEach(filteredEventIds, id: \.self) { eventId in
                                if let event = appSession.eventStore.events.first(where: { $0.id == eventId }) {
                                    let eventApprovals = groupedApprovals[eventId] ?? []
                                    let isPending = eventApprovals.contains { $0.status == .pending }
                                    
                                    ApprovalSummaryCard(
                                        title: event.name,
                                        subtitle: (isPending ? "Pending Action • " : "Processed • ") + formatDate(event.createdAt),
                                        eventDate: event.dateRangeString,
                                        action: { selectedEventId = eventId }
                                    )
                                }
                            }
                        }
                    }
                }
                .padding()
            }
        }
        .navigationTitle("Approval Requests")
        .navigationBarTitleDisplayMode(.large)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - FacultyFilterPill
fileprivate struct FacultyFilterPill: View {
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

#Preview {
    NavigationStack {
        FacultyApprovalsListView(user: MockData.facultyResource, selectedEventId: .constant(nil))
            .environment(MockData.session(for: .faculty))
    }
}
