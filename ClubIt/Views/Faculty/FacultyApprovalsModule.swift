import SwiftUI
import ClubItShared

struct FacultyApprovalsModule: View {
    @Environment(AppSession.self) var appSession
    let user: User
    
    var body: some View {
        let assignedSubgroupIds = Set(appSession.subgroupStore.allSubgroups.filter { $0.facultyId == user.id }.map { $0.id })
        let eventsWithApprovals = appSession.eventStore.events.filter { event in
            appSession.approvalStore.approvals.contains { 
                $0.eventId == event.id && 
                ($0.type == .venue || $0.type == .resource || $0.type == .event) && 
                $0.receiverId == user.id && 
                $0.status == .pending
            }
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

                        if let subgroup = appSession.subgroupStore.allSubgroups.first(where: { $0.id == event.subgroupId }) {
                            NavigationLink(destination: EventManagementApprovalDetailView(subgroup: subgroup, event: event)) {
                                EventManagementEventApprovalCard(event: event, subgroup: subgroup)
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
    let session = MockData.session(for: .groupSubLead)
    FacultyApprovalsModule(user: session.currentUser ?? MockData.studentUser)
        .environment(session)
        .padding()
}
