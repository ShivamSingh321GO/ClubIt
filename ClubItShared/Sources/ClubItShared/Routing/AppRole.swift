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
        switch dbRole {
        case "superadmin", "SuperAdmin": return .superAdmin
        case "admin", "Admin": return .admin
        case "level_1_lead", "Group Lead": return .groupLead
        case "level_1_sublead", "Group SubLead": return .groupSubLead
        case "level_2_lead", "SubGroup Lead": return .subGroupLead
        case "level_2_member", "SubGroup member": return .subGroupMember
        default:
            if dbRole.hasPrefix("level_1_lead") { return .groupLead }
            if dbRole.hasPrefix("level_1_sublead") { return .groupSubLead }
            if dbRole.hasPrefix("level_2_lead") { return .subGroupLead }
            if dbRole.hasPrefix("level_2_sublead") { return .subGroupLead }
            return .guest
        }
    }
}
