import SwiftUI

struct FacultyApprovalsModule: View {
    @Environment(AppSession.self) var appSession
    let user: User
    
    var body: some View {
        let assignedClubIds = Set(appSession.clubStore.allClubs.filter { $0.facultyId == user.id }.map { $0.id })
        let eventsWithPending = appSession.eventStore.events.filter { event in
            assignedClubIds.contains(event.clubId) && (
                appSession.approvalStore.approvals.contains { $0.eventId == event.id && $0.status == .pending } ||
                appSession.approvalStore.resources.contains { $0.eventId == event.id && $0.status == .pending } ||
                appSession.approvalStore.budgets.contains { $0.eventId == event.id && $0.status == .pending }
            )
        }.sorted(by: { $0.startDate > $1.startDate })
        
        VStack(alignment: .leading, spacing: 16) {
            if eventsWithPending.isEmpty {
                Text("No pending approval requests")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .glassEffect(in: .rect(cornerRadius: 20))
            } else {
                VStack(spacing: 16) {
                    ForEach(eventsWithPending.prefix(2)) { event in
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
