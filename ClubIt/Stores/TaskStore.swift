import Foundation
import Observation
import Supabase

@Observable
final class TaskStore {
    private var client: SupabaseClient { SupabaseManager.shared.client }
    var tasks: [Tasks] = []
    
    init() {}
    
    @MainActor
    func fetchTasks() async throws {
        self.tasks = try await client
            .from("tasks")
            .select()
            .order("deadline", ascending: true)
            .execute()
            .value
    }
    
    @MainActor
    func addTask(_ task: Tasks) async throws {
        try await client
            .from("tasks")
            .insert(task)
            .execute()
        
        try await fetchTasks()
    }
    
    @MainActor
    func updateTaskStatus(id: UUID, status: TaskStatus) async throws {
        try await client
            .from("tasks")
            .update(["status": status.rawValue])
            .eq("id", value: id)
            .execute()
        
        try await fetchTasks()
    }
    
    @MainActor
    func editTask(_ task: Tasks) async throws {
        try await client
            .from("tasks")
            .update(task)
            .eq("id", value: task.id)
            .execute()
        
        try await fetchTasks()
    }
    
    @MainActor
    func deleteTask(id: UUID) async throws {
        try await client
            .from("tasks")
            .delete()
            .eq("id", value: id)
            .execute()
        
        try await fetchTasks()
    }
    
    @MainActor
    func delegateTask(taskId: UUID, memberId: UUID) async throws {
        try await client
            .from("tasks")
            .update(["delegated_to_id": memberId])
            .eq("id", value: taskId)
            .execute()
        
        try await fetchTasks()
    }
    
    // Computed filters remain the same
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
