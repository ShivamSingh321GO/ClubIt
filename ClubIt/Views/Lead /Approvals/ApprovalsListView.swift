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
    @State private var selectedFilter: ApprovalFilter = .all
    
    enum ApprovalFilter: String, CaseIterable {
        case all = "All"
        case upcoming = "Upcoming"
        case pending = "Pending"
        case approved = "Approved"
        case rejected = "Rejected"
        case overdue = "Overdue"
    }
    
    private func getStatus(for eventId: UUID, sortedApprovals: [Approval]) -> ApprovalFilter {
        let pendingResources = appSession.approvalStore.resources.filter { 
            $0.eventId == eventId && $0.status == .pending 
        }
        let pendingVenues = appSession.approvalStore.approvals.filter { 
            $0.eventId == eventId && $0.type == .venue && $0.status == .pending 
        }
        let pendingBudgets = appSession.approvalStore.budgets.filter { 
            $0.eventId == eventId && $0.status == .pending 
        }
        
        let totalPending: Int
        let isRejected: Bool
        
        if appSession.currentRole == .president {
            totalPending = pendingBudgets.count
            isRejected = appSession.approvalStore.budgets.contains { $0.eventId == eventId && $0.status == .rejected }
        } else {
            let approval = sortedApprovals.first(where: { $0.eventId == eventId })
            totalPending = pendingResources.count + pendingVenues.count + pendingBudgets.count
            let mainRejected = approval?.status == .rejected
            isRejected = mainRejected || 
                         appSession.approvalStore.resources.contains { $0.eventId == eventId && $0.status == .rejected } ||
                         appSession.approvalStore.approvals.contains { $0.eventId == eventId && $0.type == .venue && $0.status == .rejected } ||
                         appSession.approvalStore.budgets.contains { $0.eventId == eventId && $0.status == .rejected }
        }
        
        if isRejected {
            return .rejected
        } else if totalPending > 0 {
            return .pending
        } else {
            return .approved
        }
    }
    
    private func count(for filter: ApprovalFilter, uniqueEvents: [UUID], sortedApprovals: [Approval]) -> Int {
        if filter == .all {
            return uniqueEvents.count
        }
        if filter == .upcoming {
            return uniqueEvents.filter { eventId in
                guard let event = appSession.eventStore.events.first(where: { $0.id == eventId }) else { return false }
                return event.startDate >= Calendar.current.startOfDay(for: Date())
            }.count
        }
        if filter == .overdue {
            return uniqueEvents.filter { eventId in
                guard let event = appSession.eventStore.events.first(where: { $0.id == eventId }) else { return false }
                let isPast = event.startDate < Calendar.current.startOfDay(for: Date())
                return isPast && getStatus(for: eventId, sortedApprovals: sortedApprovals) == .pending
            }.count
        }
        return uniqueEvents.filter { eventId in
            getStatus(for: eventId, sortedApprovals: sortedApprovals) == filter
        }.count
    }
    
    var body: some View {
        let sortedApprovals = appSession.approvalStore.approvals.filter { approval in
            if appSession.currentRole == .president {
                // President sees budget requests related to them
                return approval.type == .budget
            } else {
                // Leads see their sent approvals
                return approval.senderId == user.id && approval.type == .event
            }
        }

        let uniqueEvents = Array(Set(sortedApprovals.compactMap { $0.eventId })).sorted { id1, id2 in
            guard let event1 = appSession.eventStore.events.first(where: { $0.id == id1 }),
                  let event2 = appSession.eventStore.events.first(where: { $0.id == id2 }) else { return false }
            if Calendar.current.isDate(event1.startDate, inSameDayAs: event2.startDate) {
                return (event1.startTime ?? Date.distantFuture) < (event2.startTime ?? Date.distantFuture)
            }
            return event1.startDate < event2.startDate
        }
        
        let filteredEvents = uniqueEvents.filter { eventId in
            if selectedFilter == .all {
                return true
            }
            if selectedFilter == .upcoming {
                guard let event = appSession.eventStore.events.first(where: { $0.id == eventId }) else { return false }
                return event.startDate >= Calendar.current.startOfDay(for: Date())
            }
            if selectedFilter == .overdue {
                guard let event = appSession.eventStore.events.first(where: { $0.id == eventId }) else { return false }
                let isPast = event.startDate < Calendar.current.startOfDay(for: Date())
                return isPast && getStatus(for: eventId, sortedApprovals: sortedApprovals) == .pending
            }
            return getStatus(for: eventId, sortedApprovals: sortedApprovals) == selectedFilter
        }
        
        ZStack {
            VStack(spacing: 0) {
                if !sortedApprovals.isEmpty {
                    // Filter Bar
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            ForEach(ApprovalFilter.allCases, id: \.self) { filter in
                                ApprovalsFilterPill(
                                    title: "\(filter.rawValue) \(count(for: filter, uniqueEvents: uniqueEvents, sortedApprovals: sortedApprovals))",
                                    isSelected: selectedFilter == filter,
                                    action: {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            selectedFilter = filter
                                        }
                                    }
                                )
                            }
                        }
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 8)
                }
                
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        if sortedApprovals.isEmpty {
                            ContentUnavailableView(
                                appSession.currentRole == .president ? "No Budget Requests" : "No Approvals Sent",
                                systemImage: appSession.currentRole == .president ? "indianrupeesign.circle" : "paperplane",
                                description: Text(appSession.currentRole == .president ? "Pending budget requests will appear here." : "Created events will generate approval requests here.")
                            )
                            .padding(.top, 40)
                        } else if filteredEvents.isEmpty {
                            ContentUnavailableView(
                                "No \(selectedFilter.rawValue) Requests",
                                systemImage: selectedFilter == .pending ? "hourglass" : (selectedFilter == .approved ? "checkmark.circle" : (selectedFilter == .upcoming ? "calendar" : (selectedFilter == .overdue ? "exclamationmark.triangle" : "xmark.circle"))),
                                description: Text("No requests match the selected filter.")
                            )
                            .padding(.top, 40)
                        } else {
                            LazyVStack(spacing: 16) {
                                ForEach(filteredEvents, id: \.self) { eventId in
                                    if let event = appSession.eventStore.events.first(where: { $0.id == eventId }) {
                                        if appSession.currentRole == .president {
                                            if let club = appSession.clubStore.allClubs.first(where: { $0.id == event.clubId }) {
                                                NavigationLink(destination: EventManagementApprovalDetailView(club: club, event: event)) {
                                                    EventManagementEventApprovalCard(event: event, club: club)
                                                }
                                                .buttonStyle(.plain)
                                            }
                                        } else {
                                            if let approval = sortedApprovals.first(where: { $0.eventId == eventId }) {
                                                Button {
                                                    selectedEventId = event.id
                                                } label: {
                                                    LeadApprovalEventCard(event: event, approval: approval)
                                                }
                                                .buttonStyle(.plain)
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                    .padding(.vertical)
                }
                .refreshable {
                    await appSession.refreshData()
                }
            }
            
            if appSession.isRefreshing {
                VStack {
                    ProgressView()
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                    Text("Updating approvals...")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color.black.opacity(0.1))
                .transition(.opacity)
            }
        }

        .navigationTitle(appSession.currentRole == .president ? "Budget Requests" : "Approval Requests")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(item: $selectedEventId) { id in
            LeadEventApprovalDetailView(eventId: id)
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .full
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

// MARK: - Subcomponents
fileprivate struct ApprovalsFilterPill: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .bold()
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? Color.accent : Color.secondary.opacity(0.1))
                .foregroundColor(isSelected ? .white : .secondary)
                .clipShape(RoundedRectangle(cornerRadius: 20))
        }
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
  
