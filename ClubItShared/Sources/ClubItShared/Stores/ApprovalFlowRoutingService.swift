import Foundation
import Observation
import Supabase

@Observable
public final class ApprovalFlowRoutingService {
    private var client: SupabaseClient { SupabaseManager.shared.client }
    
    public init() {}
    
    /// Resolves the sequence of approver user IDs for a given category by walking up the hierarchy:
    /// Subgroup -> Group -> Organization -> Global Fallback
    public func resolveApprovers(category: String, subgroupId: UUID, groupId: UUID, orgId: UUID) async -> [UUID] {
        var resolvedIds: [UUID] = []
        
        // 1. Try Subgroup Flow
        if let subgroupApprovers = try? await fetchFlowApprovers(entityId: subgroupId, entityType: .subgroup, category: category), !subgroupApprovers.isEmpty {
            print("DEBUG Routing: Found Subgroup approval flow for \(category) with \(subgroupApprovers.count) approver(s).")
            resolvedIds = subgroupApprovers
        }
        // 2. Try Group Flow
        else if let groupApprovers = try? await fetchFlowApprovers(entityId: groupId, entityType: .group, category: category), !groupApprovers.isEmpty {
            print("DEBUG Routing: Found Group approval flow for \(category) with \(groupApprovers.count) approver(s).")
            resolvedIds = groupApprovers
        }
        // 3. Try Organization Flow
        else if let orgApprovers = try? await fetchFlowApprovers(entityId: orgId, entityType: .organization, category: category), !orgApprovers.isEmpty {
            print("DEBUG Routing: Found Organization approval flow for \(category) with \(orgApprovers.count) approver(s).")
            resolvedIds = orgApprovers
        }
        // 4. Try Global dummy Org ID fallback
        else {
            let globalOrgId = UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
            if let globalApprovers = try? await fetchFlowApprovers(entityId: globalOrgId, entityType: .organization, category: category), !globalApprovers.isEmpty {
                print("DEBUG Routing: Found Global approval flow for \(category) with \(globalApprovers.count) approver(s).")
                resolvedIds = globalApprovers
            }
        }
        
        if resolvedIds.isEmpty {
            print("DEBUG Routing: No custom approval flows configured for \(category). Attempting role-based fallback.")
            if category.lowercased() == "budget" {
                struct UserRoleRow: Decodable {
                    let user_id: UUID?
                    let role_name: String
                    let group_id: UUID?
                }
                let targetGroupLeadRows: [UserRoleRow] = (try? await client
                    .from("user_roles")
                    .select("user_id, role_name, group_id")
                    .eq("group_id", value: groupId)
                    .execute()
                    .value) ?? []
                
                if let leadId = targetGroupLeadRows.first(where: { 
                    let roleLower = $0.role_name.lowercased()
                    return roleLower.contains("group lead") || roleLower == "level_1_lead" || roleLower == "group_lead" || roleLower.contains("president")
                })?.user_id {
                    resolvedIds = [leadId]
                }
            } else {
                struct SubgroupRow: Decodable {
                    let faculty_id: UUID?
                }
                let subRows: [SubgroupRow] = (try? await client
                    .from("subgroups")
                    .select("faculty_id")
                    .eq("id", value: subgroupId)
                    .execute()
                    .value) ?? []
                
                if let facultyId = subRows.first?.faculty_id {
                    resolvedIds = [facultyId]
                } else {
                    let emtId = UUID(uuidString: "b02ff9cf-dce8-4be9-8fc6-a0d15c03ddad")!
                    resolvedIds = [emtId]
                }
            }
        }
        
        if resolvedIds.isEmpty {
            print("DEBUG Routing: No approval flows or default approvers resolved for \(category).")
            return []
        }
        
        // Dynamic Swap: If any resolved approver is a Group Lead of a different group, 
        // swap them with the Group Lead of the target group.
        var finalIds: [UUID] = []
        for approverId in resolvedIds {
            struct UserRoleRow: Decodable {
                let user_id: UUID?
                let role_name: String
                let group_id: UUID?
            }
            let roles: [UserRoleRow] = (try? await client
                .from("user_roles")
                .select("role_name, group_id")
                .eq("user_id", value: approverId)
                .execute()
                .value) ?? []
            
            let isGroupLead = roles.contains { 
                let roleLower = $0.role_name.lowercased()
                return roleLower.contains("group lead") || roleLower == "level_1_lead" || roleLower == "group_lead"
            }
            
            if isGroupLead {
                let belongsToTargetGroup = roles.contains { $0.group_id == groupId }
                if !belongsToTargetGroup {
                    let targetGroupLeadRows: [UserRoleRow] = (try? await client
                        .from("user_roles")
                        .select("user_id, role_name, group_id")
                        .eq("group_id", value: groupId)
                        .execute()
                        .value) ?? []
                    
                    if let correctLeadId = targetGroupLeadRows.first(where: { 
                        let roleLower = $0.role_name.lowercased()
                        return roleLower.contains("group lead") || roleLower == "level_1_lead" || roleLower == "group_lead"
                    })?.user_id {
                        print("DEBUG Routing: Dynamically swapped placeholder Group Lead \(approverId) with correct Group Lead \(correctLeadId) for group \(groupId)")
                        finalIds.append(correctLeadId)
                        continue
                    }
                }
            }
            finalIds.append(approverId)
        }
        
        return finalIds
    }
    
    private func fetchFlowApprovers(entityId: UUID, entityType: ApprovalEntityType, category: String) async throws -> [UUID] {
        let flows: [ApprovalFlowConfig] = try await client
            .from("approval_flows")
            .select()
            .eq("entity_id", value: entityId)
            .eq("entity_type", value: entityType.rawValue)
            .eq("category", value: category)
            .eq("is_enabled", value: true)
            .execute()
            .value
            
        guard let flow = flows.first else { return [] }
        
        let assignees: [ApprovalFlowAssignee] = try await client
            .from("approval_flow_assignees")
            .select()
            .eq("flow_id", value: flow.id)
            .eq("role_type", value: ApprovalAssigneeRole.approver.rawValue)
            .order("sequence_order", ascending: true)
            .execute()
            .value
            
        return assignees.map(\.userId)
    }
}
