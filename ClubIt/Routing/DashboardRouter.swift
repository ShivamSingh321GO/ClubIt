//
//  DashboardRouter.swift
//  ConnexusRe
//
//  Created by Ansh Srivastava on 3/19/26.
//


import SwiftUI
import ClubItShared

struct DashboardRouter: View {
    @Environment(AppSession.self) private var appSession

    var body: some View {
        let activeRole = appSession.currentRole ?? appSession.currentUser?.role
        
        Group {
            switch activeRole {
            case .admin, .superAdmin:
                OrgAdminDashboardView()
            case .groupLead:
                GroupLeadDashboardView()
            case .groupSubLead:
                GroupSubLeadDashboardView()
            case .subGroupLead:
                SubGroupLeadView()
            case .subGroupMember:
                SubGroupMemberView()
            case .guest:
                GuestDashboardView()
            case .none:
                SignInView()
            }
        }
    }
}
