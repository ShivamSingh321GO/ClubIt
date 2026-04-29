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
    
    // State properties
    @State private var assignmentType: AssignmentType = .myself
    @State private var selectedOtherClubId: UUID? = nil
    @State private var selectedMemberId: UUID? = nil
    @State private var selectedClubLeadId: UUID? = nil
    @State private var title: String = ""
    @State private var description: String = ""
    @State private var priority: TaskPriority = .low
    @State private var deadline: Date = Date()
    @State private var selectedEventId: UUID? = nil
    
    // Track initialization to avoid infinite loops
    @State private var isFirstAppear = true
    
    private var clubMembers: [User] {
        guard let clubId = appSession.currentUser?.clubId else { return [] }
        return appSession.clubStore.allUsers.filter { $0.clubId == clubId && $0.role == .clubMember }
    }
    
    private var availableClubLeads: [User] {
        guard let clubId = selectedOtherClubId else { return [] }
        return appSession.clubStore.allUsers.filter { $0.clubId == clubId && $0.role == .clubLead }
    }
    
    private var filteredEvents: [Event] {
        guard let clubId = appSession.currentUser?.clubId else { return [] }
        return appSession.eventStore.events.filter { 
            $0.clubId == clubId && $0.status == .approved 
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
                    // Using .menu style for better response in sheets
                    Picker("Related Event", selection: $selectedEventId) {
                        Text("None / General Task").tag(UUID?.none)
                        ForEach(filteredEvents) { event in
                            Text(event.name).tag(UUID?.some(event.id))
                        }
                    }
                    .pickerStyle(.menu)
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
                        .pickerStyle(.menu)
                        .onChange(of: selectedOtherClubId) { _, newValue in
                            if let clubId = newValue {
                                selectedClubLeadId = appSession.clubStore.allClubs.first(where: { $0.id == clubId })?.clubLeadId
                            }
                        }
                        
                        if selectedOtherClubId != nil {
                            Picker("Select Club Lead", selection: $selectedClubLeadId) {
                                Text("Select a lead").tag(UUID?.none)
                                ForEach(availableClubLeads) { lead in
                                    Text(lead.name).tag(UUID?.some(lead.id))
                                }
                            }
                            .pickerStyle(.menu)
                        }
                    }
                    
                    if assignmentType == .clubMember {
                        Picker("Select Member", selection: $selectedMemberId) {
                            Text("Select a member").tag(UUID?.none)
                            ForEach(clubMembers) { member in
                                Text(member.name).tag(UUID?.some(member.id))
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
                
                Section("Priority & Schedule") {
                    Picker("Priority", selection: $priority) {
                        ForEach(TaskPriority.allCases, id: \.self) { p in
                            Text(p.rawValue.capitalized).tag(p)
                        }
                    }
                    .pickerStyle(.menu)
                    
                    DatePicker("Deadline", selection: $deadline)
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
            if let memberId = selectedMemberId {
                assignedToId = memberId
                assignedToRole = .clubMember
            }
        case .club:
            if let clubId = selectedOtherClubId, let leadId = selectedClubLeadId {
                assignedToId = leadId
                assignedToRole = .clubLead
                targetClubId = clubId
            }
        }
        
        let taskToSave = Tasks(
            id: initialTask?.id ?? UUID(),
            clubId: currentUser.clubId ?? UUID(),
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
