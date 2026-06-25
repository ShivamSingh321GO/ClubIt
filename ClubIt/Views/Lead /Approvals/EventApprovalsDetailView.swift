//
//  EventApprovalsDetailView.swift
//  ClubIt
//
//  
//

import SwiftUI
import ClubItShared

struct EventApprovalsDetailView: View {
    @Environment(AppSession.self) var appSession
    let eventId: UUID
    
    var detailApprovals: [Approval] {
        appSession.approvalStore.approvals.filter { $0.eventId == eventId }
    }
    
    var body: some View {
        ZStack {

            //Color.f2Background.ignoresSafeArea()
            
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    ForEach(detailApprovals) { approval in
                        HomeApprovalCard(approval: approval, showTrack: true)
                    }
                }
                //.padding(16)
            }
        }
        .navigationTitle(appSession.eventStore.events.first(where: { $0.id == eventId })?.name ?? "Event Approvals")
        .navigationBarTitleDisplayMode(.inline)
    }
}


#Preview {
    NavigationStack {
        EventApprovalsDetailView(eventId: UUID())
            .environment(AppSession())
    }
}

