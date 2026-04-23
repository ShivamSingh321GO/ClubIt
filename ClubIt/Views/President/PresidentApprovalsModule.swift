import SwiftUI

struct PresidentApprovalsModule: View {
    @Environment(AppSession.self) var appSession
    let user: User
    let onSelect: (UUID) -> Void

    var body: some View {
        let incomingApprovals = appSession.approvalStore.approvals.filter { approval in
            // For President, we specifically only handle budget approvals
            (approval.receiverId == user.id || appSession.currentRole == .president) &&
            approval.status == .pending &&
            approval.type == .budget &&
            appSession.eventStore.events.contains(where: { $0.id == approval.eventId })
        }
        
        VStack(alignment: .leading, spacing: 16) {
            if incomingApprovals.isEmpty {
                Text("No pending approval requests")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .glassEffect(in: .rect(cornerRadius: 20))
            } else {
                VStack(spacing: 16) {
                    ForEach(incomingApprovals.prefix(2), id: \.id) { approval in
                        if let event = appSession.eventStore.events.first(where: { $0.id == approval.eventId }),
                           let club = appSession.clubStore.allClubs.first(where: { $0.id == event.clubId }) {
                            PresidentApprovalCard(
                                eventName: event.name,
                                clubName: club.name,
                                timeAgo: formatDate(approval.createdAt),
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

struct PresidentApprovalCard: View {
    let eventName: String
    let clubName: String
    let timeAgo: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack(spacing: 6) {
                            Image(systemName: "calendar.badge.clock")
                                .font(.caption2)
                                .foregroundColor(.orange)
                            Text("Budget Approval")
                                .font(.caption2.bold())
                                .foregroundColor(.orange)
                        }
                        
                        Text(eventName)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        Text("by \(clubName) • \(timeAgo)")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .glassEffect(in: .rect(cornerRadius: 20))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    let session = MockData.session(for: .president)
    return PresidentApprovalsModule(user: session.currentUser ?? MockData.studentUser) { _ in }
        .environment(session)
        .padding()
}
