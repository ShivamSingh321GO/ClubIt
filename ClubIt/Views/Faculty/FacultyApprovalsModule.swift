import SwiftUI

struct FacultyApprovalsModule: View {
    @Environment(AppSession.self) var appSession
    let user: User
    
    var body: some View {
        let assignedClubIds = Set(appSession.clubStore.allClubs.filter { $0.facultyId == user.id }.map { $0.id })
        let eventsWithApprovals = appSession.eventStore.events.filter { event in
            assignedClubIds.contains(event.clubId) && (
                appSession.approvalStore.approvals.contains { $0.eventId == event.id } ||
                appSession.approvalStore.resources.contains { $0.eventId == event.id } ||
                appSession.approvalStore.budgets.contains { $0.eventId == event.id }
            )
        }.sorted(by: { $0.createdAt > $1.createdAt })
        
        VStack(alignment: .leading, spacing: 16) {
            if eventsWithApprovals.isEmpty {
                Text("No approval requests")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
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
    let session = MockData.session(for: .faculty)
    FacultyApprovalsModule(user: session.currentUser ?? MockData.studentUser)
        .environment(session)
        .padding()
}
