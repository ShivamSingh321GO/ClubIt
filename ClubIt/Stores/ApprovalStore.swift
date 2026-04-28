import Foundation
import Observation
import Supabase

@Observable
final class ApprovalStore {
    private var client: SupabaseClient { SupabaseManager.shared.client }
    
    var approvals: [Approval] = []
    var budgets: [Budget] = []
    var resources: [Resource] = []
    
    init() {
        // We'll fetch from Supabase in AppSession, but keeping mock init for safety during transitions
        self.approvals = MockData.sampleApprovals
        self.resources = MockData.sampleResources
        self.budgets = MockData.sampleBudgets
    }
    
    @MainActor
    func fetchApprovals() async throws {
        self.approvals = try await client
            .from("approvals")
            .select()
            .order("created_at", ascending: false)
            .execute()
            .value
    }
    
    @MainActor
    func fetchBudgets(eventId: UUID? = nil) async throws {
        var query = client.from("budgets").select()
        if let eventId = eventId {
            query = query.eq("event_id", value: eventId)
        }
        self.budgets = try await query.execute().value
    }
    
    @MainActor
    func fetchResources(eventId: UUID? = nil) async throws {
        var query = client.from("resources").select()
        if let eventId = eventId {
            query = query.eq("event_id", value: eventId)
        }
        self.resources = try await query.execute().value
    }
    
    @MainActor
    func submitApprovalRequest(_ approval: Approval) async throws {
        try await client
            .from("approvals")
            .insert(approval)
            .execute()
        
        try await fetchApprovals()
    }
    
    @MainActor
    func addBudget(_ budget: Budget) async throws {
        try await client
            .from("budgets")
            .insert(budget)
            .execute()
        
        try await fetchBudgets(eventId: budget.eventId)
    }
    
    @MainActor
    func addResource(_ resource: Resource) async throws {
        try await client
            .from("resources")
            .insert(resource)
            .execute()
        
        try await fetchResources(eventId: resource.eventId)
    }
    
    func approvals(for eventId: UUID) -> [Approval] {
        approvals.filter { $0.eventId == eventId }
    }
    
    @MainActor
    func updateApproval(id: UUID, status: ApprovalStatus, remarks: [Remark]? = nil) async throws {
        var updateData: [String: AnyJSON] = ["status": .string(status.rawValue)]
        if let remarks = remarks {
            // Encode remarks to JSONB
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            if let data = try? encoder.encode(remarks),
               let json = try? JSONSerialization.jsonObject(with: data) as? [[String: Any]] {
                updateData["remarks"] = .array(json.map { .object($0.mapValues { AnyJSON.string("\($0)") }) }) // Simplified for now
            }
        }
        
        try await client
            .from("approvals")
            .update(updateData)
            .eq("id", value: id)
            .execute()
            
        if let index = approvals.firstIndex(where: { $0.id == id }) {
            approvals[index].status = status
            if let remarks = remarks {
                approvals[index].remarks = remarks
            }
            approvals[index].updatedAt = Date()
        }
    }
    
    @MainActor
    func updateResourceStatus(id: UUID, status: ResourceStatus, remarks: [Remark]? = nil) async throws {
        print("DEBUG: Updating Resource Status for \(id) to \(status.rawValue)")
        do {
            // 1. Update resources table
            try await client
                .from("resources")
                .update(["status": status.rawValue])
                .eq("id", value: id)
                .execute()
                
            // 2. ALSO update the main approvals table
            try await client
                .from("approvals")
                .update(["status": status.rawValue])
                .eq("approval_related_id", value: id)
                .execute()

            // Update local state
            if let index = resources.firstIndex(where: { $0.id == id }) {
                resources[index].status = status
                if let remarks = remarks {
                    resources[index].remarks = remarks
                }
                resources[index].approvedAt = status == .approved ? Date() : nil
            }
            
            if let appIndex = approvals.firstIndex(where: { $0.approvalRelatedId == id }) {
                approvals[appIndex].status = ApprovalStatus(rawValue: status.rawValue) ?? .pending
            }
        } catch {
            print("DEBUG ERROR: Failed to update resource status: \(error)")
            throw error
        }
    }

    @MainActor
    func updateBudgetStatus(id: UUID, status: ApprovalStatus, remarks: [Remark]? = nil) async throws {
        print("DEBUG: Updating Budget Status for \(id) to \(status.rawValue)")
        do {
            // 1. Update budgets table
            try await client
                .from("budgets")
                .update(["status": status.rawValue])
                .eq("id", value: id)
                .execute()
                
            // 2. ALSO update the main approvals table
            try await client
                .from("approvals")
                .update(["status": status.rawValue])
                .eq("approval_related_id", value: id)
                .execute()

            // Update local state
            if let index = budgets.firstIndex(where: { $0.id == id }) {
                budgets[index].status = status
                if let remarks = remarks {
                    budgets[index].remarks = remarks
                }
                budgets[index].approvedAt = status == .approved ? Date() : nil
            }
            
            if let appIndex = approvals.firstIndex(where: { $0.approvalRelatedId == id }) {
                approvals[appIndex].status = status
            }
        } catch {
            print("DEBUG ERROR: Failed to update budget status: \(error)")
            throw error
        }
    }
    
    @MainActor
    func updateBudget(_ budget: Budget) async throws {
        try await client
            .from("budgets")
            .update(budget)
            .eq("id", value: budget.id)
            .execute()
            
        if let index = budgets.firstIndex(where: { $0.id == budget.id }) {
            budgets[index] = budget
        }
    }
    
    @MainActor
    func updateResource(_ resource: Resource) async throws {
        try await client
            .from("resources")
            .update(resource)
            .eq("id", value: resource.id)
            .execute()
            
        if let index = resources.firstIndex(where: { $0.id == resource.id }) {
            resources[index] = resource
        }
    }
}
