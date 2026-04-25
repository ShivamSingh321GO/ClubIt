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
        self.budgets = MockData.sampleBudgets
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
    
    func updateApproval(id: UUID, status: ApprovalStatus, remark: Remark? = nil) {
        if let index = approvals.firstIndex(where: { $0.id == id }) {
            approvals[index].status = status
            if let remark = remark {
                approvals[index].remarks.append(remark)
            }
            approvals[index].updatedAt = Date()
        }
    }
    
    func updateResourceStatus(id: UUID, status: ResourceStatus, remark: Remark? = nil) {
        if let index = resources.firstIndex(where: { $0.id == id }) {
            resources[index].status = status
            if let remark = remark {
                resources[index].remarks.append(remark)
            }
            resources[index].approvedAt = status == .approved ? Date() : nil
        }
    }

    func updateBudgetStatus(id: UUID, status: ApprovalStatus, remark: Remark? = nil) {
        if let index = budgets.firstIndex(where: { $0.id == id }) {
            budgets[index].status = status
            if let remark = remark {
                budgets[index].remarks.append(remark)
            }
            budgets[index].approvedAt = status == .approved ? Date() : nil
        }
    }
    
    func updateBudget(_ budget: Budget) {
        if let index = budgets.firstIndex(where: { $0.id == budget.id }) {
            budgets[index] = budget
        }
    }
    
    func updateResource(_ resource: Resource) {
        if let index = resources.firstIndex(where: { $0.id == resource.id }) {
            resources[index] = resource
        }
    }
    
    func updateApprovalStatus(id: UUID, status: ApprovalStatus) {
        if let index = approvals.firstIndex(where: { $0.id == id }) {
            approvals[index].status = status
            approvals[index].updatedAt = Date()
        }
    }
    
    // Helper methods for replies
    func addRemarkToApproval(id: UUID, remark: Remark) {
        if let index = approvals.firstIndex(where: { $0.id == id }) {
            approvals[index].remarks.append(remark)
        }
    }
    
    func addRemarkToResource(id: UUID, remark: Remark) {
        if let index = resources.firstIndex(where: { $0.id == id }) {
            resources[index].remarks.append(remark)
        }
    }
    
    func addRemarkToBudget(id: UUID, remark: Remark) {
        if let index = budgets.firstIndex(where: { $0.id == id }) {
            budgets[index].remarks.append(remark)
        }
    }
}
