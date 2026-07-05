import Foundation

public enum ApprovalEntityType: String, Codable {
    case organization
    case group
    case subgroup
}

public enum ApprovalAssigneeRole: String, Codable {
    case approver
    case viewer
}

public struct ApprovalFlowConfig: Identifiable, Codable {
    public var id: UUID
    public var entityType: ApprovalEntityType
    public var entityId: UUID
    public var category: String
    public var isEnabled: Bool
    public var createdAt: Date
    public var updatedAt: Date
    
    public enum CodingKeys: String, CodingKey {
        case id
        case entityType = "entity_type"
        case entityId = "entity_id"
        case category
        case isEnabled = "is_enabled"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    public init(id: UUID = UUID(), entityType: ApprovalEntityType, entityId: UUID, category: String, isEnabled: Bool = true, createdAt: Date = Date(), updatedAt: Date = Date()) {
        self.id = id
        self.entityType = entityType
        self.entityId = entityId
        self.category = category
        self.isEnabled = isEnabled
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

public struct ApprovalFlowAssignee: Identifiable, Codable {
    public var id: UUID
    public var flowId: UUID
    public var userId: UUID
    public var roleType: ApprovalAssigneeRole
    public var sequenceOrder: Int?
    public var createdAt: Date
    
    public enum CodingKeys: String, CodingKey {
        case id
        case flowId = "flow_id"
        case userId = "user_id"
        case roleType = "role_type"
        case sequenceOrder = "sequence_order"
        case createdAt = "created_at"
    }
    
    public init(id: UUID = UUID(), flowId: UUID, userId: UUID, roleType: ApprovalAssigneeRole, sequenceOrder: Int? = nil, createdAt: Date = Date()) {
        self.id = id
        self.flowId = flowId
        self.userId = userId
        self.roleType = roleType
        self.sequenceOrder = sequenceOrder
        self.createdAt = createdAt
    }
}
