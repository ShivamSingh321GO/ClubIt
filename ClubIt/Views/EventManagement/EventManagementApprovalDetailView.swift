import SwiftUI


struct EventManagementApprovalDetailView: View {
    @Environment(AppSession.self) var appSession
    @Environment(\.dismiss) private var dismiss
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
    
    // Reply states
    @State private var replyingToApprovalId: UUID? = nil
    @State private var replyText: String = ""
    
    @State private var isProcessingApproval = false
    
    var body: some View {
        Group {
            if appSession.currentRole == .vicePresident {
                vpDraftReviewView()
            } else {
                standardApprovalView()
            }
        }
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
        .sheet(item: $selectedEventApprovalForRemark) { approval in
            FacultyVenueRemarkSheet(approval: approval)
        }
        // Resource Alert
        .alert("Confirm Approval", isPresented: $showingResourceApprovalAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Approve") {
                if let resource = resourceToApprove {
                    Task {
                        do {
                            try await appSession.approvalStore.updateResourceStatus(id: resource.id, status: .approved)
                            await appSession.checkAndAutoApproveEvent(eventId: event.id)
                        } catch {
                            print("DEBUG ERROR: Resource approval failed: \(error)")
                        }
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
                    Task {
                        do {
                            try await appSession.approvalStore.updateApproval(id: approval.id, status: .approved)
                            await appSession.checkAndAutoApproveEvent(eventId: event.id)
                        } catch {
                            print("DEBUG ERROR: Venue approval failed: \(error)")
                        }
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
                    Task {
                        do {
                            try await appSession.approveBudgetAndCheckForwarding(budget: budget, status: .approved)
                            await appSession.checkAndAutoApproveEvent(eventId: event.id)
                        } catch {
                            print("DEBUG ERROR: Budget approval failed: \(error)")
                        }
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
                    Task {
                        isProcessingApproval = true
                        defer { isProcessingApproval = false }
                        
                        if appSession.currentRole == .vicePresident {
                            try? await appSession.approvalStore.updateApproval(id: approval.id, status: .approved)
                            if let event = appSession.eventStore.events.first(where: { $0.id == approval.eventId }) {
                                await appSession.chatStore.createEventChatsForPublishedEvent(event: event)
                            }
                            if let event = appSession.eventStore.events.first(where: { $0.id == approval.eventId }),
                               let club = appSession.clubStore.allClubs.first(where: { $0.id == event.clubId }) {
                                try? await appSession.forwardToPresidentBudgetApproval(
                                    eventId: event.id,
                                    club: club,
                                    senderId: appSession.currentUser?.id ?? UUID()
                                )
                            }
                        } else {
                            try? await appSession.approvalStore.updateApproval(id: approval.id, status: .approved)
                            // Sync event status
                            try? await appSession.eventStore.updateEventStatus(id: approval.eventId ?? UUID(), status: .approved)
                            
                            if let event = appSession.eventStore.events.first(where: { $0.id == approval.eventId }) {
                                await appSession.chatStore.createEventChatsForPublishedEvent(event: event)
                            }
                        }
                    }
                }
            }
        } message: {
            if let approval = eventToApprove,
               let event = appSession.eventStore.events.first(where: { $0.id == approval.eventId }) {
                Text(appSession.currentRole == .vicePresident ? "Are you sure you want to approve and forward event '\(event.name)'?" : "Are you sure you want to approve the creation of event '\(event.name)'?")
            }
        }
        .overlay(alignment: .bottom) {
            if let approvalId = replyingToApprovalId {
                GlobalReplyBar(
                    text: $replyText,
                    onSend: {
                        let content = replyText
                        Task {
                            try? await appSession.approvalStore.addRemark(
                                approvalId: approvalId,
                                authorId: appSession.currentUser?.id ?? UUID(),
                                content: content
                            )
                        }
                        replyText = ""
                        replyingToApprovalId = nil
                    },
                    onCancel: {
                        replyingToApprovalId = nil
                        replyText = ""
                    }
                )
            }
        }
        .onAppear {
            if appSession.currentRole == .president {
                selectedTab = "Budget"
            }
        }
        .overlay {
            if isProcessingApproval {
                ZStack {
                    Color.black.opacity(0.3).ignoresSafeArea()
                    VStack {
                        ProgressView()
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(12)
                        Text("Processing...")
                            .font(.caption)
                            .foregroundColor(.white)
                    }
                }
            }
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
                            },
                            onReply: {
                                withAnimation {
                                    replyingToApprovalId = approval.id
                                    replyText = ""
                                }
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
                                .fill(Color.accentColor.opacity(0.1))
                                .frame(width: 32, height: 32)
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.caption)
                                .foregroundColor(.accentColor)
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
                },
                onReply: { resource in
                    withAnimation {
                        if let approvalId = appSession.approvalStore.approvals.first(where: { $0.approvalRelatedId == resource.id })?.id {
                            replyingToApprovalId = approvalId
                            replyText = ""
                        }
                    }
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
            },
            onReply: { approval in
                withAnimation {
                    replyingToApprovalId = approval.id
                    replyText = ""
                }
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
            if appSession.currentRole == .faculty {
                VStack(spacing: 20) {
                    let totalRequested = budgets.reduce(0) { $0 + $1.totalAmount }
                    let anyRejected = budgets.contains { $0.status == .rejected }
                    let allApproved = budgets.allSatisfy { $0.status == .approved }
                    let status: ApprovalStatus = anyRejected ? .rejected : (allApproved ? .approved : .pending)
                    
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Budget Approval Overview")
                                    .font(.headline)
                                Text("Total Estimated Amount: ₹\(String(format: "%.0f", totalRequested))")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            ApprovalStatusBadge(status: status)
                        }
                        
                        Divider().opacity(0.5)
                        
                        Text(status == .approved ? "The budget request has been approved by the President." : (status == .rejected ? "The budget request was rejected by the President." : "The budget request is currently pending President's approval."))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(20)
                    .glassEffect(in: .rect(cornerRadius: 24))
                }
                .padding(.horizontal)
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
                                        .fill(Color.accentColor.opacity(0.1))
                                        .frame(width: 32, height: 32)
                                    Image(systemName: "clock.arrow.circlepath")
                                        .font(.caption)
                                        .foregroundColor(.accentColor)
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
                                },
                                onReply: {
                                    withAnimation {
                                        if let approvalId = appSession.approvalStore.approvals.first(where: { $0.approvalRelatedId == budget.id })?.id {
                                            replyingToApprovalId = approvalId
                                            replyText = ""
                                        }
                                    }
                                }
                            )
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    @ViewBuilder
    private func standardApprovalView() -> some View {
        let allClubResources = appSession.approvalStore.resources.filter { resource in
            resource.eventId == event.id &&
            appSession.approvalStore.approvals.contains { $0.approvalRelatedId == resource.id && $0.type == .resource }
        }
        let allClubVenueApprovals = appSession.approvalStore.approvals.filter { 
            $0.eventId == event.id && $0.type == .venue 
        }
        let allClubBudgets = appSession.approvalStore.budgets.filter { budget in
            budget.eventId == event.id &&
            appSession.approvalStore.approvals.contains { $0.approvalRelatedId == budget.id && $0.type == .budget }
        }
        let allClubEventApprovals = appSession.approvalStore.approvals.filter { 
            $0.eventId == event.id && $0.type == .event 
        }
        
        let venueApprovalsToDisplay: [Approval] = {
            if allClubVenueApprovals.isEmpty && !event.location.isEmpty {
                return [Approval(
                    id: UUID(),
                    type: .venue,
                    senderId: event.createdBy,
                    receiverId: club.facultyId ?? UUID(uuidString: "b02ff9cf-dce8-4be9-8fc6-a0d15c03ddad")!,
                    eventId: event.id,
                    approvalRelatedId: event.id,
                    status: .pending,
                    remarks: [],
                    createdAt: event.createdAt,
                    updatedAt: nil
                )]
            }
            return allClubVenueApprovals
        }()
        
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                // MARK: - Club Header
                ClubHeaderView(club: club, event: event)
                
                // MARK: - Segmented Filter (3 Segments)
                if appSession.currentRole != .president {
                    Picker("Select Category", selection: $selectedTab) {
                        Text("Venue (\(venueApprovalsToDisplay.count))").tag("Venue")
                        Text("Resource (\(allClubResources.count))").tag("Resource")
                        if appSession.currentUser?.email != "emt" {
                            Text("Budget (\(allClubBudgets.count))").tag("Budget")
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                }
                
                // MARK: - Global Timestamp
                let resDates = allClubResources.map { $0.createdAt }
                let venueDates = venueApprovalsToDisplay.map { $0.createdAt }
                let budgetDates = allClubBudgets.map { $0.createdAt }
                let eventDates = allClubEventApprovals.map { $0.createdAt }
                let allDates = resDates + venueDates + budgetDates + eventDates
                
                if let latestRequest = allDates.sorted(by: { $0 > $1 }).first {
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
                    venueSection(venueApprovalsToDisplay)
                case "Resource":
                    resourceSection(allClubResources)
                case "Budget":
                    budgetSection(allClubBudgets)
                default:
                    EmptyView()
                }
            }
            .padding(.vertical)
        }
        .refreshable {
            await appSession.refreshData()
            let relevantApprovals = appSession.approvalStore.approvals.filter { $0.eventId == event.id }
            for approval in relevantApprovals {
                try? await appSession.approvalStore.fetchRemarks(for: approval.id)
            }
        }
        .navigationTitle("Approval Management")
    }
    
    @ViewBuilder
    private func vpDraftReviewView() -> some View {
        let allClubResources = appSession.approvalStore.resources.filter { $0.eventId == event.id }
        let allClubBudgets = appSession.approvalStore.budgets.filter { $0.eventId == event.id }
        let allClubEventApprovals = appSession.approvalStore.approvals.filter { 
            $0.eventId == event.id && $0.type == .event 
        }
        let vpApproval = allClubEventApprovals.sorted(by: { $0.createdAt > $1.createdAt }).first(where: { $0.receiverId == appSession.currentUser?.id && $0.type == .event })
        let isEdited = allClubEventApprovals.count > 1 && vpApproval?.status == .pending
        
        ZStack(alignment: .bottom) {
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 20) {
                    // Header
                    ClubHeaderView(club: club, event: event, isEditedAfterApproval: isEdited)
                    
                    // Event Details Section
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Event Details")
                            .font(.headline)
                            .foregroundColor(.accentColor)
                        
                        VStack(alignment: .leading, spacing: 16) {
                            HStack(alignment: .top) {
                                Label("Date & Time", systemImage: "calendar")
                                    .font(.subheadline.bold())
                                Spacer()
                                VStack(alignment: .trailing, spacing: 4) {
                                    Text(event.dashboardDateLine1)
                                        .font(.caption)
                                        .multilineTextAlignment(.trailing)
                                    Text(event.dashboardDateLine2)
                                        .font(.caption2)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.trailing)
                                }
                            }
                            
                            Divider().opacity(0.3)
                            
                            HStack(alignment: .top) {
                                Label("Venue requested", systemImage: "mappin.and.ellipse")
                                    .font(.subheadline.bold())
                                Spacer(minLength: 16)
                                Text(event.location)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                                    .multilineTextAlignment(.trailing)
                            }
                            
                            if !event.description.isEmpty {
                                Divider().opacity(0.3)
                                VStack(alignment: .leading, spacing: 6) {
                                    Text("Description")
                                        .font(.subheadline.bold())
                                    Text(event.description)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .lineSpacing(4)
                                }
                            }
                        }
                        .padding()
                        .glassEffect(in: .rect(cornerRadius: 20))
                    }
                    .padding(.horizontal)
                    
                    // Budgets Requested
                    if !allClubBudgets.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            let totalBudget = allClubBudgets.reduce(0) { $0 + $1.totalAmount }
                            HStack {
                                Text("Budgets Requested (\(allClubBudgets.count))")
                                    .font(.headline)
                                Spacer()
                                Text("Total: ₹\(String(format: "%.0f", totalBudget))")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.accentColor)
                            }
                            
                            VStack(spacing: 8) {
                                ForEach(allClubBudgets) { budget in
                                    HStack {
                                        Text(budget.itemName)
                                            .font(.subheadline)
                                        Spacer()
                                        Text("\(budget.quantity) x ₹\(String(format: "%.0f", budget.unitPrice))")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.vertical, 4)
                                    if budget.id != allClubBudgets.last?.id {
                                        Divider().opacity(0.3)
                                    }
                                }
                            }
                            .padding()
                            .glassEffect(in: .rect(cornerRadius: 20))
                        }
                        .padding(.horizontal)
                    }
                    
                    // Resources Requested
                    if !allClubResources.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Resources Requested (\(allClubResources.count))")
                                .font(.headline)
                            
                            VStack(spacing: 8) {
                                ForEach(allClubResources) { res in
                                    HStack {
                                        VStack(alignment: .leading, spacing: 2) {
                                            Text(res.name)
                                                .font(.subheadline)
                                            Text(res.type == .university ? "University Resource" : "External Rental")
                                                .font(.system(size: 10))
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        Text("Qty: \(res.quantity)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .padding(.vertical, 4)
                                    if res.id != allClubResources.last?.id {
                                        Divider().opacity(0.3)
                                    }
                                }
                            }
                            .padding()
                            .glassEffect(in: .rect(cornerRadius: 20))
                        }
                        .padding(.horizontal)
                    }
                    
                    // Remarks History
                    if let approval = vpApproval {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Remarks")
                                .font(.headline)
                            ZStack {
                                Color.clear.frame(width: 0, height: 0)
                                    .onAppear {
                                        Task {
                                            try? await appSession.approvalStore.fetchRemarks(for: approval.id)
                                        }
                                    }
                                
                                if let remarks = appSession.approvalStore.remarkMessages[approval.id], !remarks.isEmpty {
                                    RemarkConversationView(approvalId: approval.id)
                                        .padding(12)
                                        .glassEffect(in: .rect(cornerRadius: 20))
                                }
                            }
                            
                            HStack {
                                Spacer()
                                Button(action: {
                                    withAnimation {
                                        replyingToApprovalId = approval.id
                                        replyText = ""
                                    }
                                }) {
                                    Label("Reply", systemImage: "arrowshape.turn.up.left.fill")
                                        .font(.caption.bold())
                                        .foregroundColor(.blue)
                                        .padding(.vertical, 8)
                                        .padding(.horizontal, 12)
                                        .background(Color.blue.opacity(0.1))
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                            .padding(.top, 4)
                        }
                        .padding(.horizontal)
                        
                        // Approve / Reject buttons flow naturally here
                        VStack(spacing: 0) {
                            if approval.status == .pending {
                                HStack(spacing: 12) {
                                    Button(role: .destructive, action: {
                                        selectedEventApprovalForRemark = approval
                                    }) {
                                        Label("Reject", systemImage: "xmark.circle")
                                            .frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(.bordered)
                                    .controlSize(.large)
                                    
                                    Button(action: {
                                        eventToApprove = approval
                                        showingEventApprovalAlert = true
                                    }) {
                                        Label("Approve Draft", systemImage: "checkmark.circle.fill")
                                            .frame(maxWidth: .infinity)
                                    }
                                    .buttonStyle(.borderedProminent)
                                    .tint(.green)
                                    .controlSize(.large)
                                }
                                .padding(.top, 16)
                            } else {
                                HStack {
                                    Text("Draft Review Completed:")
                                        .font(.headline)
                                    Spacer()
                                    ApprovalStatusBadge(status: approval.status)
                                }
                                .padding(.vertical, 16)
                            }
                        }
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .refreshable {
                await appSession.refreshData()
                let relevantApprovals = appSession.approvalStore.approvals.filter { $0.eventId == event.id }
                for approval in relevantApprovals {
                    try? await appSession.approvalStore.fetchRemarks(for: approval.id)
                }
            }
        }
        .navigationTitle("Event Draft Review")
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
    let onReply: () -> Void
    
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
            
            VStack(alignment: .leading, spacing: 8) {
                Text("REMARKS")
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.secondary)
                
                RemarkConversationView(approvalId: approval.id)
            }
            .padding(.top, 4)
            
            HStack {
                Spacer()
                Button(action: onReply) {
                    Label("Reply to Lead", systemImage: "arrowshape.turn.up.left.fill")
                        .font(.caption.bold())
                        .foregroundColor(.blue)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Capsule())
                }
            }
            .padding(.top, 4)
            
            if approval.status == .pending {
                HStack(spacing: 12) {
                    Button(role: .destructive, action: onReject) {
                        Text("Reject")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    
                    Button(action: onApprove) {
                        Text("Approve")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.blue)
                    .controlSize(.large)
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
        case .pending: return .accentColor
        case .approved: return .green
        case .rejected: return .red
        }
    }
}
