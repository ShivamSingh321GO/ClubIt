import SwiftUI

struct AddTaskView: View {
    var initialTask: Tasks? = nil
    @Environment(\.dismiss) var dismiss
    @Environment(AppSession.self) var appSession
    
    enum AssignmentType: String, CaseIterable, Identifiable {
        case myself = "Myself"
        case clubMember = "Club Member"
        case club = "Club"
        var id: String { self.rawValue }
    }
    
    @State private var assignmentType: AssignmentType = .myself
    @State private var selectedOtherClubId: UUID? = nil
    @State private var selectedMemberId: UUID? = nil
    @State private var selectedClubLeadId: UUID? = nil
    @State private var title: String = ""
    @State private var description: String = ""

    @State private var priority: TaskPriority = .low
    @State private var deadline: Date = Date()
    @State private var selectedEventId: UUID? = nil
    
    private var clubMembers: [User] {
        guard let clubId = appSession.currentUser?.clubId else { return [] }
        return appSession.clubStore.allUsers.filter { $0.clubId == clubId && $0.role == .clubMember }
    }
    
    private var availableClubLeads: [User] {
        guard let clubId = selectedOtherClubId else { return [] }
        return appSession.clubStore.allUsers.filter { $0.clubId == clubId && $0.role == .clubLead }
    }
    
    init(initialTask: Tasks? = nil) {
        self.initialTask = initialTask
        if let task = initialTask {
            _title = State(initialValue: task.title)
            _description = State(initialValue: task.description)

            _priority = State(initialValue: task.priority)
            _deadline = State(initialValue: task.deadline)
            _selectedEventId = State(initialValue: task.eventId)
            
            // Map back assignment type
            if let targetId = task.targetClubId {
                _assignmentType = State(initialValue: .club)
                _selectedOtherClubId = State(initialValue: targetId)
                _selectedClubLeadId = State(initialValue: task.assignedTo)
            } else if task.assignedToRole == .clubMember {
                _assignmentType = State(initialValue: .clubMember)
                _selectedMemberId = State(initialValue: task.assignedTo)
            } else {
                _assignmentType = State(initialValue: .myself)
            }
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
                    Picker("Related Event", selection: $selectedEventId) {
                        Text("None / General Task").tag(UUID?.none)
                        
                        let activeEvents = appSession.eventStore.events.filter { 
                            $0.status == .upcoming || $0.status == .ongoing 
                        }
                        
                        ForEach(activeEvents) { event in
                            Text(event.name).tag(UUID?.some(event.id))
                        }
                    }
                }
                
                Section("Assignment") {
                    Picker("Assign To", selection: $assignmentType) {
                        ForEach(AssignmentType.allCases) { type in
                            Text(type.rawValue).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    if assignmentType == .club {
                        Picker("Select Club", selection: $selectedOtherClubId) {
                            Text("Select a club").tag(UUID?.none)
                            ForEach(appSession.clubStore.allClubs) { club in
                                if club.id != appSession.currentUser?.clubId {
                                    Text(club.name).tag(UUID?.some(club.id))
                                }
                            }
                        }
                        .onChange(of: selectedOtherClubId) { oldId, newId in
                            if let newId = newId,
                               let club = appSession.clubStore.allClubs.first(where: { $0.id == newId }) {
                                selectedClubLeadId = club.clubLeadId
                            } else {
                                selectedClubLeadId = nil
                            }
                        }
                        
                        if selectedOtherClubId != nil {
                            Picker("Select Club Lead", selection: $selectedClubLeadId) {
                                Text("Select a lead").tag(UUID?.none)
                                ForEach(availableClubLeads) { lead in
                                    Text(lead.name).tag(UUID?.some(lead.id))
                                }
                            }
                        }
                    }
                    
                    if assignmentType == .clubMember {
                        Picker("Select Member", selection: $selectedMemberId) {
                            Text("Select a member").tag(UUID?.none)
                            ForEach(clubMembers) { member in
                                Text(member.name).tag(UUID?.some(member.id))
                            }
                        }
                    }
                }
                
                Section("Priority & Schedule") {
                    Picker("Priority", selection: $priority) {
                        ForEach(TaskPriority.allCases, id: \.self) { priority in
                            Text(priority.rawValue.capitalized).tag(priority)
                        }
                    }
                    
                    DatePicker("Deadline", selection: $deadline)
                        
                }
            }
            .navigationTitle(initialTask == nil ? "Add Task" : "Edit Task")
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
                        saveTask()
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .disabled(title.isEmpty || (assignmentType == .club && (selectedOtherClubId == nil || selectedClubLeadId == nil)) || (assignmentType == .clubMember && selectedMemberId == nil))
                }
            }
        }
    }
    
    private func saveTask() {
        guard let currentUser = appSession.currentUser else { return }
        
        var assignedToId: UUID = currentUser.id
        var assignedToRole: AppRole = currentUser.role
        var targetClubId: UUID? = nil
        
        switch assignmentType {
        case .myself:
            assignedToId = currentUser.id
            assignedToRole = currentUser.role
        case .clubMember:
            if let memberId = selectedMemberId {
                assignedToId = memberId
                assignedToRole = .clubMember
            }
        case .club:
            if let clubId = selectedOtherClubId,
               let leadId = selectedClubLeadId {
                assignedToId = leadId
                assignedToRole = .clubLead
                targetClubId = clubId
            }
        }
        
        let newTask = Tasks(
            id: initialTask?.id ?? UUID(),
            clubId: currentUser.clubId ?? UUID(),
            targetClubId: targetClubId,
            eventId: selectedEventId,
            title: title,
            description: description,
            assignedBy: currentUser.id,
            assignedByRole: currentUser.role,
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
                    try await appSession.taskStore.editTask(newTask)
                } else {
                    try await appSession.taskStore.addTask(newTask)
                }
                dismiss()
            } catch {
                print("DEBUG ERROR: Save task failed: \(error)")
            }
        }
    }
}

#Preview {
    let session = AppSession()
    session.currentRole = .clubLead
    return AddTaskView()
        .environment(session)
}
