import SwiftUI


struct EventManagementApprovalDetailView: View {
    @Environment(AppSession.self) var appSession
    let club: Club
    let event: Event
    
    @State private var selectedTab: String = "Venue"
    
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
    
    // Event states
    @State private var selectedEventApprovalForRemark: Approval?
    @State private var showingEventApprovalAlert = false
    @State private var eventToApprove: Approval?
    
    var body: some View {
        let allClubResources = appSession.approvalStore.resources.filter { $0.eventId == event.id }
        let allClubVenueApprovals = appSession.approvalStore.approvals.filter { 
            $0.eventId == event.id && $0.type == .venue 
        }
        let allClubBudgets = appSession.approvalStore.budgets.filter { $0.eventId == event.id }
        let allClubEventApprovals = appSession.approvalStore.approvals.filter { 
            $0.eventId == event.id && $0.type == .event 
        }
        
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                
                // MARK: - Club Header
                ClubHeaderView(club: club, event: event)
                
                // MARK: - Segmented Filter (3 Segments)
                Picker("Select Category", selection: $selectedTab) {
                    Text("Venue (\(allClubVenueApprovals.count))").tag("Venue")
                    Text("Budget (\(allClubBudgets.count))").tag("Budget")
                    Text("Resource (\(allClubResources.count))").tag("Resource")
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                // MARK: - Global Timestamp
                let allRequests = allClubResources.map { $0.createdAt } + allClubVenueApprovals.map { $0.createdAt } + allClubBudgets.map { $0.createdAt } + allClubEventApprovals.map { $0.createdAt }
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
                case "Venue":
                    venueSection(allClubVenueApprovals)
                case "Budget":
                    budgetSection(allClubBudgets)
                case "Resource":
                    resourceSection(allClubResources)
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
                        appSession.checkAndAutoApproveEvent(eventId: event.id)
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
                        appSession.checkAndAutoApproveEvent(eventId: event.id)
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
                        appSession.checkAndAutoApproveEvent(eventId: event.id)
                    }
                }
            }
        } message: {
            if let budget = budgetToApprove {
                Text("Are you sure you want to approve the budget for '\(budget.itemName)'?")
            }
        }
        // Event Alert
        .alert("Confirm Approval", isPresented: $showingEventApprovalAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Approve") {
                if let approval = eventToApprove {
                    withAnimation {
                        appSession.approvalStore.updateApproval(id: approval.id, status: .approved)
                        // Sync event status
                        appSession.eventStore.updateEventStatus(id: approval.eventId, status: .upcoming)
                    }
                }
            }
        } message: {
            if let approval = eventToApprove,
               let event = appSession.eventStore.events.first(where: { $0.id == approval.eventId }) {
                Text("Are you sure you want to approve the creation of event '\(event.name)'?")
            }
        }
        .sheet(item: $selectedEventApprovalForRemark) { approval in
            FacultyVenueRemarkSheet(approval: approval, onReject: { remark in
                let newRemark = Remark(text: remark, authorId: appSession.currentUser?.id ?? UUID(), authorName: appSession.currentUser?.name ?? "EMT", createdAt: Date())
                appSession.approvalStore.updateApproval(id: approval.id, status: .rejected, remark: newRemark)
                appSession.eventStore.updateEventStatus(id: approval.eventId, status: .cancelled)
            })
        }
    }
    
    @ViewBuilder
    private func eventSection(_ approvals: [Approval]) -> some View {
        if approvals.isEmpty {
            VStack(spacing: 20) {
                Image(systemName: "calendar.badge.plus")
                    .font(.system(size: 48))
                    .foregroundColor(.secondary.opacity(0.5))
                Text("No event creation requests")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, 60)
        } else {
            VStack(spacing: 16) {
                ForEach(approvals.sorted(by: { $0.createdAt > $1.createdAt })) { approval in
                    if let event = appSession.eventStore.events.first(where: { $0.id == approval.eventId }) {
                        EventApprovalRequestCard(
                            event: event,
                            approval: approval,
                            onReject: { selectedEventApprovalForRemark = approval },
                            onApprove: {
                                eventToApprove = approval
                                showingEventApprovalAlert = true
                            }
                        )
                    }
                }
            }
            .padding(.horizontal)
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
        EventManagementApprovalDetailView(club: MockData.technoJamClub, event: MockData.sampleEvents[0])
            .environment(MockData.session(for: .faculty))
    }
}

struct EventApprovalRequestCard: View {
    @Environment(AppSession.self) var appSession
    let event: Event
    let approval: Approval
    let onReject: () -> Void
    let onApprove: () -> Void
    @State private var replyText: String = ""
    @State private var showingReply: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(event.name)
                        .font(.headline)
                    Text(event.category.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                ApprovalStatusBadge(status: approval.status)
            }
            
            Divider()
                .opacity(0.5)
            
            HStack {
                Label(event.startDate.formatted(date: .abbreviated, time: .shortened), systemImage: "calendar")
                    .font(.caption)
                Spacer()
                Label(event.location, systemImage: "mappin.and.ellipse")
                    .font(.caption)
            }
            .foregroundColor(.secondary)
            
            if !approval.remarks.isEmpty {
                VStack(alignment: .leading, spacing: 8) {
                    Text("REMARKS")
                        .font(.system(size: 8, weight: .bold))
                        .foregroundColor(.secondary)
                    
                    RemarkConversationView(remarks: approval.remarks)
                }
                .padding(.top, 4)
            }
            
            if showingReply {
                ReplyInputView(replyText: $replyText, onSend: {
                    let newRemark = Remark(text: replyText, authorId: appSession.currentUser?.id ?? UUID(), authorName: appSession.currentUser?.name ?? "Faculty", createdAt: Date())
                    appSession.approvalStore.addRemarkToApproval(id: approval.id, remark: newRemark)
                    replyText = ""
                    showingReply = false
                }, onCancel: {
                    showingReply = false
                    replyText = ""
                })
            } else {
                Button(action: { withAnimation { showingReply = true } }) {
                    Label("Reply to Lead", systemImage: "arrowshape.turn.up.left.fill")
                        .font(.caption.bold())
                        .foregroundColor(.blue)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Capsule())
                }
                .padding(.top, 4)
            }
            
            if approval.status == .pending {
                HStack(spacing: 12) {
                    Button(action: onReject) {
                        Text("Reject")
                            .font(.subheadline.bold())
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.red.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    
                    Button(action: onApprove) {
                        Text("Approve")
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 8)
                            .background(Color.blue)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(16)
        .glassEffect(in: .rect(cornerRadius: 24))
    }
}

struct ApprovalStatusBadge: View {
    let status: ApprovalStatus
    
    var body: some View {
        Text(status.rawValue.capitalized)
            .font(.caption2.bold())
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.1))
            .foregroundColor(color)
            .clipShape(Capsule())
    }
    
    var color: Color {
        switch status {
        case .pending: return .orange
        case .approved: return .green
        case .rejected: return .red
        }
    }
}
