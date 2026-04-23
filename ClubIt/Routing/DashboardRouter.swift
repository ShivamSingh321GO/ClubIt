//
//  DashboardRouter.swift
//  ConnexusRe
//
//  Created by Ansh Srivastava on 3/19/26.
//


import SwiftUI

struct DashboardRouter: View {
    @Environment(AppSession.self) private var appSession

    var body: some View {
        Group {
            switch appSession.currentRole {
            case .admin:
                AdminDashboardView()
            case .faculty:
                FacultyDashboardView()
            case .president:
                PresidentDashboardView()
            case .vicePresident:
                VicePresidentDashboardView()
            case .clubLead:
                ClubLeadDashboardView()
            case .clubMember:
                ClubMemberDashboardView()
            case .student:
                StudentDashboardView()
            case .none:
                SignInView()
            }
        }
    }
}
