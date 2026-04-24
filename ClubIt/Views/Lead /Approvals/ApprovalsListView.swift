//
//  ApprovalsListView.swift
//  ClubIt
//
//  Approvals screen showing event approval requests with status tracking.
//

import SwiftUI

struct ApprovalsListView: View {
    @Environment(AppSession.self) var appSession
    let user: User
    
    @State private var selectedEventId: UUID? = nil
    
    
    var body: some View {
        let sortedApprovals = appSession.approvalStore.approvals.filter { approval in
            if appSession.currentRole == .president {
                // President sees incoming budget requests
                return approval.type == .budget && approval.status == .pending
            } else {
                // Leads see their sent approvals
                return approval.senderId == user.id && approval.type == .event
            }
        }
        
        let uniqueEvents = Array(Set(sortedApprovals.compactMap { $0.eventId }))
        
        ScrollView(showsIndicators: false) {
            VStack(spacing: 16) {
                if sortedApprovals.isEmpty {
                    ContentUnavailableView(
                        appSession.currentRole == .president ? "No Budget Requests" : "No Approvals Sent",
                        systemImage: appSession.currentRole == .president ? "indianrupeesign.circle" : "paperplane",
                        description: Text(appSession.currentRole == .president ? "Pending budget requests will appear here." : "Created events will generate approval requests here.")
                    )
                    .padding(.top, 40)
                } else {
                    ForEach(uniqueEvents, id: \.self) { eventId in
                        if let event = appSession.eventStore.events.first(where: { $0.id == eventId }) {
                            ApprovalSummaryCard(
                                title: event.name,
                                subtitle: appSession.currentRole == .president ? "Budget Request • \(formatDate(event.createdAt))" : "Created by you • \(formatDate(event.createdAt))",
                                action: { selectedEventId = event.id }
                            )
                        }
                    }
                }
            }
            //.padding(16)
        }
        .navigationTitle(appSession.currentRole == .president ? "Budget Requests" : "Approval Requests")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $selectedEventId) { id in
            EventApprovalsDetailView(eventId: id)
        }
    }
    
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}


    
#Preview {
    
    let session = AppSession()
    session.currentUser = MockData.clubLeadUser
    return NavigationStack {
        ApprovalsListView(user: MockData.clubLeadUser)
            .environment(session)
    }
}
  
