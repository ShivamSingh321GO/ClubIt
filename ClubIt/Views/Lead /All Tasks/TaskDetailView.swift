import SwiftUI

struct TaskDetailView: View {
    let task: Tasks
    @Environment(\.dismiss) var dismiss
    @Environment(AppSession.self) var appSession
    
    @State private var showingEditTask = false
    @State private var showingDelegateSheet = false
    @State private var selectedEvent: Event? = nil
    @State private var showDeleteAlert = false
    
    private var currentTask: Tasks {
        appSession.taskStore.tasks.first(where: { $0.id == task.id }) ?? task
    }
    
    private var assignerName: String {
        if currentTask.assignedBy == appSession.currentUser?.id { return "You" }
        return appSession.clubStore.allUsers.first(where: { $0.id == currentTask.assignedBy })?.name ?? "Unknown"
    }
    
    private var assigneeName: String {
        if currentTask.assignedTo == appSession.currentUser?.id { return "You" }
        return appSession.clubStore.allUsers.first(where: { $0.id == currentTask.assignedTo })?.name ?? "Unknown"
    }
    
    private var delegatedName: String? {
        guard let id = currentTask.delegatedToId else { return nil }
        return appSession.clubStore.allUsers.first(where: { $0.id == id })?.name
    }
    
    private var associatedEvent: Event? {
        appSession.eventStore.events.first(where: { $0.id == currentTask.eventId })
    }
    
    private var canDelegate: Bool {
        let isAssignee = appSession.currentUser?.id == currentTask.assignedTo
        let isEligibleRole = appSession.currentUser?.role == .clubLead || appSession.currentUser?.role == .president || appSession.currentUser?.role == .vicePresident
        return isAssignee && isEligibleRole && currentTask.delegatedToId == nil
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // Header Section
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 8) {
                            priorityBadge
                            statusBadge
                            Spacer()
                        }
                        
                        Text(currentTask.title)
                            .font(.title2)
                            .bold()
                            .foregroundStyle(.primary)
                            
                        Divider().padding(.top, 12)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    
                    // Description Section
                    VStack(alignment: .leading, spacing: 12) {
                        sectionHeader(title: "Description", icon: "doc.text.fill")
                        
                        Text(currentTask.description)
                            .font(.body)
                            .lineSpacing(4)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            
                        Divider().padding(.top, 12)
                    }
                    .padding(.horizontal, 20)
                    
                    // Timeline Section
                    VStack(alignment: .leading, spacing: 16) {
                        sectionHeader(title: "Timeline", icon: "clock.fill")
                        
                        VStack(spacing: 16) {
                            dateRow(title: "Deadline", date: currentTask.deadline, icon: "calendar.badge.exclamationmark", color: .orange)
                            dateRow(title: "Created", date: currentTask.createdAt, icon: "plus.circle.fill", color: .green)
                        }
                        
                        Divider().padding(.top, 8)
                    }
                    .padding(.horizontal, 20)
                    
                    // Assignment Section
                    VStack(alignment: .leading, spacing: 16) {
                        sectionHeader(title: "Assignment History", icon: "clock.arrow.2.circlepath")
                        
                        VStack(alignment: .leading, spacing: 0) {
                            if currentTask.assignedBy == currentTask.assignedTo {
                                // Self Assigned Flow
                                HStack {
                                    historyRow(name: assignerName, role: currentTask.assignedToRole.rawValue, icon: "person.circle.fill", isSource: true, isCurrent: delegatedName == nil)
                                    
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
                                historyRow(name: assignerName, role: currentTask.assignedByRole.rawValue, icon: "person.circle.fill", isSource: true)
                                
                                lineConnector()
                                
                                HStack {
                                    historyRow(name: assigneeName, role: currentTask.assignedToRole.rawValue, icon: "person.circle.fill", isCurrent: delegatedName == nil)
                                    
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
                        
                        if associatedEvent != nil {
                            Divider().padding(.top, 8)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Event Context
                    if let event = associatedEvent {
                        VStack(alignment: .leading, spacing: 12) {
                            sectionHeader(title: "Related Event", icon: "calendar")
                            
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
                                            .foregroundStyle(.primary)
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
                                .contentShape(Rectangle())
                                .background(Color(.secondarySystemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.horizontal, 20)
                    }
                    
                    // Mark as Complete Button
                    if (currentTask.assignedTo == appSession.currentUser?.id || currentTask.delegatedToId == appSession.currentUser?.id) && currentTask.status != .completed {
                        Button {
                            Task {
                                do {
                                    try await appSession.taskStore.updateTaskStatus(id: currentTask.id, status: .completed)
                                    appSession.selectedTask = nil
                                    dismiss()
                                } catch {
                                    print("DEBUG ERROR: Status update failed: \(error)")
                                }
                            }
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
                        .padding(.horizontal, 20)
                        .padding(.top, 10)
                        .padding(.bottom, 20)
                    }
                    
                    Spacer(minLength: 40)
                }
            }
            .background(Color(.systemBackground))
            .alert("Delete Task", isPresented: $showDeleteAlert, actions: {
                Button("Cancel", role: .cancel) {
                    // Do nothing, just close the alert
                }
                Button("Delete", role: .destructive) {
                    Task {
                        do {
                            try await appSession.taskStore.deleteTask(id: currentTask.id)
                            appSession.selectedTask = nil
                            dismiss()
                        } catch {
                            print("DEBUG ERROR: Deletion failed: \(error)")
                        }
                    }
                }
            }, message: {
                Text("Are you sure you want to delete this task? This action cannot be undone.")
            })
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    if currentTask.assignedBy == appSession.currentUser?.id {
                        Button {
                            showDeleteAlert = true
                        } label: {
                            Text("Delete")
                                .foregroundStyle(.red)
                        }
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    if currentTask.assignedBy == appSession.currentUser?.id {
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
            .sheet(isPresented: $showingEditTask) {
                AddTaskView(initialTask: currentTask)
            }
            .sheet(isPresented: $showingDelegateSheet) {
                DelegateTaskView(task: currentTask)
            }
            .navigationDestination(item: $selectedEvent) { event in
                EventDetailView(event: event, isMyEvent: event.clubId == appSession.currentUser?.clubId)
            }
        }
    }
    
    // MARK: - Components
    
    private func sectionHeader(title: String, icon: String) -> some View {
        Label(title.uppercased(), systemImage: icon)
            .font(.footnote)
            .fontWeight(.semibold)
            .foregroundStyle(.secondary)
    }
    
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
    
    private func dateRow(title: String, date: Date, icon: String, color: Color) -> some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 44, height: 44)
                .background(color.opacity(0.1))
                .clipShape(Circle())
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(formattedDate(date))
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.primary)
            }
            Spacer()
        }
    }
    
    private var priorityBadge: some View {
        Text(currentTask.priority.rawValue.uppercased())
            .font(.caption2)
            .bold()
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(currentTask.priority == .high ? .red.opacity(0.2) : .orange.opacity(0.2))
            .foregroundStyle(currentTask.priority == .high ? .red : .orange)
            .clipShape(Capsule())
    }
    
    private var statusColor: Color {
        switch currentTask.status {
        case .pending: return .orange
        case .inProgress: return .blue
        case .completed: return .green
        }
    }
    
    private var statusBadge: some View {
        Text(currentTask.status.rawValue.uppercased())
            .font(.caption2)
            .bold()
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(statusColor.opacity(0.2))
            .foregroundStyle(statusColor)
            .clipShape(Capsule())
    }
    
    private func formattedDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}
