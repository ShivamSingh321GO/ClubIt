import Foundation

public struct SubgroupModel: Identifiable, Hashable, Codable {
    public var id: UUID
    public var groupId: UUID
    public var parentSubgroupId: UUID?
    public var name: String
    public var category: String?
    public var logoUrl: String?
    public var createdAt: Date?
    public var description: String?
    public var tagline: String?
    public var leadName: String?
    public var leadEmail: String?
    public var leadDesignation: String?
    
    // UI only (not encoded)
    public var logoData: Data? = nil
    public var parentName: String = ""
    
    public var isNested: Bool {
        return parentSubgroupId != nil
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case groupId = "group_id"
        case parentSubgroupId = "parent_subgroup_id"
        case name
        case category
        case logoUrl = "logo_url"
        case createdAt = "created_at"
        case description
        case tagline
        case leadName = "lead_name"
        case leadEmail = "lead_email"
        case leadDesignation = "lead_designation"
    }
    
    public init(id: UUID = UUID(), groupId: UUID, parentSubgroupId: UUID? = nil, name: String, category: String? = nil, logoUrl: String? = nil, createdAt: Date? = nil, description: String? = nil, tagline: String? = nil, leadName: String? = nil, leadEmail: String? = nil, leadDesignation: String? = nil, logoData: Data? = nil, parentName: String = "") {
        self.id = id
        self.groupId = groupId
        self.parentSubgroupId = parentSubgroupId
        self.name = name
        self.category = category
        self.logoUrl = logoUrl
        self.createdAt = createdAt
        self.description = description
        self.tagline = tagline
        self.leadName = leadName
        self.leadEmail = leadEmail
        self.leadDesignation = leadDesignation
        
        self.logoData = logoData
        self.parentName = parentName
    }
}
