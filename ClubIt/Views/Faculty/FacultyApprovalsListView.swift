import SwiftUI

struct FacultyApprovalsListView: View {
    @Environment(AppSession.self) var appSession
    let user: User
    @Binding var selectedEventId: UUID?
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                let pendingApprovals = appSession.approvalStore.approvals.filter { 
                    $0.receiverId == user.id && $0.status == .pending && $0.type != .budget
                }
                
                let groupedApprovals = Dictionary(grouping: pendingApprovals, by: { $0.eventId })
                
                if groupedApprovals.isEmpty {
                    VStack(spacing: 20) {
                        Image(systemName: "checkmark.seal.fill")
                            .font(.system(size: 60))
                            .foregroundColor(.green.opacity(0.5))
                        
                        Text("You're All Caught Up!")
                            .font(.title2.bold())
                        
                        Text("No pending event approval requests at the moment.")
                            .multilineTextAlignment(.center)
                            .foregroundColor(.secondary)
                    }
                    .padding(40)
                    .frame(maxWidth: .infinity)
                    .glassEffect(in: .rect(cornerRadius: 30))
                    .padding(.top, 40)
                } else {
                    VStack(spacing: 16) {
                        ForEach(groupedApprovals.keys.sorted(by: { $0.uuidString < $1.uuidString }), id: \.self) { eventId in
                            if let event = appSession.eventStore.events.first(where: { $0.id == eventId }) {
                                let _ = groupedApprovals[eventId] ?? []
                                ApprovalSummaryCard(
                                    title: event.name,
                                    subtitle: "Event Request • \(formatDate(event.createdAt))",
                                    action: { selectedEventId = eventId }
                                )
                            }
                        }
                    }
                }
            }
            .padding()
        }
        .navigationTitle("Pending Approvals")
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
