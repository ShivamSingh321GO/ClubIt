import Foundation
import Observation

@Observable
final class TaskStore {
    var tasks: [Tasks] = {
        let presidentId = MockData.allMockUsers.first { $0.role == .president }?.id ?? UUID()
        let facultyId = MockData.technoJamBundle.users.first { $0.role == .faculty }?.id ?? UUID()
        let leadId = MockData.clubLeadUser.id
        let memberId = MockData.technoJamBundle.users.first { $0.role == .clubMember }?.id ?? UUID()
        let clubId = MockData.tj_id
        let eventId = MockData.sampleEvents.first?.id
        
        return [
            Tasks(
                clubId: clubId,
                targetClubId: nil,
                eventId: eventId,
                title: "Annual Tech Summit Budget",
                description: "Finalize the sponsorship budget and get approval from the President.",
                assignedBy: presidentId,
                assignedByRole: .president,
                assignedTo: leadId,
                assignedToRole: .clubLead,
                delegatedToId: nil,
                delegatedToName: nil,
                deadline: Date().addingTimeInterval(3600 * 24 * 2),
                priority: .high,
                status: .pending,
                createdAt: Date()
            ),
            Tasks(
                clubId: clubId,
                targetClubId: nil,
                eventId: eventId,
                title: "Speaker Invitation List",
                description: "Review and short-list speakers for the upcoming summit.",
                assignedBy: facultyId,
                assignedByRole: .faculty,
                assignedTo: leadId,
                assignedToRole: .clubLead,
                delegatedToId: nil,
                delegatedToName: nil,
                deadline: Date().addingTimeInterval(3600 * 24 * 5),
                priority: .high,
                status: .pending,
                createdAt: Date()
            ),
            Tasks(
                clubId: clubId,
                targetClubId: nil,
                eventId: nil,
                title: "Social Media Strategy",
                description: "Plan the next month's posts for Instagram and Twitter.",
                assignedBy: leadId,
                assignedByRole: .clubLead,
                assignedTo: leadId,
                assignedToRole: .clubLead,
                delegatedToId: nil,
                delegatedToName: nil,
                deadline: Date().addingTimeInterval(3600 * 24 * 7),
                priority: .low,
                status: .pending,
                createdAt: Date()
            )
        ]
    }()
    
    func addTask(title: String, description: String, clubId: UUID, targetClubId: UUID? = nil, eventId: UUID?, assignedBy: UUID, assignedByRole: AppRole, assignedTo: UUID, assignedToRole: AppRole, priority: TaskPriority, deadline: Date) {
        let newTask = Tasks(
            clubId: clubId,
            targetClubId: targetClubId,
            eventId: eventId,
            title: title,
            description: description,
            assignedBy: assignedBy,
            assignedByRole: assignedByRole,
            assignedTo: assignedTo,
            assignedToRole: assignedToRole,
            deadline: deadline,
            priority: priority,
            status: .pending,
            createdAt: Date()
        )
        tasks.append(newTask)
    }
    
    func updateTaskStatus(id: UUID, status: TaskStatus) {
        if let index = tasks.firstIndex(where: { $0.id == id }) {
            tasks[index].status = status
        }
    }
    
    func editTask(id: UUID, title: String, description: String, clubId: UUID, targetClubId: UUID? = nil, eventId: UUID?, assignedTo: UUID, assignedToRole: AppRole, priority: TaskPriority, deadline: Date) {
        if let index = tasks.firstIndex(where: { $0.id == id }) {
            tasks[index].title = title
            tasks[index].description = description
            tasks[index].clubId = clubId
            tasks[index].targetClubId = targetClubId
            tasks[index].eventId = eventId
            tasks[index].assignedTo = assignedTo
            tasks[index].assignedToRole = assignedToRole
            tasks[index].deadline = deadline
            tasks[index].priority = priority
        }
    }
    
    func delegateTask(taskId: UUID, memberId: UUID, memberName: String) {
        if let index = tasks.firstIndex(where: { $0.id == taskId }) {
            tasks[index].delegatedToId = memberId
            tasks[index].delegatedToName = memberName
            // Optionally change status or add a note
        }
    }
    
    var pendingTasks: [Tasks] {
        tasks.filter { $0.status == .pending }
            .sorted { $0.deadline < $1.deadline }
    }
    
    var completedTasks: [Tasks] {
        tasks.filter { $0.status == .completed }
            .sorted { $0.deadline < $1.deadline }
    }

    func filteredTasks(for userId: UUID) -> [Tasks] {
        tasks.filter { $0.assignedBy == userId || $0.assignedTo == userId || $0.delegatedToId == userId }
            .sorted { $0.deadline < $1.deadline }
    }

    func filteredPendingTasks(for userId: UUID) -> [Tasks] {
        tasks.filter { ($0.assignedBy == userId || $0.assignedTo == userId || $0.delegatedToId == userId) && $0.status == .pending }
            .sorted { $0.deadline < $1.deadline }
    }

    func filteredCompletedTasks(for userId: UUID) -> [Tasks] {
        tasks.filter { ($0.assignedBy == userId || $0.assignedTo == userId || $0.delegatedToId == userId) && $0.status == .completed }
            .sorted { $0.deadline < $1.deadline }
    }
}
