import SwiftUI

struct AddTaskView: View {
    var initialTask: Tasks? = nil
    @Environment(\.dismiss) var dismiss
    @Environment(AppSession.self) var appSession
    
    enum AssignmentType: String, CaseIterable, Identifiable {
        case myself = "Myself"
        case clubMember = "Club Member"
        case club = "Club"
        case vicePresident = "Vice President"
        var id: String { self.rawValue }
    }
    
    // State properties
    @State private var assignmentType: AssignmentType = .myself
    @State private var selectedOtherClubId: UUID? = nil
    @State private var selectedMemberId: UUID? = nil
    @State private var selectedClubLeadId: UUID? = nil
    @State private var selectedVicePresidentId: UUID? = nil
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var priority: TaskPriority = .low
    @State private var deadline: Date = Date()
    @State private var selectedEventId: UUID? = nil
    
    // Track initialization to avoid infinite loops
    @State private var isFirstAppear = true
    
    private var clubMembers: [User] {
        guard let clubId = appSession.currentUserClubId else { return [] }
        return appSession.clubStore.allUsers.filter { $0.clubId == clubId && ($0.role == .clubMember || $0.role == .clubLead) && $0.id != appSession.currentUser?.id }
    }
    
    private var availableClubLeads: [User] {
        guard let clubId = selectedOtherClubId else { return [] }
        return appSession.clubStore.allUsers.filter { $0.clubId == clubId && $0.role == .clubLead }
    }
    
    private var vicePresidents: [User] {
        return appSession.clubStore.allUsers.filter { $0.role == .vicePresident && $0.id != appSession.currentUser?.id }
    }
    
    private var filteredEvents: [Event] {
        if appSession.currentUser?.role == .president {
            return appSession.eventStore.events.filter { $0.status == .approved || $0.status == .published }
        }
        guard let clubId = appSession.currentUserClubId else { return [] }
        return appSession.eventStore.events.filter { 
            $0.clubId == clubId && ($0.status == .approved || $0.status == .published)
        }
    }
    
    private var availableAssignmentTypes: [AssignmentType] {
        let role = appSession.currentUser?.role
        if role == .president {
            return [.myself, .vicePresident, .club]
        } else if role == .vicePresident {
            return [.myself, .club]
        } else {
            return [.myself, .clubMember, .club]
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
                        displayValue: { $0.rawValue }
                    )
                    
                    if assignmentType == .club {
                        optionalNavigationRow(
                            title: "Select Club",
                            selection: $selectedOtherClubId,
                            options: appSession.clubStore.allClubs.filter { $0.id != appSession.currentUser?.clubId }.map { $0.id },
                            noneLabel: "Select a club",
                            displayValue: { id in appSession.clubStore.allClubs.first(where: { $0.id == id })?.name ?? "Unknown" }
                        )
                        .onChange(of: selectedOtherClubId) { _, newValue in
                            if let clubId = newValue {
                                selectedClubLeadId = appSession.clubStore.allClubs.first(where: { $0.id == clubId })?.clubLeadId
                            }
                        }
                        
                        if selectedOtherClubId != nil {
                            optionalNavigationRow(
                                title: "Select Club Lead",
                                selection: $selectedClubLeadId,
                                options: availableClubLeads.map { $0.id },
                                noneLabel: "Select a lead",
                                displayValue: { id in availableClubLeads.first(where: { $0.id == id })?.name ?? "Unknown" }
                            )
                        }
                    }
                    
                    if assignmentType == .clubMember {
                        optionalNavigationRow(
                            title: "Select Member",
                            selection: $selectedMemberId,
                            options: clubMembers.map { $0.id },
                            noneLabel: "Select a member",
                            displayValue: { id in clubMembers.first(where: { $0.id == id })?.name ?? "Unknown" }
                        )
                    }
                    
                    if assignmentType == .vicePresident {
                        optionalNavigationRow(
                            title: "Select Vice President",
                            selection: $selectedVicePresidentId,
                            options: vicePresidents.map { $0.id },
                            noneLabel: "Select a VP",
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
        
        if let targetId = task.targetClubId {
            assignmentType = .club
            selectedOtherClubId = targetId
            selectedClubLeadId = task.assignedTo
        } else if task.assignedToRole == .clubMember {
            assignmentType = .clubMember
            selectedMemberId = task.assignedTo
        } else if task.assignedToRole == .vicePresident {
            assignmentType = .vicePresident
            selectedVicePresidentId = task.assignedTo
        } else {
            assignmentType = .myself
        }
    }
    
    private func saveTask() {
        guard let currentUser = appSession.currentUser else { return }
        
        var assignedToId = currentUser.id
        var assignedToRole = currentUser.role
        var targetClubId: UUID? = nil
        
        switch assignmentType {
        case .myself:
            assignedToId = currentUser.id
            assignedToRole = currentUser.role
        case .clubMember:
            if let memberId = selectedMemberId,
               let member = appSession.clubStore.allUsers.first(where: { $0.id == memberId }) {
                assignedToId = memberId
                assignedToRole = member.role
            }
        case .club:
            if let clubId = selectedOtherClubId, let leadId = selectedClubLeadId {
                assignedToId = leadId
                assignedToRole = .clubLead
                targetClubId = clubId
            }
        case .vicePresident:
            if let vpId = selectedVicePresidentId,
               let vp = appSession.clubStore.allUsers.first(where: { $0.id == vpId }) {
                assignedToId = vpId
                assignedToRole = vp.role
            }
        }
        
        let defaultClubId = appSession.clubStore.allClubs.first?.id ?? UUID()
        let taskToSave = Tasks(
            id: initialTask?.id ?? UUID(),
            clubId: targetClubId ?? appSession.currentUserClubId ?? defaultClubId,
            targetClubId: targetClubId,
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
            createdAt: initialTask?.createdAt ?? Date()
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
            }
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}
