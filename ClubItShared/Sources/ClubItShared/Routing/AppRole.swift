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
}
