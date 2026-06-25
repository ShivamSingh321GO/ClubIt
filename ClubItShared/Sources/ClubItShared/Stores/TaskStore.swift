import Foundation
import Observation
import Supabase

@Observable
public final class TaskStore {
    private var client: SupabaseClient { SupabaseManager.shared.client }
    public var tasks: [Tasks] = []
    
    public init() {}
    
    @MainActor
    public func fetchTasks() async throws {
        self.tasks = try await client
            .from("tasks")
            .select()
            .order("deadline", ascending: true)
            .execute()
            .value
    }
    
    @MainActor
    public func addTask(_ task: Tasks) async throws {
        try await client
            .from("tasks")
            .insert(task)
            .execute()
        
        try await fetchTasks()
    }
    
    @MainActor
    public func updateTaskStatus(id: UUID, status: TaskStatus) async throws {
        try await client
            .from("tasks")
            .update(["status": status.rawValue])
            .eq("id", value: id)
            .execute()
        
        try await fetchTasks()
    }
    
    @MainActor
    public func editTask(_ task: Tasks) async throws {
        try await client
            .from("tasks")
            .update(task)
            .eq("id", value: task.id)
            .execute()
        
        try await fetchTasks()
    }
    
    @MainActor
    public func deleteTask(id: UUID) async throws {
        try await client
            .from("tasks")
            .delete()
            .eq("id", value: id)
            .execute()
        
        try await fetchTasks()
    }
    
    @MainActor
    public func delegateTask(taskId: UUID, memberId: UUID) async throws {
        try await client
            .from("tasks")
            .update(["delegated_to_id": memberId])
            .eq("id", value: taskId)
            .execute()
        
        try await fetchTasks()
    }
    
    // Computed filters remain the same
    public var pendingTasks: [Tasks] {
        tasks.filter { $0.status == .pending }
            .sorted { $0.deadline < $1.deadline }
    }
    
    public var completedTasks: [Tasks] {
        tasks.filter { $0.status == .completed }
            .sorted { $0.deadline < $1.deadline }
    }
    
    public func filteredTasks(for userId: UUID) -> [Tasks] {
        tasks.filter { $0.assignedBy == userId || $0.assignedTo == userId || $0.delegatedToId == userId }
            .sorted { $0.deadline < $1.deadline }
    }
    
    public func filteredPendingTasks(for userId: UUID) -> [Tasks] {
        tasks.filter { ($0.assignedBy == userId || $0.assignedTo == userId || $0.delegatedToId == userId) && $0.status == .pending }
            .sorted { $0.deadline < $1.deadline }
    }
    
    public func filteredCompletedTasks(for userId: UUID) -> [Tasks] {
        tasks.filter { ($0.assignedBy == userId || $0.assignedTo == userId || $0.delegatedToId == userId) && $0.status == .completed }
            .sorted { $0.deadline < $1.deadline }
    }
    
    public func filteredOverdueTasks(for userId: UUID) -> [Tasks] {
        let now = Date()
        return tasks.filter { ($0.assignedBy == userId || $0.assignedTo == userId || $0.delegatedToId == userId) && $0.status == .pending && $0.deadline < now }
            .sorted { $0.deadline < $1.deadline }
    }
}
