import Foundation
import Observation
import Supabase

@Observable
final class ApprovalStore {
    private var client: SupabaseClient { SupabaseManager.shared.client }
    
    var approvals: [Approval] = []
    var budgets: [Budget] = []
    var resources: [Resource] = []
    
    // New: Dictionary to store remarks for each approval
    var remarkMessages: [UUID: [RemarkMessage]] = [:]
    
    init() {
        // We'll fetch from Supabase in AppSession
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
    func fetchRemarks(for approvalId: UUID) async throws {
        let messages: [RemarkMessage] = try await client
            .from("remarks")
            .select()
            .eq("approval_id", value: approvalId)
            .order("created_at", ascending: true)
            .execute()
            .value
        
        self.remarkMessages[approvalId] = messages
    }
    
    @MainActor
    func addRemark(approvalId: UUID, authorId: UUID, content: String) async throws {
        print("DEBUG: Sending Remark to Supabase - Approval: \(approvalId), Author: \(authorId), Content: '\(content)'")
        
        let newRemark = RemarkMessage(
            id: UUID(),
            approvalId: approvalId,
            authorId: authorId,
            content: content,
            createdAt: Date()
        )
        
        try await client
            .from("remarks")
            .insert(newRemark)
            .execute()
        
        // Update locally
        if var current = remarkMessages[approvalId] {
            current.append(newRemark)
            remarkMessages[approvalId] = current
        } else {
            remarkMessages[approvalId] = [newRemark]
        }
    }

    @MainActor
    func addRemarks(_ remarks: [RemarkMessage]) async throws {
        try await client.from("remarks").insert(remarks).execute()
        // Update locally
        for remark in remarks {
            if var current = remarkMessages[remark.approvalId] {
                current.append(remark)
                remarkMessages[remark.approvalId] = current
            } else {
                remarkMessages[remark.approvalId] = [remark]
            }
        }
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
        
        try? await fetchApprovals()
    }

    @MainActor
    func submitApprovalRequests(_ approvals: [Approval]) async throws {
        try await client.from("approvals").insert(approvals).execute()
        try? await fetchApprovals()
    }
    
    @MainActor
    func addBudget(_ budget: Budget) async throws {
        try await client
            .from("budgets")
            .insert(budget)
            .execute()
        
        try? await fetchBudgets(eventId: budget.eventId)
    }

    @MainActor
    func addBudgets(_ budgets: [Budget]) async throws {
        try await client.from("budgets").insert(budgets).execute()
        if let first = budgets.first {
            try? await fetchBudgets(eventId: first.eventId)
        }
    }
    
    @MainActor
    func addResource(_ resource: Resource) async throws {
        try await client
            .from("resources")
            .insert(resource)
            .execute()
        
        try? await fetchResources(eventId: resource.eventId)
    }

    @MainActor
    func addResources(_ resources: [Resource]) async throws {
        try await client.from("resources").insert(resources).execute()
        if let first = resources.first {
            try? await fetchResources(eventId: first.eventId)
        }
    }
    
    func approvals(for eventId: UUID) -> [Approval] {
        approvals.filter { $0.eventId == eventId }
    }
    
    @MainActor
    func updateApproval(id: UUID, status: ApprovalStatus, approvalRelatedId: UUID? = nil) async throws {
        var updateDict: [String: String] = ["status": status.rawValue]
        if let relatedId = approvalRelatedId {
            updateDict["approval_related_id"] = relatedId.uuidString
        }
        
        try await client
            .from("approvals")
            .update(updateDict)
            .eq("id", value: id)
            .execute()
            
        if let index = approvals.firstIndex(where: { $0.id == id }) {
            approvals[index].status = status
            if let relatedId = approvalRelatedId {
                approvals[index].approvalRelatedId = relatedId
            }
            approvals[index].updatedAt = Date()
        }
    }
    
    @MainActor
    func updateResourceStatus(id: UUID, status: ResourceStatus) async throws {
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
    func updateBudgetStatus(id: UUID, status: ApprovalStatus) async throws {
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
