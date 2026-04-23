//
//  AppRole.swift
//  ConnexusRe
//
//  Created by Ansh Srivastava on 3/19/26.
//


import Foundation

enum AppRole: String, Codable, CaseIterable, Identifiable {
    case admin = "Admin"
    case faculty = "Faculty Advisor"
    case president = "President"
    case vicePresident = "Vice President"
    case clubLead = "Club Lead"
    case clubMember = "Club Member"
    case student = "Student"

    var id: String { rawValue }
}
