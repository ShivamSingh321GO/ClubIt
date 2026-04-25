import SwiftUI

struct TaskDetailView: View {
    let task: Tasks
    @Environment(\.dismiss) var dismiss
    @Environment(AppSession.self) var appSession
    
    @State private var showingEditTask = false
    @State private var showingDelegateSheet = false
    @State private var selectedEvent: Event? = nil
    @State private var showDeleteAlert = false
    
    private var assignerName: String {
        MockData.allMockUsers.first(where: { $0.id == task.assignedBy })?.name ?? "Unknown"
    }
    
    private var assigneeName: String {
        if task.assignedTo == appSession.currentUser?.id { return "You" }
        return MockData.allMockUsers.first(where: { $0.id == task.assignedTo })?.name ?? "Unknown"
    }
    
    private var delegatedName: String? {
        task.delegatedToName
    }
    
    private var associatedEvent: Event? {
        appSession.eventStore.events.first(where: { $0.id == task.eventId })
    }
    
    private var canDelegate: Bool {
        let isAssignee = appSession.currentUser?.id == task.assignedTo
        let isLeadOrPresident = appSession.currentUser?.role == .clubLead || appSession.currentUser?.role == .president
        return isAssignee && isLeadOrPresident && task.delegatedToId == nil
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    // Header Card (Title and Badges)
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            priorityBadge
                            Spacer()
                            statusBadge
                        }
                        
                        Text(task.title)
                            .font(.title2)
                            .bold()
                            .foregroundStyle(.primary)
                    }
                    .padding(20)
                    .glassEffect(in: .rect(cornerRadius: 24))
                    
                    // Description Section
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Description", systemImage: "doc.text.fill")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        
                        Text(task.description)
                            .font(.body)
                            .lineSpacing(4)
                            .padding(20)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .glassEffect(in: .rect(cornerRadius: 24))
                        
                        // Dates immediately under description
                        HStack(spacing: 16) {
                            attributeCard(title: "Deadline", value: formattedDate(task.deadline), icon: "calendar")
                            attributeCard(title: "Created", value: formattedDate(task.createdAt), icon: "plus.circle")
                        }
                    }
                    
                    // Assignment Section
                    VStack(alignment: .leading, spacing: 12) {
                        Label("Assignment History", systemImage: "clock.arrow.2.circlepath")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        
                        VStack(alignment: .leading, spacing: 0) {
                            if task.assignedBy == task.assignedTo {
                                // Self Assigned Flow
                                HStack {
                                    let displayName = task.assignedBy == appSession.currentUser?.id ? "\(assignerName) (You)" : assignerName
                                    historyRow(name: displayName, role: task.assignedToRole.rawValue, icon: "person.circle.fill", isSource: true, isCurrent: delegatedName == nil)
                                    
                                    if canDelegate {
                                        Spacer()
                                        Button("Delegate") {
                                            showingDelegateSheet = true
                                        }
                                        .font(.caption.bold())
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(.blue.opacity(0.1))
                                        .foregroundStyle(.blue)
                                        .clipShape(Capsule())
                                    }
                                }
                                
                                if let delegated = delegatedName {
                                    lineConnector()
                                    historyRow(name: delegated, role: "Club Member", icon: "person.circle.fill", isCurrent: true, isDelegated: true)
                                }
                            } else {
                                // Standard Assignment Flow
                                historyRow(name: assignerName, role: task.assignedByRole.rawValue, icon: "person.circle.fill", isSource: true)
                                
                                lineConnector()
                                
                                HStack {
                                    historyRow(name: assigneeName, role: task.assignedToRole.rawValue, icon: "person.circle.fill", isCurrent: delegatedName == nil)
                                    
                                    if canDelegate {
                                        Spacer()
                                        Button("Delegate") {
                                            showingDelegateSheet = true
                                        }
                                        .font(.caption.bold())
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(.blue.opacity(0.1))
                                        .foregroundStyle(.blue)
                                        .clipShape(Capsule())
                                    }
                                }
                                
                                if let delegated = delegatedName {
                                    lineConnector()
                                    historyRow(name: delegated, role: "Club Member", icon: "person.circle.fill", isCurrent: true, isDelegated: true)
                                }
                            }
                        }
                        .padding(20)
                        .glassEffect(in: .rect(cornerRadius: 24))
                    }
                    
                    // Event Context
                    if let event = associatedEvent {
                        VStack(alignment: .leading, spacing: 8) {
                            Label("Related Event", systemImage: "calendar")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            
                            Button {
                                selectedEvent = event
                            } label: {
                                HStack(spacing: 16) {
                                    Image(systemName: "calendar.badge.clock")
                                        .font(.title2)
                                        .foregroundStyle(.blue)
                                        .frame(width: 44, height: 44)
                                        .background(.blue.opacity(0.1))
                                        .clipShape(Circle())
                                    
                                    VStack(alignment: .leading, spacing: 2) {
                                        Text(event.name)
                                            .font(.headline)
                                        Text(event.category.rawValue)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(16)
                                .glassEffect(in: .rect(cornerRadius: 20))
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    
                    // Mark as Complete Button
                    if (task.assignedTo == appSession.currentUser?.id || task.delegatedToId == appSession.currentUser?.id) && task.status != .completed {
                        Button {
                            appSession.taskStore.updateTaskStatus(id: task.id, status: .completed)
                            dismiss()
                        } label: {
                            Text("Mark as Complete")
                                .font(.headline)
                                .bold()
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.blue)
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        .padding(.top, 10)
                        .padding(.bottom, 20)
                    }
                }
                .padding(.horizontal)
                
            }
            .alert("Delete Task", isPresented: $showDeleteAlert, actions: {
                Button("Cancel", role: .cancel) {
                    dismiss()
                }
                Button("Delete", role: .destructive) {
                    appSession.taskStore.deleteTask(id: task.id)
                    dismiss()
                }
            }, message: {
                Text("Are you sure you want to delete this task? This action cannot be undone.")
            })
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if task.assignedBy == appSession.currentUser?.id {
                        Button {
                            showDeleteAlert = true
//                            appSession.taskStore.deleteTask(id: task.id)
//                            dismiss()
                        } label: {
                            Text("Delete")
                                .foregroundStyle(.red)
                        }
                        
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    if task.assignedBy == appSession.currentUser?.id {
                        Button("Edit") {
                            showingEditTask = true
                        }
                    } else {
                        Button {
                            dismiss()
                        } label: {
                            Image(systemName: "checkmark")
                        }
                    }
                }
            }
//            .padding(.top, 20)
            .sheet(isPresented: $showingEditTask) {
                AddTaskView(initialTask: task)
            }
            .sheet(isPresented: $showingDelegateSheet) {
                DelegateTaskView(task: task)
            }
            .navigationDestination(item: $selectedEvent) { event in
                EventDetailView(event: event, isMyEvent: event.clubId == appSession.currentUser?.clubId)
            }
        }
    }
    
    // MARK: - Components
    
    private func historyRow(name: String, role: String, icon: String, isSource: Bool = false, isCurrent: Bool = false, isDelegated: Bool = false) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(isSource ? .blue : (isCurrent ? .green : .secondary))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(name)
                    .font(.subheadline)
                    .fontWeight(.bold)
                Text(role)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            
            Spacer()
            
        }
    }
    
    private func lineConnector() -> some View {
        Rectangle()
            .fill(.secondary.opacity(0.3))
            .frame(width: 2, height: 20)
            .padding(.leading, 10)
    }
    
    private func attributeCard(title: String, value: String, icon: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(title, systemImage: icon)
                .font(.caption)
                .foregroundStyle(.secondary)
            Text(value)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .glassEffect(in: .rect(cornerRadius: 20))
    }
    
    private var priorityBadge: some View {
        Text(task.priority.rawValue.uppercased())
            .font(.caption2)
            .bold()
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(task.priority == .high ? .red.opacity(0.2) : .orange.opacity(0.2))
            .foregroundStyle(task.priority == .high ? .red : .orange)
            .clipShape(Capsule())
    }
    
    private var statusBadge: some View {
        Text(task.status.rawValue.uppercased())
            .font(.caption2)
            .bold()
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(.secondary.opacity(0.2))
            .foregroundStyle(.secondary)
            .clipShape(Capsule())
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
