import SwiftUI
import ClubItShared

struct DelegateTaskView: View {
    let task: Tasks
    @Environment(\.dismiss) var dismiss
    @Environment(AppSession.self) var appSession
    
    @State private var selectedMemberId: UUID? = nil
    @State private var selectedOtherClubId: UUID? = nil
    
    private var isPresidentOrVP: Bool {
        let role = appSession.currentRole ?? .subGroupMember
        return role == .groupLead || role == .groupSubLead
    }
    
    private var availableClubs: [Club] {
        return appSession.clubStore.allClubs.filter { $0.id != appSession.currentUser?.clubId }
    }
    
    private var availableClubLeads: [User] {
        guard let clubId = selectedOtherClubId else { return [] }
        return appSession.clubStore.allUsers.filter { $0.clubId == clubId && $0.role == .subGroupLead }
    }
    
    var clubMembers: [User] {
        // Club Lead delegates to Members in their club
        guard let clubId = appSession.currentUser?.clubId else { return [] }
        return appSession.clubStore.allUsers.filter { $0.clubId == clubId && $0.role == .subGroupMember }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if isPresidentOrVP {
                    Form {
                        Section("Delegate to Club Lead") {
                            optionalNavigationRow(
                                title: "Select Club",
                                selection: $selectedOtherClubId,
                                options: availableClubs.map { $0.id },
                                noneLabel: "Select a club",
                                displayValue: { id in availableClubs.first(where: { $0.id == id })?.name ?? "Unknown" }
                            )
                            .onChange(of: selectedOtherClubId) { _, newValue in
                                if let clubId = newValue {
                                    let leads = appSession.clubStore.allUsers.filter { $0.clubId == clubId && $0.role == .subGroupLead }
                                    if leads.count == 1 {
                                        selectedMemberId = leads.first?.id
                                    } else {
                                        selectedMemberId = nil
                                    }
                                }
                            }
                            
                            if selectedOtherClubId != nil {
                                optionalNavigationRow(
                                    title: "Select Club Lead",
                                    selection: $selectedMemberId,
                                    options: availableClubLeads.map { $0.id },
                                    noneLabel: "Select a lead",
                                    displayValue: { id in availableClubLeads.first(where: { $0.id == id })?.name ?? "Unknown" }
                                )
                            }
                        }
                    }
                } else {
                    List {
                        if clubMembers.isEmpty {
                            Text("No members found in your club")
                                .foregroundStyle(.secondary)
                        } else {
                            Section("Select Member to Delegate") {
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
    
    private func optionalNavigationRow<T: Hashable>(title: String, selection: Binding<T?>, options: [T], noneLabel: String, displayValue: @escaping (T) -> String) -> some View {
        NavigationLink {
            OptionalSelectionListView(title: title, selection: selection, options: options, noneLabel: noneLabel, displayValue: displayValue)
        } label: {
            HStack {
                Text(title).foregroundStyle(.primary)
                Spacer()
                Text(selection.wrappedValue.map(displayValue) ?? noneLabel).foregroundStyle(.secondary)
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
        assignedByRole: AppRole.subGroupLead,
        assignedTo: MockData.clubLeadUser.id,
        assignedToRole: AppRole.subGroupLead,
        deadline: Date(),
        priority: .high,
        status: .pending,
        createdAt: Date()
    )
    
    return DelegateTaskView(task: sampleTask)
        .environment(session)
}
