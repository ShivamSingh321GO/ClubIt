import SwiftUI

struct FacultyApprovalsModule: View {
    @Environment(AppSession.self) var appSession
    let user: User
    
    var body: some View {
        let assignedClubs = appSession.clubStore.allClubs.filter { $0.facultyId == user.id }
        let clubsWithPending = assignedClubs.filter { club in
            let clubEvents = appSession.eventStore.events.filter { $0.clubId == club.id }
            let clubEventIds = Set(clubEvents.map { $0.id })
            
            let hasPendingResources = appSession.approvalStore.resources.contains { 
                clubEventIds.contains($0.eventId) && $0.status == .pending 
            }
            let hasPendingVenues = appSession.approvalStore.approvals.contains {
                clubEventIds.contains($0.eventId) && $0.type == .venue && $0.status == .pending
            }
            
            return hasPendingResources || hasPendingVenues
        }
        
        VStack(alignment: .leading, spacing: 16) {
            if clubsWithPending.isEmpty {
                Text("No pending approval requests")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .glassEffect(in: .rect(cornerRadius: 20))
            } else {
                VStack(spacing: 16) {
                    ForEach(clubsWithPending.prefix(2)) { club in
                        NavigationLink(destination: ClubResourcesDetailView(club: club)) {
                            FacultyClubResourceCard(club: club)
                        }
                        .buttonStyle(.plain)
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
