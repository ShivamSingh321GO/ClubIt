import SwiftUI

struct DelegateTaskView: View {
    let task: Tasks
    @Environment(\.dismiss) var dismiss
    @Environment(AppSession.self) var appSession
    
    @State private var selectedMemberId: UUID? = nil
    
    var clubMembers: [User] {
        let role = appSession.currentRole ?? .clubMember
        if role == .president || role == .vicePresident {
            // President/VP delegates to Club Leads
            return appSession.clubStore.allUsers.filter { $0.role == .clubLead }
        } else {
            // Club Lead delegates to Members in their club
            guard let clubId = appSession.currentUser?.clubId else { return [] }
            return appSession.clubStore.allUsers.filter { $0.clubId == clubId && $0.role == .clubMember }
        }
    }
    
    var delegationTargetTitle: String {
        let role = appSession.currentRole ?? .clubMember
        return (role == .president || role == .vicePresident) ? "Select Lead to Delegate" : "Select Member to Delegate"
    }
    
    var body: some View {
        NavigationStack {
            List {
                if clubMembers.isEmpty {
                    Text("No members found in your club")
                        .foregroundStyle(.secondary)
                } else {
                    Section(delegationTargetTitle) {
                        ForEach(clubMembers) { member in
                            Button {
                                selectedMemberId = member.id
                            } label: {
                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(member.name)
                                            .font(.headline)
                                        Text(member.role.rawValue)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    if selectedMemberId == member.id {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.blue)
                                    }
                                }
                            }
                            .foregroundColor(.primary)
                        }
                    }
                }
            }
            .navigationTitle("Delegate Task")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if let memberId = selectedMemberId {
                            Task {
                                do {
                                    try await appSession.taskStore.delegateTask(taskId: task.id, memberId: memberId)
                                    dismiss()
                                } catch {
                                    print("DEBUG ERROR: Delegate task failed: \(error)")
                                }
                            }
                        }
                    } label: {
                        Image(systemName: "checkmark")

                    }
                    .disabled(selectedMemberId == nil)
                }
            }
        }
    }
}

#Preview {
    let session = AppSession()
    session.currentUser = MockData.clubLeadUser
    
    let sampleTask = Tasks(id: UUID(), clubId: MockData.tj_id,
        targetClubId: nil,
        eventId: nil,
        title: "Test Task",
        description: "Test Description",
        assignedBy: UUID(),
        assignedByRole: AppRole.clubLead,
        assignedTo: MockData.clubLeadUser.id,
        assignedToRole: AppRole.clubLead,
        deadline: Date(),
        priority: .high,
        status: .pending,
        createdAt: Date()
    )
    
    return DelegateTaskView(task: sampleTask)
        .environment(session)
}
