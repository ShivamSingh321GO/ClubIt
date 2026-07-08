import SwiftUI
import ClubItShared

struct AddTaskView: View {
    var initialTask: Tasks? = nil
    @Environment(\.dismiss) var dismiss
    @Environment(AppSession.self) var appSession
    
    enum AssignmentType: String, CaseIterable, Identifiable {
        case myself = "Myself"
        case subGroupMember = "SubGroup Member"
        case subgroup = "Subgroup"
        case groupSubLead = "Group SubLead"
        var id: String { self.rawValue }
    }
    
    // State properties
    @State private var assignmentType: AssignmentType = .myself
    @State private var selectedOtherSubgroupId: UUID? = nil
    @State private var selectedMemberId: UUID? = nil
    @State private var selectedSubgroupLeadId: UUID? = nil
    @State private var selectedVicePresidentId: UUID? = nil
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var priority: TaskPriority = .low
    @State private var deadline: Date = Date()
    @State private var selectedEventId: UUID? = nil
    
    // Track initialization to avoid infinite loops
    @State private var isFirstAppear = true
    
    private var subgroupMembers: [User] {
        guard let subgroupId = appSession.currentUserSubgroupId else { return [] }
        return appSession.subgroupStore.allUsers.filter { $0.subgroupId == subgroupId && ($0.role == .subGroupMember || $0.role == .subGroupLead) && $0.id != appSession.currentUser?.id }
    }
    
    private var availableSubgroupLeads: [User] {
        guard let subgroupId = selectedOtherSubgroupId else { return [] }
        return appSession.subgroupStore.allUsers.filter { $0.subgroupId == subgroupId && $0.role == .subGroupLead }
    }
    
    private var vicePresidents: [User] {
        return appSession.subgroupStore.allUsers.filter { $0.role == .groupSubLead && $0.id != appSession.currentUser?.id }
    }
    
    private var filteredEvents: [Event] {
        let isVPApproved: (Event) -> Bool = { event in
            appSession.approvalStore.approvals.contains { 
                $0.eventId == event.id && $0.type == .event && $0.status == .approved 
            }
        }
        if appSession.currentUser?.role == .groupLead {
            return appSession.eventStore.events.filter { 
                $0.status == .approved || $0.status == .published || isVPApproved($0)
            }
        }
        guard let subgroupId = appSession.currentUserSubgroupId else { return [] }
        return appSession.eventStore.events.filter { 
            $0.subgroupId == subgroupId && ($0.status == .approved || $0.status == .published || isVPApproved($0))
        }
    }
    
    private var availableAssignmentTypes: [AssignmentType] {
        let role = appSession.currentUser?.role
        if role == .groupLead {
            return [.myself, .groupSubLead, .subgroup]
        } else if role == .groupSubLead {
            return [.myself, .subgroup]
        } else {
            return [.myself, .subGroupMember, .subgroup]
        }
    }
    
    private func dynamicAssignmentName(for type: AssignmentType) -> String {
        switch type {
        case .myself:
            return "Myself"
        case .subGroupMember:
            let level2Name = appSession.subgroupStore.levelName(for: 2, defaultName: "Subgroup")
            return "\(level2Name) Member"
        case .subgroup:
            let level2Name = appSession.subgroupStore.levelName(for: 2, defaultName: "Subgroup")
            return "Other \(level2Name)"
        case .groupSubLead:
            let level1Name = appSession.subgroupStore.levelName(for: 1, defaultName: "Group")
            return "\(level1Name) SubLead"
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Task Information") {
                    TextField("Title", text: $title)
                    
                    ZStack(alignment: .topLeading) {
                        if description.isEmpty {
                            Text("Description")
                                .foregroundColor(.secondary.opacity(0.5))
                                .padding(.top, 8)
                                .padding(.leading, 5)
                        }
                        TextEditor(text: $description)
                            .frame(minHeight: 120)
                    }
                }
                
                Section("Event Context") {
                    optionalNavigationRow(
                        title: "Related Event",
                        selection: $selectedEventId,
                        options: {
                            var opts = filteredEvents.map { $0.id }
                            if let curr = selectedEventId, !opts.contains(curr) {
                                opts.insert(curr, at: 0)
                            }
                            return opts
                        }(),
                        noneLabel: "None / General Task",
                        displayValue: { id in appSession.eventStore.events.first(where: { $0.id == id })?.name ?? "Unknown" }
                    )
                }
                
                Section("Assignment") {
                    navigationRow(
                        title: "Assign To",
                        selection: $assignmentType,
                        options: availableAssignmentTypes,
                        displayValue: dynamicAssignmentName(for:)
                    )
                    
                    if assignmentType == .subgroup {
                        let subgroupName = appSession.subgroupStore.levelName(for: 2, defaultName: "Subgroup")
                        optionalNavigationRow(
                            title: "Select \(subgroupName)",
                            selection: $selectedOtherSubgroupId,
                            options: appSession.subgroupStore.allSubgroups.filter { $0.id != appSession.currentUser?.subgroupId && $0.parentSubgroupId == nil }.map { $0.id },
                            noneLabel: "Select a \(subgroupName.lowercased())",
                            displayValue: { id in appSession.subgroupStore.allSubgroups.first(where: { $0.id == id })?.name ?? "Unknown" }
                        )
                        .onChange(of: selectedOtherSubgroupId) { _, newValue in
                            if let subgroupId = newValue {
                                selectedSubgroupLeadId = appSession.subgroupStore.allSubgroups.first(where: { $0.id == subgroupId })?.subgroupLeadId
                            }
                        }
                        
                        if selectedOtherSubgroupId != nil {
                            optionalNavigationRow(
                                title: "Select \(subgroupName) Lead",
                                selection: $selectedSubgroupLeadId,
                                options: availableSubgroupLeads.map { $0.id },
                                noneLabel: "Select a lead",
                                displayValue: { id in availableSubgroupLeads.first(where: { $0.id == id })?.name ?? "Unknown" }
                            )
                        }
                    }
                    
                    if assignmentType == .subGroupMember {
                        optionalNavigationRow(
                            title: "Select Member",
                            selection: $selectedMemberId,
                            options: subgroupMembers.map { $0.id },
                            noneLabel: "Select a member",
                            displayValue: { id in subgroupMembers.first(where: { $0.id == id })?.name ?? "Unknown" }
                        )
                    }
                    
                    if assignmentType == .groupSubLead {
                        let groupName = appSession.subgroupStore.levelName(for: 1, defaultName: "Group")
                        optionalNavigationRow(
                            title: "Select \(groupName) SubLead",
                            selection: $selectedVicePresidentId,
                            options: vicePresidents.map { $0.id },
                            noneLabel: "Select a sublead",
                            displayValue: { id in vicePresidents.first(where: { $0.id == id })?.name ?? "Unknown" }
                        )
                    }
                }
                
                Section("Priority & Schedule") {
                    navigationRow(
                        title: "Priority",
                        selection: $priority,
                        options: TaskPriority.allCases,
                        displayValue: { $0.rawValue.capitalized }
                    )
                    
                    DatePicker("Deadline", selection: $deadline, in: Date()...)
                }
            }
            .navigationTitle(initialTask == nil ? "Add Task" : "Edit Task")
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                if isFirstAppear {
                    loadTaskData()
                    isFirstAppear = false
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button { dismiss() } label: { Image(systemName: "xmark") }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button { saveTask() } label: { Image(systemName: "checkmark") }
                    .disabled(title.isEmpty)
                }
            }
        }
    }
    
    private func navigationRow<T: Hashable>(title: String, selection: Binding<T>, options: [T], displayValue: @escaping (T) -> String) -> some View {
        NavigationLink {
            SelectionListView(title: title, selection: selection, options: options, displayValue: displayValue)
        } label: {
            HStack {
                Text(title).foregroundStyle(.primary)
                Spacer()
                Text(displayValue(selection.wrappedValue)).foregroundStyle(.secondary)
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
    
    private func loadTaskData() {
        guard let task = initialTask else { return }
        
        title = task.title
        description = task.description
        priority = task.priority
        deadline = task.deadline
        selectedEventId = task.eventId
        
        if let targetId = task.targetSubgroupId {
            assignmentType = .subgroup
            selectedOtherSubgroupId = targetId
            selectedSubgroupLeadId = task.assignedTo
        } else if task.assignedToRole == .subGroupMember {
            assignmentType = .subGroupMember
            selectedMemberId = task.assignedTo
        } else if task.assignedToRole == .groupSubLead {
            assignmentType = .groupSubLead
            selectedVicePresidentId = task.assignedTo
        } else {
            assignmentType = .myself
        }
    }
    
    private func saveTask() {
        guard let currentUser = appSession.currentUser else { return }
        
        var assignedToId = currentUser.id
        var assignedToRole = currentUser.role
        var targetSubgroupId: UUID? = nil
        
        switch assignmentType {
        case .myself:
            assignedToId = currentUser.id
            assignedToRole = currentUser.role
        case .subGroupMember:
            if let memberId = selectedMemberId,
               let member = appSession.subgroupStore.allUsers.first(where: { $0.id == memberId }) {
                assignedToId = memberId
                assignedToRole = member.role
            }
        case .subgroup:
            if let subgroupId = selectedOtherSubgroupId, let leadId = selectedSubgroupLeadId {
                assignedToId = leadId
                assignedToRole = .subGroupLead
                targetSubgroupId = subgroupId
            }
        case .groupSubLead:
            if let vpId = selectedVicePresidentId,
               let vp = appSession.subgroupStore.allUsers.first(where: { $0.id == vpId }) {
                assignedToId = vpId
                assignedToRole = vp.role
            }
        }
        
        let now = Date()
        let creationDate = initialTask?.createdAt ?? now
        let updatedDate = initialTask != nil ? now : creationDate
        
        let defaultSubgroupId = appSession.subgroupStore.allSubgroups.first?.id ?? UUID()
        let taskToSave = Tasks(
            id: initialTask?.id ?? UUID(),
            subgroupId: targetSubgroupId ?? appSession.currentUserSubgroupId ?? defaultSubgroupId,
            targetSubgroupId: targetSubgroupId,
            eventId: selectedEventId,
            title: title,
            description: description,
            assignedBy: initialTask?.assignedBy ?? currentUser.id,
            assignedByRole: initialTask?.assignedByRole ?? currentUser.role,
            assignedTo: assignedToId,
            assignedToRole: assignedToRole,
            deadline: deadline,
            priority: priority,
            status: initialTask?.status ?? .pending,
            createdAt: creationDate,
            updatedAt: updatedDate
        )
        
        Task {
            do {
                if initialTask != nil {
                    try await appSession.taskStore.editTask(taskToSave)
                } else {
                    try await appSession.taskStore.addTask(taskToSave)
                }
                dismiss()
            } catch {
                print("DEBUG ERROR: Save task failed: \(error)")
            }
        }
    }
}

struct SelectionListView<T: Hashable>: View {
    let title: String
    @Binding var selection: T
    let options: [T]
    let displayValue: (T) -> String
    @Environment(\.dismiss) var dismiss

    var body: some View {
        List {
            ForEach(options, id: \.self) { option in
                Button {
                    selection = option
                    dismiss()
                } label: {
                    HStack {
                        Text(displayValue(option)).foregroundStyle(.primary)
                        Spacer()
                        if selection == option {
                            Image(systemName: "checkmark").foregroundStyle(.blue)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct OptionalSelectionListView<T: Hashable>: View {
    let title: String
    @Binding var selection: T?
    let options: [T]
    let noneLabel: String
    let displayValue: (T) -> String
    @Environment(\.dismiss) var dismiss

    var body: some View {
        List {
            Button {
                selection = nil
                dismiss()
            } label: {
                HStack {
                    Text(noneLabel).foregroundStyle(.primary)
                    Spacer()
                    if selection == nil {
                        Image(systemName: "checkmark").foregroundStyle(.blue)
                    }
                }
            }
            .buttonStyle(.plain)
            ForEach(options, id: \.self) { option in
                Button {
                    selection = option
                    dismiss()
                } label: {
                    HStack {
                        Text(displayValue(option)).foregroundStyle(.primary)
                        Spacer()
                        if selection == option {
                            Image(systemName: "checkmark").foregroundStyle(.blue)
                        }
                    }
                }
                .buttonStyle(.plain)
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
