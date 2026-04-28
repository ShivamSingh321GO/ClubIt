import SwiftUI

struct TaskRowView: View {
    @Environment(AppSession.self) var appSession
    let task: Tasks
    var now: Date = Date()
    
    @State private var showingTaskDetail = false
    
    private var associatedEvent: Event? {
        appSession.eventStore.events.first(where: { $0.id == task.eventId })
    }
    
    private var isOverdue: Bool {
        task.status != .completed && task.deadline < now
    }
    
    private var assignerName: String {
        let user = appSession.clubStore.allUsers.first(where: { $0.id == task.assignedBy })
        return user?.name ?? "Unknown"
    }
    
    private var assigneeName: String {
        if task.assignedTo == appSession.currentUser?.id {
            return "You"
        }
        let user = appSession.clubStore.allUsers.first(where: { $0.id == task.assignedTo })
        return user?.name ?? "Unknown"
    }
    
    private var targetClubName: String? {
        guard let targetId = task.targetClubId else { return nil }
        return appSession.clubStore.allClubs.first(where: { $0.id == targetId })?.name
    }
    
    private var assignmentInfo: String {
        if let delegatedId = task.delegatedToId, let delegatedName = appSession.clubStore.allUsers.first(where: { $0.id == delegatedId })?.name {
            // Flow: Assigner -> Delegate (hiding the middleman as requested)
            return "\(assignerName) → \(delegatedName)"
        } else if task.assignedTo == task.assignedBy {
            return "Self Assigned"
        } else if let clubName = targetClubName {
            return "\(assignerName) → \(clubName)"
        } else {
            return "\(assignerName) → \(assigneeName)"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Task Content (Clickable)
            VStack(alignment: .leading, spacing: 10) {
                // Top Tags: Priority and Event
                HStack(spacing: 8) {
                    priorityBadge
                    
                    if let event = associatedEvent {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar.badge.clock")
                                .font(.system(size: 8, weight: .bold))
                            Text(event.name.uppercased())
                                .font(.caption2)
                                .bold()
                        }
                        .foregroundStyle(.blue)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .glassEffect(in: .capsule)
                    }
                }
                
                // Title and Description
                VStack(alignment: .leading, spacing: 4) {
                    Text(task.title)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundStyle(task.status == .completed ? .secondary : .primary)
                        .strikethrough(task.status == .completed)
                    
                    if !task.description.isEmpty {
                        Text(task.description)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .lineLimit(2)
                            .multilineTextAlignment(.leading)
                    }
                }
            }
            // Footer: Assignment Chain and Deadline
            HStack(spacing: 8) {
                // Assignment Chain
                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                        .font(.system(size: 8))
                    Text(assignmentInfo)
                        .font(.system(size: 10, weight: .medium))
                }
                .foregroundStyle(.secondary)
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(.secondary.opacity(0.1))
                .clipShape(Capsule())
                
                Spacer()
                
                // Deadline
                HStack(spacing: 4) {
                    Image(systemName: isOverdue ? "exclamationmark.circle.fill" : "calendar")
                        .font(.caption2)
                    Text(formattedDeadline)
                        .font(.caption2)
                        .fontWeight(.semibold)
                }
                .foregroundStyle(isOverdue ? .red : .secondary)
            }
        }
        .padding()
        .contentShape(Rectangle())
        .onTapGesture {
            appSession.selectedTask = task
        }
        .glassEffect(in: .rect(cornerRadius: 20))
        .contextMenu {
            if task.assignedBy == appSession.currentUser?.id {
                Button(role: .destructive) {
                    Task {
                        try? await appSession.taskStore.deleteTask(id: task.id)
                    }
                } label: {
                    Label("Delete Task", systemImage: "trash")
                }
            }
            
            if task.status != .completed && (task.assignedTo == appSession.currentUser?.id || task.delegatedToId == appSession.currentUser?.id) {
                Button {
                    Task {
                        try? await appSession.taskStore.updateTaskStatus(id: task.id, status: .completed)
                    }
                } label: {
                    Label("Mark as Complete", systemImage: "checkmark.circle")
                }
            }
        }
    }
    
    private var priorityBadge: some View {
        Label {
            Text(task.priority.rawValue.uppercased())
        } icon: {
            Image(systemName: task.priority == .high ? "exclamationmark.triangle.fill" : "exclamationmark.circle.fill")
        }
        .font(.caption)
        .foregroundStyle(priorityColor)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .glassEffect(in: .capsule)
    }
    
    private var priorityColor: Color {
        switch task.priority {
        case .high: return .red
        case .low: return .orange
        }
    }
    
    private var formattedDeadline: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d • h:mm a"
        return formatter.string(from: task.deadline)
    }
}

#Preview {
    let session = AppSession()
    let eventId = UUID()
    let clubId = UUID()
    
    let event = Event(
        id: eventId,
        name: "Sample Event",
        title: "Test Title",
        description: "Event Description",
        startDate: Date(),
        endDate: Date(),
        startTime: Date(),
        endTime: Date(),
        numberOfVolunteers: 0,
        numberOfRegistrations: 0,
        maxParticipants: 100,
        registrationType: .individual,
        location: "Main Hall",
        clubId: clubId,
        createdBy: UUID(),
        category: .technical,
        status: .approved,
        registrationDeadline: Date(),
        bannerImage: nil,
        agenda: nil,
        createdAt: Date()
    )
    
    session.eventStore.events.append(event)
    
    let sampleTask = Tasks(id: UUID(), clubId: clubId,
        targetClubId: nil,
        eventId: eventId,
        title: "Sample Task",
        description: "This is a sample task description.",
        assignedBy: UUID(),
        assignedByRole: AppRole.clubLead,
        assignedTo: UUID(),
        assignedToRole: AppRole.clubLead,
        deadline: Date(),
        priority: .high,
        status: .pending,
        createdAt: Date()
    )
    
    return TaskRowView(task: sampleTask)
        .environment(session)
        .padding()
}
