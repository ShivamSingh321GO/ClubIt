import SwiftUI

struct LeadEventApprovalDetailView: View {
    @Environment(AppSession.self) var appSession
    let eventId: UUID
    
    @State private var selectedTab: String = "Event"
    @State private var replyText: String = ""
    @State private var replyingToItemId: UUID? = nil
    @State private var replyingToType: ApprovalType? = nil
    
    var event: Event? {
        appSession.eventStore.events.first(where: { $0.id == eventId })
    }
    
    var club: Club? {
        guard let event = event else { return nil }
        return appSession.clubStore.allClubs.first(where: { $0.id == event.clubId })
    }

    private var allClubEventApprovals: [Approval] {
        if let vpApp = vpApproval {
            return [vpApp]
        }
        return []
    }

    private var allClubResources: [Resource] {
        guard let event = event else { return [] }
        return appSession.approvalStore.resources.filter { $0.eventId == event.id }
    }
    
    private var allClubVenueApprovals: [Approval] {
        guard let event = event else { return [] }
        let realVenueApprovals = appSession.approvalStore.approvals.filter { $0.eventId == event.id && $0.type == .venue }
        if realVenueApprovals.isEmpty && !event.location.isEmpty {
            return [Approval(
                id: UUID(),
                type: .venue,
                senderId: event.createdBy,
                receiverId: club?.facultyId ?? UUID(uuidString: "b02ff9cf-dce8-4be9-8fc6-a0d15c03ddad")!,
                eventId: event.id,
                approvalRelatedId: event.id,
                status: .pending,
                remarks: [],
                createdAt: event.createdAt,
                updatedAt: nil
            )]
        }
        return realVenueApprovals
    }
    
    private var allClubBudgets: [Budget] {
        guard let event = event else { return [] }
        return appSession.approvalStore.budgets.filter { $0.eventId == event.id }
    }
    
    private var mainApproval: Approval? {
        guard let event = event else { return nil }
        return appSession.approvalStore.approvals.first(where: { $0.eventId == event.id && $0.type == .event })
    }
    
    private var isAnyRejected: Bool {
        let isMainRejected = mainApproval?.status == .rejected
        let isResRejected = allClubResources.contains { $0.status == .rejected }
        let isVenueRejected = allClubVenueApprovals.contains { $0.status == .rejected }
        let isBudgetRejected = allClubBudgets.contains { $0.status == .rejected }
        return isMainRejected || isResRejected || isVenueRejected || isBudgetRejected
    }
    
    private var isAllApproved: Bool {
        let isMainApproved = mainApproval?.status == .approved
        let isResApproved = allClubResources.isEmpty || allClubResources.allSatisfy { $0.status == .approved }
        let isVenueApproved = allClubVenueApprovals.isEmpty || allClubVenueApprovals.allSatisfy { $0.status == .approved }
        let isBudgetApproved = allClubBudgets.isEmpty || allClubBudgets.allSatisfy { $0.status == .approved }
        return isMainApproved && isResApproved && isVenueApproved && isBudgetApproved
    }
    
    private var hasVP: Bool {
        guard let club = club else { return false }
        return club.vicePresidentId != nil
    }
    
    private var vpUser: User? {
        guard let club = club, let vpId = club.vicePresidentId else { return nil }
        return appSession.clubStore.allUsers.first(where: { $0.id == vpId })
    }
    
    private var allVpApprovals: [Approval] {
        guard let event = event, let club = club, let vpId = club.vicePresidentId else { return [] }
        return appSession.approvalStore.approvals.filter { 
            $0.eventId == event.id && $0.type == .event && $0.receiverId == vpId 
        }.sorted(by: { $0.createdAt > $1.createdAt })
    }
    
    private var vpApproval: Approval? {
        allVpApprovals.first
    }
    
    private var lastApprovedVpApproval: Approval? {
        allVpApprovals.first(where: { $0.status == .approved })
    }
    
    private var vpRejectionRemark: String? {
        guard let approval = vpApproval else { return nil }
        if let lastRemark = approval.remarks?.last?.content {
            return lastRemark
        }
        return appSession.approvalStore.remarkMessages[approval.id]?.last?.content
    }
    
    enum StepStatus {
        case locked
        case pending
        case approved
        case rejected
        case skipped
    }
    
    private var hasBudget: Bool {
        !allClubBudgets.isEmpty
    }
    
    private var presidentUser: User? {
        appSession.clubStore.allUsers.first(where: { $0.role == .president })
    }
    
    private var facultyUser: User? {
        guard let club = club else { return nil }
        let facultyId = club.facultyId
        return appSession.clubStore.allUsers.first(where: { $0.id == facultyId })
    }
    
    private var vpStepStatus: StepStatus {
        guard hasVP else { return .skipped }
        guard let approval = vpApproval else { return .pending }
        switch approval.status {
        case .pending: return .pending
        case .approved: return .approved
        case .rejected: return .rejected
        }
    }
    
    private var presidentStepStatus: StepStatus {
        if hasVP && vpStepStatus != .approved {
            return .locked
        }
        guard hasBudget else { return .skipped }
        
        let isAnyBudgetRejected = allClubBudgets.contains { $0.status == .rejected }
        let isAllBudgetApproved = allClubBudgets.allSatisfy { $0.status == .approved }
        
        if isAnyBudgetRejected {
            return .rejected
        } else if isAllBudgetApproved {
            return .approved
        } else {
            return .pending
        }
    }
    
    private var emtStepStatus: StepStatus {
        if hasVP && vpStepStatus != .approved { return .locked }
        if hasBudget && presidentStepStatus != .approved { return .locked }
        
        let eventManagementTeamID = UUID(uuidString: "b02ff9cf-dce8-4be9-8fc6-a0d15c03ddad")!
        let facultyId = club?.facultyId ?? eventManagementTeamID
        
        let emtApprovals = appSession.approvalStore.approvals.filter { 
            $0.eventId == eventId && 
            ($0.type == .event || $0.type == .venue) && 
            ($0.receiverId == facultyId || $0.receiverId == appSession.currentUser?.id)
        }
        
        let isAnyEmtRejected = emtApprovals.contains { $0.status == .rejected } || 
                               allClubResources.contains { $0.status == .rejected }
                               
        let isAllEmtApproved = !emtApprovals.isEmpty && 
                               emtApprovals.allSatisfy { $0.status == .approved } &&
                               allClubResources.allSatisfy { $0.status == .approved }
                               
        if isAnyEmtRejected {
            return .rejected
        } else if isAllEmtApproved {
            return .approved
        } else {
            return .pending
        }
    }
    
    private var presidentRejectionRemark: String? {
        if let rejectedBudget = allClubBudgets.first(where: { $0.status == .rejected }) {
            if let approval = appSession.approvalStore.approvals.first(where: { $0.approvalRelatedId == rejectedBudget.id }),
               let lastRemark = approval.remarks?.last?.content ?? appSession.approvalStore.remarkMessages[approval.id]?.last?.content {
                return "\(rejectedBudget.itemName): \(lastRemark)"
            }
        }
        return nil
    }
    
    private var emtRejectionRemark: String? {
        let eventManagementTeamID = UUID(uuidString: "b02ff9cf-dce8-4be9-8fc6-a0d15c03ddad")!
        let facultyId = club?.facultyId ?? eventManagementTeamID
        
        if let eventApproval = appSession.approvalStore.approvals.first(where: { 
            $0.eventId == eventId && 
            $0.type == .event && 
            ($0.receiverId == facultyId || $0.receiverId == appSession.currentUser?.id) &&
            $0.status == .rejected
        }) {
            return eventApproval.remarks?.last?.content ?? appSession.approvalStore.remarkMessages[eventApproval.id]?.last?.content
        }
        
        if let venueApproval = appSession.approvalStore.approvals.first(where: { 
            $0.eventId == eventId && 
            $0.type == .venue && 
            ($0.receiverId == facultyId || $0.receiverId == appSession.currentUser?.id) &&
            $0.status == .rejected
        }) {
            return venueApproval.remarks?.last?.content ?? appSession.approvalStore.remarkMessages[venueApproval.id]?.last?.content
        }
        
        if let rejectedResource = allClubResources.first(where: { $0.status == .rejected }) {
            if let approval = appSession.approvalStore.approvals.first(where: { $0.approvalRelatedId == rejectedResource.id }),
               let lastRemark = approval.remarks?.last?.content ?? appSession.approvalStore.remarkMessages[approval.id]?.last?.content {
                return "\(rejectedResource.name): \(lastRemark)"
            }
        }
        return nil
    }
    
    private func statusColor(for step: StepStatus) -> Color {
        switch step {
        case .locked: return .secondary
        case .pending: return .orange
        case .approved: return .green
        case .rejected: return .red
        case .skipped: return .secondary
        }
    }
    
    private func statusIcon(for step: StepStatus) -> String {
        switch step {
        case .locked: return "lock.fill"
        case .pending: return "clock.fill"
        case .approved: return "checkmark"
        case .rejected: return "xmark"
        case .skipped: return "checkmark"
        }
    }
    
    private func statusText(for step: StepStatus) -> String {
        switch step {
        case .locked: return "LOCKED"
        case .pending: return "PENDING"
        case .approved: return "APPROVED"
        case .rejected: return "REJECTED"
        case .skipped: return "SKIPPED"
        }
    }
    
    var body: some View {
        if let event = event, let club = club {

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // Club Header
                    LeadDetailClubHeaderView(club: club, event: event, canEdit: true, isEditedAfterApproval: vpStepStatus == .pending && lastApprovedVpApproval != nil)
                        .padding(.horizontal)
                    
                    // Sequential Approval Status Tracker
                    VStack(alignment: .leading, spacing: 16) {
                        Text("APPROVAL FLOW STATUS")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        VStack(alignment: .leading, spacing: 20) {
                            // Step 1: Vice President Draft Approval
                            HStack(alignment: .top, spacing: 12) {
                                VStack {
                                    Circle()
                                        .fill(statusColor(for: vpStepStatus))
                                        .frame(width: 24, height: 24)
                                        .overlay(
                                            Image(systemName: statusIcon(for: vpStepStatus))
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(.white)
                                        )
                                    
                                    Rectangle()
                                        .fill(statusColor(for: presidentStepStatus).opacity(0.3))
                                        .frame(width: 2, height: 30)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Step 1: Vice President Draft Approval")
                                        .font(.subheadline.bold())
                                    
                                    if hasVP, let vp = vpUser {
                                        Text("Reviewer: \(vp.name)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    } else {
                                        Text("Reviewer: N/A")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    HStack(spacing: 4) {
                                        Text("Status:")
                                            .foregroundColor(.secondary)
                                        Text(statusText(for: vpStepStatus))
                                            .foregroundColor(statusColor(for: vpStepStatus))
                                    }
                                    .font(.caption.bold())
                                    
                                    if vpStepStatus == .rejected, let remark = vpRejectionRemark {
                                        Text("Remark: \"\(remark)\"")
                                            .font(.caption.italic())
                                            .foregroundColor(.red)
                                            .padding(.top, 4)
                                    }
                                }
                                Spacer()
                            }
                            
                            // Step 2: President Budget Approval
                            HStack(alignment: .top, spacing: 12) {
                                VStack {
                                    Circle()
                                        .fill(statusColor(for: presidentStepStatus))
                                        .frame(width: 24, height: 24)
                                        .overlay(
                                            Image(systemName: statusIcon(for: presidentStepStatus))
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(.white)
                                        )
                                    
                                    Rectangle()
                                        .fill(statusColor(for: emtStepStatus).opacity(0.3))
                                        .frame(width: 2, height: 30)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Step 2: President Budget Approval")
                                        .font(.subheadline.bold())
                                    
                                    if let president = presidentUser {
                                        Text("Reviewer: \(president.name)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    HStack(spacing: 4) {
                                        Text("Status:")
                                            .foregroundColor(.secondary)
                                        Text(statusText(for: presidentStepStatus))
                                            .foregroundColor(statusColor(for: presidentStepStatus))
                                    }
                                    .font(.caption.bold())
                                    
                                    if presidentStepStatus == .rejected, let remark = presidentRejectionRemark {
                                        Text("Remark: \"\(remark)\"")
                                            .font(.caption.italic())
                                            .foregroundColor(.red)
                                            .padding(.top, 4)
                                    }
                                }
                                Spacer()
                            }
                            
                            // Step 3: Faculty (EMT) Final Review
                            HStack(alignment: .top, spacing: 12) {
                                VStack {
                                    Circle()
                                        .fill(statusColor(for: emtStepStatus))
                                        .frame(width: 24, height: 24)
                                        .overlay(
                                            Image(systemName: statusIcon(for: emtStepStatus))
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(.white)
                                        )
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Step 3: Faculty (EMT) Final Review")
                                        .font(.subheadline.bold())
                                    
                                    if let faculty = facultyUser {
                                        Text("Reviewer: \(faculty.name)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    } else {
                                        Text("Reviewers: Event Management Team & Faculty")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    
                                    HStack(spacing: 4) {
                                        Text("Status:")
                                            .foregroundColor(.secondary)
                                        Text(statusText(for: emtStepStatus))
                                            .foregroundColor(statusColor(for: emtStepStatus))
                                    }
                                    .font(.caption.bold())
                                    
                                    if emtStepStatus == .rejected, let remark = emtRejectionRemark {
                                        Text("Remark: \"\(remark)\"")
                                            .font(.caption.italic())
                                            .foregroundColor(.red)
                                            .padding(.top, 4)
                                    }
                                }
                                Spacer()
                            }
                        }
                        .padding()
                        .background(Color.primary.opacity(0.03))
                        .cornerRadius(20)
                        .overlay(
                            RoundedRectangle(cornerRadius: 20)
                                .stroke(Color.primary.opacity(0.08), lineWidth: 1)
                        )
                        .padding(.horizontal)
                    }


                    
                    // Segmented Filter
                    Picker("Select Category", selection: $selectedTab) {
                        Text("Event (\(allClubEventApprovals.count))").tag("Event")
                        Text("Venue (\(allClubVenueApprovals.count))").tag("Venue")
                        Text("Resource (\(allClubResources.count))").tag("Resource")
                        Text("Budget (\(allClubBudgets.count))").tag("Budget")
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    // Requested On
                    if let firstRequest = allClubResources.sorted(by: { $0.createdAt > $1.createdAt }).first {
                        HStack {
                            Image(systemName: "clock.fill")
                            Text("Requested on \(formatDate(firstRequest.createdAt))")
                        }
                        .font(.caption.bold())
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                        .padding(.top, -8)
                    }
                    
                    // Content List
                    switch selectedTab {
                    case "Event":
                        eventSection(allClubEventApprovals)
                    case "Venue":
                        venueSection(allClubVenueApprovals)
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
                let relevantApprovals = appSession.approvalStore.approvals.filter { $0.eventId == eventId }
                for approval in relevantApprovals {
                    try? await appSession.approvalStore.fetchRemarks(for: approval.id)
                }
            }
            .navigationTitle("Approval Management")
            .navigationBarTitleDisplayMode(.inline)
            .overlay(alignment: .bottom) {
                if replyingToItemId != nil {
                    replyInputOverlay()
                }
            }
        } else {
            ContentUnavailableView("Event Not Found", systemImage: "calendar.badge.exclamationmark")
        }
    }
    
    @ViewBuilder
    private func eventSection(_ approvals: [Approval]) -> some View {
        VStack(spacing: 16) {
            ForEach(approvals.sorted(by: { $0.createdAt > $1.createdAt })) { approval in
                VStack(alignment: .leading, spacing: 4) {
                    LeadItemApprovalCard(
                        title: "VP Draft Review",
                        icon: "doc.text.fill",
                        iconColor: .orange,
                        status: approval.status.rawValue,
                        details: [
                            (icon: nil, label: "Category", value: event?.category.rawValue ?? "N/A"),
                            (icon: nil, label: "Reviewer", value: vpUser?.name ?? "N/A")
                        ],
                        approvalId: approval.id,
                        onReply: {
                            replyingToItemId = approval.id
                            replyingToType = .event
                        }
                    )
                    
                    if approval.id == vpApproval?.id && approval.status == .pending, let lastApproved = lastApprovedVpApproval {
                        Text("Last approved on \(formatDateShort(lastApproved.createdAt))")
                            .font(.system(size: 10, weight: .semibold))
                            .foregroundColor(.secondary)
                            .padding(.leading, 12)
                    }
                }
            }
        }
        .padding(.horizontal)
    }

    @ViewBuilder
    private func resourceSection(_ resources: [Resource]) -> some View {
        let externalResources = resources.filter { $0.type == .external }
        let totalRequestedRental = externalResources.reduce(0) { $0 + ($1.cost ?? 0) }
        let approvedExternalResources = externalResources.filter { $0.status == .approved }
        let totalApprovedRental = approvedExternalResources.reduce(0) { $0 + ($1.cost ?? 0) }
        
        VStack(spacing: 20) {
            SummaryCardRow(requested: totalRequestedRental, approved: totalApprovedRental, label: "RENTAL")
            
            VStack(spacing: 16) {
                ForEach(resources.sorted(by: { $0.createdAt > $1.createdAt })) { resource in
                    LeadItemApprovalCard(
                        title: resource.name,
                        icon: "cart.fill",
                        iconColor: .orange,
                        status: resource.status.rawValue,
                        details: [
                            (icon: nil, label: "Quantity", value: "\(resource.quantity)"),
                            (icon: nil, label: "Source", value: resource.type == .university ? "University" : "External Rental")
                        ] + (resource.type == .external ? [
                            (icon: nil, label: "Rental Cost", value: "₹\(String(format: "%.0f", resource.cost ?? 0))"),
                            (icon: nil, label: "Vendor", value: resource.vendorName ?? "N/A")
                        ] : []),
                        approvalId: appSession.approvalStore.approvals.first(where: { $0.approvalRelatedId == resource.id })?.id,
                        onReply: {
                            replyingToItemId = resource.id
                            replyingToType = .resource
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
    }
    
    @ViewBuilder
    private func venueSection(_ approvals: [Approval]) -> some View {
        VStack(spacing: 16) {
            ForEach(approvals.sorted(by: { $0.createdAt > $1.createdAt })) { approval in
                LeadItemApprovalCard(
                    title: "Venue Booking",
                    subtitle: event?.location,
                    icon: "mappin.and.ellipse",
                    iconColor: .purple,
                    status: approval.status.rawValue,
                    details: [
                        (icon: "calendar", label: "Event Date", value: event != nil ? "\(event!.dashboardDateLine1)\n\(event!.dashboardDateLine2)" : formatDateShort(Date()))
                    ],
                    approvalId: approval.id,
                    onReply: {
                        replyingToItemId = approval.id
                        replyingToType = .venue
                    }
                )
            }
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private func budgetSection(_ budgets: [Budget]) -> some View {
        let totalRequested = budgets.reduce(0) { $0 + $1.totalAmount }
        let approvedBudgets = budgets.filter { $0.status == .approved }
        let totalApproved = approvedBudgets.reduce(0) { $0 + $1.totalAmount }
        
        VStack(spacing: 20) {
            SummaryCardRow(requested: totalRequested, approved: totalApproved, label: "BUDGET")
            
            VStack(spacing: 16) {
                ForEach(budgets.sorted(by: { $0.createdAt > $1.createdAt })) { budget in
                    PresidentBudgetRequestCard(
                        budget: budget,
                        onReject: {}, // Not applicable for Lead
                        onApprove: {}, // Not applicable for Lead
                        onReply: {
                            replyingToItemId = budget.id
                            replyingToType = .budget
                        }
                    )
                }
            }
            .padding(.horizontal)
        }
    }
    
    @ViewBuilder
    private func replyInputOverlay() -> some View {
        GlobalReplyBar(
            text: $replyText,
            onSend: sendReply,
            onCancel: {
                replyingToItemId = nil
                replyingToType = nil
                replyText = ""
            }
        )
    }
    
    private func sendReply() {
        guard let id = replyingToItemId, let type = replyingToType, let user = appSession.currentUser else { return }
        
        // Find the correct approval ID for this item
        let approvalId: UUID? = {
            if type == .venue || type == .event { return id }
            return appSession.approvalStore.approvals.first(where: { $0.approvalRelatedId == id })?.id
        }()
        
        guard let finalApprovalId = approvalId else {
            print("ERROR: Could not find approval ID for reply")
            return
        }
        
        let contentToSend = replyText // Capture here
        
        Task {
            do {
                try await appSession.approvalStore.addRemark(
                    approvalId: finalApprovalId,
                    authorId: user.id,
                    content: contentToSend
                )
                print("DEBUG: Remark sent successfully to approval \(finalApprovalId)")
            } catch {
                print("Error sending reply: \(error)")
            }
        }
        
        replyText = ""
        replyingToItemId = nil
        replyingToType = nil
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDateShort(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct LeadDetailClubHeaderView: View {
    @Environment(AppSession.self) var appSession
    let club: Club
    let event: Event
    var canEdit: Bool = true
    var isEditedAfterApproval: Bool = false
    @State private var isShowingEditEvent = false
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                if let bannerUrl = event.bannerImage, let url = URL(string: bannerUrl) {
                    AsyncImage(url: url) { phase in
                        switch phase {
                        case .empty:
                            ProgressView()
                                .frame(width: 60, height: 60)
                                .background(Color.secondary.opacity(0.1))
                                .clipShape(Circle())
                        case .success(let image):
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 60)
                                .clipShape(Circle())
                        case .failure:
                            Circle()
                                .fill(Color.orange.gradient.opacity(0.1))
                                .frame(width: 60, height: 60)
                            Text(String(event.name.prefix(1).uppercased()))
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.orange)
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    Circle()
                        .fill(Color.orange.gradient.opacity(0.1))
                        .frame(width: 60, height: 60)
                    
                    Text(String(event.name.prefix(1).uppercased()))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.orange)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(event.name)
                        .font(.headline)
                    
                    if isEditedAfterApproval {
                        Text("Edited")
                            .font(.system(size: 10, weight: .bold))
                            .padding(.horizontal, 6)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.15))
                            .foregroundColor(.blue)
                            .clipShape(Capsule())
                    }
                }
                Text(club.name)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            if canEdit {
                Button("Edit") {
                    isShowingEditEvent = true
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
        .padding(16)
        .glassEffect(in: .rect(cornerRadius: 20))
        .sheet(isPresented: $isShowingEditEvent) {
            NavigationStack {
                EditEventView(event: event) { updatedEvent in
                    // Update happened in store
                }
            }
        }
    }
}

struct SummaryCardRow: View {
    let requested: Double
    let approved: Double
    let label: String
    
    var body: some View {
        HStack(spacing: 12) {
            SummaryCard(title: "REQUESTED \(label)", amount: requested, icon: "clock.arrow.circlepath", color: .orange)
            SummaryCard(title: "APPROVED \(label)", amount: approved, icon: "checkmark.shield.fill", color: .green)
        }
        .padding(.horizontal)
    }
}

struct SummaryCard: View {
    let title: String
    let amount: Double
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                ZStack {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(color.opacity(0.1))
                        .frame(width: 32, height: 32)
                    Image(systemName: icon)
                        .font(.caption)
                        .foregroundColor(color)
                }
                Spacer()
                Text(title)
                    .font(.system(size: 8, weight: .bold))
                    .foregroundColor(.secondary)
            }
            
            Text("₹\(String(format: "%.0f", amount))")
                .font(.title3.bold())
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
}

struct LeadItemApprovalCard: View {
    @Environment(AppSession.self) var appSession
    let title: String
    var subtitle: String? = nil
    let icon: String
    let iconColor: Color
    let status: String
    let details: [(icon: String?, label: String, value: String)]
    let approvalId: UUID? // Changed from [Remark]
    let onReply: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                HStack(spacing: 10) {
                    Image(systemName: icon)
                        .foregroundColor(iconColor)
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(title)
                            .font(.headline)
                        
                        if let subtitle = subtitle {
                            Text(subtitle)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                Text(status.uppercased())
                    .font(.system(size: 10, weight: .bold))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(statusColor.opacity(0.1))
                    .foregroundColor(statusColor)
                    .clipShape(Capsule())
            }
            
            Divider()
            
            // Details Grid
            VStack(alignment: .leading, spacing: 12) {
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ForEach(details, id: \.label) { detail in
                        HStack(alignment: .top, spacing: 8) {
                            if let icon = detail.icon {
                                Image(systemName: icon)
                                    .foregroundColor(.orange)
                                    .font(.system(size: 14))
                                    .padding(.top, 2)
                            }
                            
                            VStack(alignment: .leading, spacing: 2) {
                                Text(detail.label.uppercased())
                                    .font(.system(size: 8, weight: .bold))
                                    .foregroundColor(.secondary)
                                let parts = detail.value.components(separatedBy: "\n")
                                if parts.count == 2 {
                                    VStack(alignment: .leading, spacing: 1) {
                                        Text(parts[0])
                                            .font(.subheadline.bold())
                                        Text(parts[1])
                                            .font(.caption2)
                                            .foregroundColor(.secondary)
                                    }
                                } else {
                                    Text(detail.value)
                                        .font(.subheadline.bold())
                                }
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                    }
                }
                
                if let approvalId = approvalId {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("REMARKS")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        RemarkConversationView(approvalId: approvalId)
                    }
                    .padding(.top, 4)
                }
                
                HStack {
                    Spacer()
                    Button(action: onReply) {
                        Label("Reply", systemImage: "arrowshape.turn.up.left.fill")
                            .font(.caption.bold())
                            .foregroundColor(.blue)
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(Color.blue.opacity(0.1))
                            .clipShape(Capsule())
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(20)
        .glassEffect(in: .rect(cornerRadius: 24))
    }
    
    var statusColor: Color {
        switch status.lowercased() {
        case "pending": return .orange
        case "approved": return .green
        case "rejected": return .red
        default: return .secondary
        }
    }
}
