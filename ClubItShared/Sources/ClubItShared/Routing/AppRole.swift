//
//  AppRole.swift
//  ClubItShared
//

import Foundation

public enum AppRole: String, Codable, CaseIterable, Identifiable {
    case superAdmin = "SuperAdmin"
    case admin = "Admin"
    case groupLead = "Group Lead"
    case groupSubLead = "Group SubLead"
    case subGroupLead = "SubGroup Lead"
    case subGroupMember = "SubGroup member"
    case guest = "Guest"

    public var id: String { rawValue }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let rawStr = try container.decode(String.self)
        self = AppRole.from(dbRole: rawStr)
    }
    
    public static func from(dbRole: String) -> AppRole {
        let cleaned = dbRole
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased()
            .replacingOccurrences(of: "_", with: "")
            .replacingOccurrences(of: " ", with: "")
            .replacingOccurrences(of: "-", with: "")
        
        switch cleaned {
        case "superadmin", "superadministrator":
            return .superAdmin
            
        case "admin", "administrator", "orgadmin", "organizationadmin":
            return .admin
            
        case "grouplead", "level1lead", "president", "level1president", "grouphead":
            return .groupLead
            
        case "groupsublead", "level1sublead", "vicepresident", "vp", "groupsvicepresident", "level1vicepresident", "groupcolead", "faculty", "facultymember", "facultyresource":
            return .groupSubLead
            
        case "subgrouplead", "level2lead", "clublead", "level2clublead", "subgrouphead", "clubhead":
            return .subGroupLead
            
        case "subgroupmember", "level2member", "level2sublead", "clubmember", "member", "subgroupcolead":
            return .subGroupMember
            
        case "guest", "student", "user", "visitor":
            return .guest
            
        default:
            if cleaned.contains("groupsublead") || cleaned.contains("level1sublead") || cleaned.contains("vicepresident") {
                return .groupSubLead
            }
            if cleaned.contains("grouplead") || cleaned.contains("level1lead") || cleaned.contains("president") {
                return .groupLead
            }
            if cleaned.contains("subgrouplead") || cleaned.contains("level2lead") || cleaned.contains("clublead") {
                return .subGroupLead
            }
            if cleaned.contains("subgroupmember") || cleaned.contains("level2member") || cleaned.contains("clubmember") {
                return .subGroupMember
            }
            if cleaned.contains("level1") {
                return .groupLead
            }
            if cleaned.contains("level2") {
                return .subGroupMember
            }
            if cleaned.contains("admin") {
                return .admin
            }
            return .guest
        }
    }
}
