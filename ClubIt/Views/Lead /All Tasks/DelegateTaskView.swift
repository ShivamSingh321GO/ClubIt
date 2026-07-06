import SwiftUI
import ClubItShared

struct DelegateTaskView: View {
    let task: Tasks
    @Environment(\.dismiss) var dismiss
    @Environment(AppSession.self) var appSession
    
    @State private var selectedMemberId: UUID? = nil
    @State private var selectedOtherSubgroupId: UUID? = nil
    
    private var isPresidentOrVP: Bool {
        let role = appSession.currentRole ?? .subGroupMember
        return role == .groupLead || role == .groupSubLead
    }
    
    private var availableSubgroups: [Subgroup] {
        return appSession.subgroupStore.allSubgroups.filter { $0.id != appSession.currentUser?.subgroupId && $0.parentSubgroupId == nil }
    }
    
    private var availableSubgroupLeads: [User] {
        guard let subgroupId = selectedOtherSubgroupId else { return [] }
        return appSession.subgroupStore.allUsers.filter { $0.subgroupId == subgroupId && $0.role == .subGroupLead }
    }
    
    var subgroupMembers: [User] {
        // Subgroup Lead delegates to Members in their subgroup
        guard let subgroupId = appSession.currentUser?.subgroupId else { return [] }
        return appSession.subgroupStore.allUsers.filter { $0.subgroupId == subgroupId && $0.role == .subGroupMember }
    }
    
    var body: some View {
        NavigationStack {
            Group {
                if isPresidentOrVP {
                    Form {
                        let subgroupName = appSession.subgroupStore.levelName(for: 2, defaultName: "Subgroup")
                        Section("Delegate to \(subgroupName) Lead") {
                            optionalNavigationRow(
                                title: "Select \(subgroupName)",
                                selection: $selectedOtherSubgroupId,
                                options: availableSubgroups.map { $0.id },
                                noneLabel: "Select a \(subgroupName.lowercased())",
                                displayValue: { id in availableSubgroups.first(where: { $0.id == id })?.name ?? "Unknown" }
                            )
                            .onChange(of: selectedOtherSubgroupId) { _, newValue in
                                if let subgroupId = newValue {
                                    let leads = appSession.subgroupStore.allUsers.filter { $0.subgroupId == subgroupId && $0.role == .subGroupLead }
                                    if leads.count == 1 {
                                        selectedMemberId = leads.first?.id
                                    } else {
                                        selectedMemberId = nil
                                    }
                                }
                            }
                            
                            if selectedOtherSubgroupId != nil {
                                optionalNavigationRow(
                                    title: "Select \(subgroupName) Lead",
                                    selection: $selectedMemberId,
                                    options: availableSubgroupLeads.map { $0.id },
                                    noneLabel: "Select a lead",
                                    displayValue: { id in availableSubgroupLeads.first(where: { $0.id == id })?.name ?? "Unknown" }
                                )
                            }
                        }
                    }
                } else {
                    List {
                        let subgroupName = appSession.subgroupStore.levelName(for: 2, defaultName: "Subgroup")
                        if subgroupMembers.isEmpty {
                            Text("No members found in your \(subgroupName.lowercased())")
                                .foregroundStyle(.secondary)
                        } else {
                            Section("Select Member to Delegate") {
                                ForEach(subgroupMembers) { member in
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
    session.currentUser = MockData.subgroupLeadUser
    
    let sampleTask = Tasks(id: UUID(), subgroupId: MockData.tj_id,
        targetSubgroupId: nil,
        eventId: nil,
        title: "Test Task",
        description: "Test Description",
        assignedBy: UUID(),
        assignedByRole: AppRole.subGroupLead,
        assignedTo: MockData.subgroupLeadUser.id,
        assignedToRole: AppRole.subGroupLead,
        deadline: Date(),
        priority: .high,
        status: .pending,
        createdAt: Date()
    )
    
    return DelegateTaskView(task: sampleTask)
        .environment(session)
}
