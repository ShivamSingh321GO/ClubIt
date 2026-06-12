import SwiftUI

struct FacultyApprovalsListView: View {
    @Environment(AppSession.self) var appSession
    let user: User
    @Binding var selectedEventId: UUID?
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                let relevantApprovals = appSession.approvalStore.approvals.filter { 
                    $0.receiverId == user.id && $0.type != .budget
                }
                
                let groupedApprovals = Dictionary(grouping: relevantApprovals, by: { $0.eventId })
                
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
                } else {
                    VStack(spacing: 16) {
                        ForEach(groupedApprovals.keys.compactMap { $0 }.sorted(by: { id1, id2 in
                            guard let e1 = appSession.eventStore.events.first(where: { $0.id == id1 }),
                                  let e2 = appSession.eventStore.events.first(where: { $0.id == id2 }) else { return false }
                            if Calendar.current.isDate(e1.startDate, inSameDayAs: e2.startDate) {
                                return (e1.startTime ?? Date.distantFuture) < (e2.startTime ?? Date.distantFuture)
                            }
                            return e1.startDate < e2.startDate
                        }), id: \.self) { eventId in
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
        .navigationTitle("Approval Requests")
        .navigationBarTitleDisplayMode(.large)

    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    NavigationStack {
        FacultyApprovalsListView(user: MockData.facultyResource, selectedEventId: .constant(nil))
            .environment(MockData.session(for: .faculty))
    }
}
