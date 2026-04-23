//
//  ApprovalStore.swift
//  ClubIt
//
//  Created by shivam kumar singh on 4/04/26.
//

import Foundation
import Observation

@Observable
final class ApprovalStore {
    var approvals: [Approval] = []
    var budgets: [Budget] = []
    var resources: [Resource] = []
    
    init() {
        // Initialize with some mock data for consistency
        self.approvals = MockData.sampleApprovals
        self.resources = MockData.sampleResources
    }
    
    func addApproval(_ approval: Approval) {
        approvals.insert(approval, at: 0)
    }
    
    func addBudget(_ budget: Budget) {
        budgets.insert(budget, at: 0)
    }
    
    func addResource(_ resource: Resource) {
        resources.insert(resource, at: 0)
    }
    
    func approvals(for eventId: UUID) -> [Approval] {
        approvals.filter { $0.eventId == eventId }
    }
    
    func updateApproval(id: UUID, status: ApprovalStatus, remark: String? = nil) {
        if let index = approvals.firstIndex(where: { $0.id == id }) {
            approvals[index].status = status
            approvals[index].remark = remark
            approvals[index].updatedAt = Date()
        }
    }
    
    func updateResourceStatus(id: UUID, status: ResourceStatus, remark: String? = nil) {
        if let index = resources.firstIndex(where: { $0.id == id }) {
            resources[index].status = status
            resources[index].remark = remark
            resources[index].approvedAt = status == .approved ? Date() : nil
        }
    }
}
