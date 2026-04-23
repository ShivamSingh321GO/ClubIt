import SwiftUI

struct DelegateTaskView: View {
    let task: Tasks
    @Environment(\.dismiss) var dismiss
    @Environment(AppSession.self) var appSession
    
    @State private var selectedMemberId: UUID? = nil
    
    var clubMembers: [User] {
        if appSession.currentRole == .president {
            // President delegates to Club Leads
            return MockData.allMockUsers.filter { $0.role == .clubLead }
        } else {
            // Club Lead delegates to Members in their club
            guard let clubId = appSession.currentUser?.clubId else { return [] }
            return MockData.allMockUsers.filter { $0.clubId == clubId && $0.role == .clubMember }
        }
    }
    
    var delegationTargetTitle: String {
        appSession.currentRole == .president ? "Select Lead to Delegate" : "Select Member to Delegate"
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
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        if let memberId = selectedMemberId,
                           let member = clubMembers.first(where: { $0.id == memberId }) {
                            appSession.taskStore.delegateTask(taskId: task.id, memberId: memberId, memberName: member.name)
                            dismiss()
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
    
    let sampleTask = Tasks(
        clubId: MockData.tj_id,
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
