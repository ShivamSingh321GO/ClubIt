import SwiftUI
import ClubItShared

struct PresidentApprovalsModule: View {
    @Environment(AppSession.self) var appSession
    let user: User

    var body: some View {
        let eventsWithApprovals = appSession.eventStore.events.filter { event in
            appSession.approvalStore.approvals.contains { 
                $0.eventId == event.id && 
                $0.type == .budget && 
                $0.receiverId == user.id && 
                $0.status == .pending
            }
        }.sorted(by: { $0.startDate > $1.startDate })
        
        VStack(alignment: .leading, spacing: 16) {
            if eventsWithApprovals.isEmpty {
                Text("No budget requests")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 32)
                    .glassEffect(in: .rect(cornerRadius: 20))
            } else {
                VStack(spacing: 16) {
                    ForEach(eventsWithApprovals.prefix(2)) { event in

                        if let club = appSession.clubStore.allClubs.first(where: { $0.id == event.clubId }) {
                            NavigationLink(destination: EventManagementApprovalDetailView(club: club, event: event)) {
                                EventManagementEventApprovalCard(event: event, club: club)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    let session = MockData.session(for: .groupLead)
    return PresidentApprovalsModule(user: session.currentUser ?? MockData.studentUser)
        .environment(session)
        .padding()
}
