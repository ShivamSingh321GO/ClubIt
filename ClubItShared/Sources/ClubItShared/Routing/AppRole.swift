//
//  AppRole.swift
//  ConnexusRe
//
//  Created by Ansh Srivastava on 3/19/26.
//


import Foundation

public enum AppRole: String, Codable, CaseIterable, Identifiable {
    case admin = "admin"
    case faculty = "faculty"
    case president = "president"
    case vicePresident = "vicePresident"
    case clubLead = "clubLead"
    case clubMember = "clubMember"
    case student = "student"

    public var id: String { rawValue }
}
