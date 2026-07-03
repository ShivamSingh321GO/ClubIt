import Foundation

public struct HierarchyLevelModel: Codable, Identifiable {
    public var id: UUID
    public var organizationId: UUID
    public var levelNumber: Int
    public var levelName: String
    public var isEnabled: Bool
    public var createdBy: UUID?
    public var createdAt: Date?
    public var updatedAt: Date?
    
    enum CodingKeys: String, CodingKey {
        case id
        case organizationId = "organization_id"
        case levelNumber = "level_number"
        case levelName = "level_name"
        case isEnabled = "is_enabled"
        case createdBy = "created_by"
        case createdAt = "created_at"
        case updatedAt = "updated_at"
    }
    
    public init(id: UUID = UUID(), organizationId: UUID, levelNumber: Int, levelName: String, isEnabled: Bool = true, createdBy: UUID? = nil, createdAt: Date? = nil, updatedAt: Date? = nil) {
        self.id = id
        self.organizationId = organizationId
        self.levelNumber = levelNumber
        self.levelName = levelName
        self.isEnabled = isEnabled
        self.createdBy = createdBy
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}
