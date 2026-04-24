import SwiftUI

struct PresidentApprovalsModule: View {
    @Environment(AppSession.self) var appSession
    let user: User

    var body: some View {
        let allClubs = appSession.clubStore.allClubs
        let clubsWithPending = allClubs.filter { club in
            let clubEvents = appSession.eventStore.events.filter { $0.clubId == club.id }
            let clubEventIds = Set(clubEvents.map { $0.id })
            
            return appSession.approvalStore.budgets.contains { 
                clubEventIds.contains($0.eventId) && $0.status == .pending 
            }
        }
        
        VStack(alignment: .leading, spacing: 16) {
            if clubsWithPending.isEmpty {
                Text("No pending budget requests")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .glassEffect(in: .rect(cornerRadius: 20))
            } else {
                VStack(spacing: 16) {
                    ForEach(clubsWithPending.prefix(2)) { club in
                        NavigationLink(destination: PresidentClubBudgetDetailView(club: club)) {
                            PresidentClubBudgetCard(club: club)
                        }
                        .buttonStyle(.plain)
                    }
                }
            }
        }
    }
}

#Preview {
    let session = MockData.session(for: .president)
    return PresidentApprovalsModule(user: session.currentUser ?? MockData.studentUser)
        .environment(session)
        .padding()
}
