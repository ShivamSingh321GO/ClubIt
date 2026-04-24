import SwiftUI

struct EventManagementApprovalDetailView: View {
    @Environment(AppSession.self) var appSession
    let club: Club
    
    @State private var selectedTab: String = "Resource"
    
    // Resource/Venue states
    @State private var selectedResourceForRemark: Resource?
    @State private var selectedVenueApprovalForRemark: Approval?
    @State private var showingResourceApprovalAlert = false
    @State private var resourceToApprove: Resource?
    @State private var showingVenueApprovalAlert = false
    @State private var venueToApprove: Approval?
    
    // Budget states
    @State private var selectedBudgetForRemark: Budget?
    @State private var showingBudgetApprovalAlert = false
    @State private var budgetToApprove: Budget?
    
    var body: some View {
        let clubEvents = appSession.eventStore.events.filter { $0.clubId == club.id }
        let clubEventIds = Set(clubEvents.map { $0.id })
        
        let allClubResources = appSession.approvalStore.resources.filter { clubEventIds.contains($0.eventId) }
        let allClubVenueApprovals = appSession.approvalStore.approvals.filter { 
            clubEventIds.contains($0.eventId) && $0.type == .venue 
        }
        let allClubBudgets = appSession.approvalStore.budgets.filter { clubEventIds.contains($0.eventId) }
        
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                
                // MARK: - Club Header
                ClubHeaderView(club: club, pendingResources: allClubResources)
                
                // MARK: - Segmented Filter (3 Segments)
                Picker("Select Category", selection: $selectedTab) {
                    Text("Resource (\(allClubResources.count))").tag("Resource")
                    Text("Venue (\(allClubVenueApprovals.count))").tag("Venue")
                    Text("Budget (\(allClubBudgets.count))").tag("Budget")
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // MARK: - Global Timestamp
                let allRequests = allClubResources.map { $0.createdAt } + allClubVenueApprovals.map { $0.createdAt } + allClubBudgets.map { $0.createdAt }
                if let latestRequest = allRequests.sorted(by: { $0 > $1 }).first {
                    HStack {
                        Image(systemName: "clock.fill")
                        Text("Requested on \(formatDate(latestRequest))")
                    }
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.top, -8)
                }
                
                // MARK: - Content List
                switch selectedTab {
                case "Resource":
                    resourceSection(allClubResources)
                case "Venue":
                    venueSection(allClubVenueApprovals)
                case "Budget":
                    budgetSection(allClubBudgets)
                default:
                    EmptyView()
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Approval Management")
        .navigationBarTitleDisplayMode(.inline)
        // Sheets
        .sheet(item: $selectedResourceForRemark) { resource in
            FacultyRemarkSheet(resource: resource)
        }
        .sheet(item: $selectedVenueApprovalForRemark) { approval in
            FacultyVenueRemarkSheet(approval: approval)
        }
        .sheet(item: $selectedBudgetForRemark) { budget in
            PresidentBudgetRemarkSheet(budget: budget)
        }
        // Resource Alert
        .alert("Confirm Approval", isPresented: $showingResourceApprovalAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Approve") {
                if let resource = resourceToApprove {
                    withAnimation {
                        appSession.approvalStore.updateResourceStatus(id: resource.id, status: .approved)
                    }
                }
            }
        } message: {
            if let resource = resourceToApprove {
                Text("Are you sure you want to approve the request for '\(resource.name)'?")
            }
        }
        // Venue Alert
        .alert("Confirm Approval", isPresented: $showingVenueApprovalAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Approve") {
                if let approval = venueToApprove {
                    withAnimation {
                        appSession.approvalStore.updateApproval(id: approval.id, status: .approved)
                    }
                }
            }
        } message: {
            if let approval = venueToApprove,
               let event = appSession.eventStore.events.first(where: { $0.id == approval.eventId }) {
                Text("Are you sure you want to approve the venue booking for '\(event.location)'?")
            }
        }
        // Budget Alert
        .alert("Confirm Approval", isPresented: $showingBudgetApprovalAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Approve") {
                if let budget = budgetToApprove {
                    withAnimation {
                        appSession.approvalStore.updateBudgetStatus(id: budget.id, status: .approved)
                    }
                }
            }
        } message: {
            if let budget = budgetToApprove {
                Text("Are you sure you want to approve the budget for '\(budget.itemName)'?")
            }
        }
    }
    
    @ViewBuilder
    private func resourceSection(_ resources: [Resource]) -> some View {
        VStack(spacing: 20) {
            // MARK: - Resource Summary Cards
            let totalRequestedRental = resources.filter { $0.type == .external }.reduce(0) { $0 + ($1.cost ?? 0) }
            let totalApprovedRental = resources.filter { $0.type == .external && $0.status == .approved }.reduce(0) { $0 + ($1.cost ?? 0) }
            
            HStack(spacing: 12) {
                // Requested Rental Card
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.orange.opacity(0.1))
                                .frame(width: 32, height: 32)
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.caption)
                                .foregroundColor(.orange)
                        }
                        Spacer()
                        Text("REQUESTED RENTAL")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                    
                    Text("₹\(String(format: "%.0f", totalRequestedRental))")
                        .font(.title3.bold())
                        .foregroundColor(.primary)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                        )
                )
                
                // Approved Rental Card
                VStack(alignment: .leading, spacing: 8) {
                    HStack {
                        ZStack {
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.green.opacity(0.1))
                                .frame(width: 32, height: 32)
                            Image(systemName: "checkmark.shield.fill")
                                .font(.caption)
                                .foregroundColor(.green)
                        }
                        Spacer()
                        Text("APPROVED RENTAL")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.secondary)
                    }
                    
                    Text("₹\(String(format: "%.0f", totalApprovedRental))")
                        .font(.title3.bold())
                        .foregroundColor(.primary)
                }
                .padding(16)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 20)
                        .fill(.ultraThinMaterial)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                        )
                )
            }
            .padding(.horizontal)
            
            ResourceListView(
                resources: resources,
                onReject: { resource in
                    selectedResourceForRemark = resource
                },
                onApprove: { resource in
                    resourceToApprove = resource
                    showingResourceApprovalAlert = true
                }
            )
        }
    }
    
    @ViewBuilder
    private func venueSection(_ approvals: [Approval]) -> some View {
        VenueListView(
            approvals: approvals,
            onReject: { approval in
                selectedVenueApprovalForRemark = approval
            },
            onApprove: { approval in
                venueToApprove = approval
                showingVenueApprovalAlert = true
            }
        )
    }
    
    @ViewBuilder
    private func budgetSection(_ budgets: [Budget]) -> some View {
        if budgets.isEmpty {
            VStack(spacing: 20) {
                Image(systemName: "tray")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary.opacity(0.5))
                Text("No budget requests found")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 60)
        } else {
            VStack(spacing: 20) {
                // MARK: - Budget Summary Cards
                let totalRequested = budgets.reduce(0) { $0 + $1.totalAmount }
                let totalApproved = budgets.filter { $0.status == .approved }.reduce(0) { $0 + $1.totalAmount }
                
                HStack(spacing: 12) {
                    // Requested Card
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.orange.opacity(0.1))
                                    .frame(width: 32, height: 32)
                                Image(systemName: "clock.arrow.circlepath")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                            Spacer()
                            Text("REQUESTED")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.secondary)
                        }
                        
                        Text("₹\(String(format: "%.0f", totalRequested))")
                            .font(.title3.bold())
                            .foregroundColor(.primary)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                            )
                    )
                    
                    // Approved Card
                    VStack(alignment: .leading, spacing: 8) {
                        HStack {
                            ZStack {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.green.opacity(0.1))
                                    .frame(width: 32, height: 32)
                                Image(systemName: "checkmark.shield.fill")
                                    .font(.caption)
                                    .foregroundColor(.green)
                            }
                            Spacer()
                            Text("APPROVED")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundColor(.secondary)
                        }
                        
                        Text("₹\(String(format: "%.0f", totalApproved))")
                            .font(.title3.bold())
                            .foregroundColor(.primary)
                    }
                    .padding(16)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 20)
                                    .stroke(Color.white.opacity(0.1), lineWidth: 0.5)
                            )
                    )
                }
                .padding(.horizontal)

                VStack(spacing: 16) {
                    ForEach(budgets.sorted(by: { $0.createdAt > $1.createdAt })) { budget in
                        PresidentBudgetRequestCard(
                            budget: budget,
                            onReject: { selectedBudgetForRemark = budget },
                            onApprove: {
                                budgetToApprove = budget
                                showingBudgetApprovalAlert = true
                            }
                        )
                    }
                }
                .padding(.horizontal)
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

#Preview {
    NavigationStack {
        EventManagementApprovalDetailView(club: MockData.technoJamClub)
            .environment(MockData.session(for: .faculty))
    }
}
