import Foundation
import Observation
import Supabase

@Observable
public final class ApprovalStore {
    private var client: SupabaseClient { SupabaseManager.shared.client }
    
    public var approvals: [Approval] = []
    public var budgets: [Budget] = []
    public var resources: [Resource] = []
    
    // New: Dictionary to store remarks for each approval
    public var remarkMessages: [UUID: [RemarkMessage]] = [:]
    
    public init() {
        // We'll fetch from Supabase in AppSession
    }
    
    @MainActor
    public func fetchApprovals() async throws {
        self.approvals = try await client
            .from("approvals")
            .select()
            .order("created_at", ascending: false)
            .execute()
            .value
    }
    
    @MainActor
    public func fetchRemarks(for approvalId: UUID) async throws {
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
    public func addRemark(approvalId: UUID, authorId: UUID, content: String) async throws {
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
    public func addRemarks(_ remarks: [RemarkMessage]) async throws {
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
    public func fetchBudgets(eventId: UUID? = nil) async throws {
        var query = client.from("budgets").select()
        if let eventId = eventId {
            query = query.eq("event_id", value: eventId)
        }
        let fetchedBudgets: [Budget] = try await query.execute().value
        if let eventId = eventId {
            self.budgets = self.budgets.filter { $0.eventId != eventId } + fetchedBudgets
        } else {
            self.budgets = fetchedBudgets
        }
    }
    
    @MainActor
    public func fetchResources(eventId: UUID? = nil) async throws {
        var query = client.from("resources").select()
        if let eventId = eventId {
            query = query.eq("event_id", value: eventId)
        }
        let fetchedResources: [Resource] = try await query.execute().value
        if let eventId = eventId {
            self.resources = self.resources.filter { $0.eventId != eventId } + fetchedResources
        } else {
            self.resources = fetchedResources
        }
    }
    
    @MainActor
    public func submitApprovalRequest(_ approval: Approval) async throws {
        try await client
            .from("approvals")
            .insert(approval)
            .execute()
        
        if !self.approvals.contains(where: { $0.id == approval.id }) {
            self.approvals.insert(approval, at: 0)
        }
    }

    @MainActor
    public func submitApprovalRequests(_ approvals: [Approval]) async throws {
        try await client.from("approvals").insert(approvals).execute()
        for approval in approvals {
            if !self.approvals.contains(where: { $0.id == approval.id }) {
                self.approvals.insert(approval, at: 0)
            }
        }
    }
    
    @MainActor
    public func addBudget(_ budget: Budget) async throws {
        try await client
            .from("budgets")
            .insert(budget)
            .execute()
        
        if !self.budgets.contains(where: { $0.id == budget.id }) {
            self.budgets.append(budget)
        }
    }

    @MainActor
    public func addBudgets(_ budgets: [Budget]) async throws {
        try await client.from("budgets").insert(budgets).execute()
        for budget in budgets {
            if !self.budgets.contains(where: { $0.id == budget.id }) {
                self.budgets.append(budget)
            }
        }
    }
    
    @MainActor
    public func addResource(_ resource: Resource) async throws {
        try await client
            .from("resources")
            .insert(resource)
            .execute()
        
        if !self.resources.contains(where: { $0.id == resource.id }) {
            self.resources.append(resource)
        }
    }

    @MainActor
    public func addResources(_ resources: [Resource]) async throws {
        try await client.from("resources").insert(resources).execute()
        for resource in resources {
            if !self.resources.contains(where: { $0.id == resource.id }) {
                self.resources.append(resource)
            }
        }
    }
    
    public func approvals(for eventId: UUID) -> [Approval] {
        approvals.filter { $0.eventId == eventId }
    }
    
    @MainActor
    public func updateApproval(id: UUID, status: ApprovalStatus, approvalRelatedId: UUID? = nil) async throws {
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
    public func deleteApproval(id: UUID) async throws {
        try await client
            .from("approvals")
            .delete()
            .eq("id", value: id)
            .execute()
            
        approvals.removeAll(where: { $0.id == id })
    }
    
    @MainActor
    public func updateResourceStatus(id: UUID, status: ResourceStatus) async throws {
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
    public func updateBudgetStatus(id: UUID, status: ApprovalStatus) async throws {
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
    public func updateBudget(_ budget: Budget) async throws {
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
    public func updateResource(_ resource: Resource) async throws {
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
