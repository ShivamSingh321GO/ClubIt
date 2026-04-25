import SwiftUI

struct AddTaskView: View {
    var initialTask: Tasks? = nil
    @Environment(\.dismiss) var dismiss
    @Environment(AppSession.self) var appSession
    
    enum AssignmentType: String, CaseIterable, Identifiable {
        case myself = "Myself"
        case clubMember = "Club Member"
        case club = "Club"
        case president = "President"
        case vicePresident = "Vice President"
        var id: String { self.rawValue }
    }
    
    @State private var assignmentType: AssignmentType = .myself
    @State private var selectedOtherClubId: UUID? = nil
    @State private var selectedMemberId: UUID? = nil
    @State private var selectedClubLeadId: UUID? = nil
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var selectedClub: ClubOption = .technoJam
    @State private var selectedAssignee: AssigneeOption = .aryan
    @State private var priority: TaskPriority = .low
    @State private var deadline: Date = Date()
    @State private var selectedEventId: UUID? = nil
    
    private var clubMembers: [User] {
        guard let clubId = appSession.currentUser?.clubId else { return [] }
        return MockData.allMockUsers.filter { $0.clubId == clubId && $0.role == .clubMember }
    }
    
    private var availableClubLeads: [User] {
        guard let clubId = selectedOtherClubId else { return [] }
        return MockData.allMockUsers.filter { $0.clubId == clubId && $0.role == .clubLead }
    }
    
    init(initialTask: Tasks? = nil) {
        self.initialTask = initialTask
        if let task = initialTask {
            _title = State(initialValue: task.title)
            _description = State(initialValue: task.description)
            _selectedClub = State(initialValue: ClubOption.from(uuid: task.clubId))
            _selectedAssignee = State(initialValue: AssigneeOption.from(uuid: task.assignedTo))
            _priority = State(initialValue: task.priority)
            _deadline = State(initialValue: task.deadline)
            _selectedEventId = State(initialValue: task.eventId)
            
            // Map back assignment type
            if task.assignedToRole == .president {
                _assignmentType = State(initialValue: .president)
            } else if task.assignedToRole == .vicePresident {
                _assignmentType = State(initialValue: .vicePresident)
            } else if let targetId = task.targetClubId {
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
                            if appSession.currentUser?.role == .clubLead {
                                // Leads can assign to self, members, or other clubs
                                if type == .myself || type == .clubMember || type == .club {
                                    Text(type.rawValue).tag(type)
                                }
                            } else if appSession.currentUser?.role == .president || appSession.currentUser?.role == .vicePresident {
                                // President/VP can assign to self or clubs
                                if type == .myself || type == .club {
                                    Text(type.rawValue).tag(type)
                                }
                            }
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    if assignmentType == .club {
                        Picker("Select Club", selection: $selectedOtherClubId) {
                            Text("Select a club").tag(UUID?.none)
                            ForEach(MockData.allClubs) { club in
                                if club.id != appSession.currentUser?.clubId {
                                    Text(club.name).tag(UUID?.some(club.id))
                                }
                            }
                        }
                        .onChange(of: selectedOtherClubId) { oldId, newId in
                            if let newId = newId,
                               let club = MockData.allClubs.first(where: { $0.id == newId }) {
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
                    
                    if assignmentType == .president {
                        Text("Assigning to University President")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    
                    if assignmentType == .vicePresident {
                        Text("Assigning to University Vice President")
                            .font(.caption)
                            .foregroundStyle(.secondary)
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
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.headline)
                            .foregroundColor(.primary)
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        saveTask()
                    } label: {
                        Image(systemName: "checkmark")
                            .font(.headline)
                            .foregroundColor(.blue)
                    }
                    .buttonStyle(.plain)
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
        case .president:
            if let president = MockData.allMockUsers.first(where: { $0.role == .president }) {
                assignedToId = president.id
                assignedToRole = .president
            }
        case .vicePresident:
            if let vicePresident = MockData.allMockUsers.first(where: { $0.role == .vicePresident }) {
                assignedToId = vicePresident.id
                assignedToRole = .vicePresident
            }
        }
        
        if let task = initialTask {
            appSession.taskStore.editTask(
                id: task.id,
                title: title,
                description: description,
                clubId: currentUser.clubId ?? UUID(),
                targetClubId: targetClubId,
                eventId: selectedEventId,
                assignedTo: assignedToId,
                assignedToRole: assignedToRole,
                priority: priority,
                deadline: deadline
            )
        } else {
            appSession.taskStore.addTask(
                title: title,
                description: description,
                clubId: currentUser.clubId ?? UUID(),
                targetClubId: targetClubId,
                eventId: selectedEventId,
                assignedBy: currentUser.id,
                assignedByRole: currentUser.role,
                assignedTo: assignedToId,
                assignedToRole: assignedToRole,
                priority: priority,
                deadline: deadline
            )
        }
        dismiss()
    }
}

#Preview {
    let session = AppSession()
    session.currentRole = .clubLead
    return AddTaskView()
        .environment(session)
}
