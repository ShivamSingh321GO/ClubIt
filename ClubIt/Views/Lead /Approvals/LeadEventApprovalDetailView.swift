import SwiftUI

struct LeadEventApprovalDetailView: View {
    @Environment(AppSession.self) var appSession
    let eventId: UUID
    
    @State private var selectedTab: String = "Venue"
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
    
    private var vpApproval: Approval? {
        guard let event = event, let club = club, let vpId = club.vicePresidentId else { return nil }
        return appSession.approvalStore.approvals.first(where: { $0.eventId == event.id && $0.type == .event && $0.receiverId == vpId })
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
                    LeadDetailClubHeaderView(club: club, event: event)
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
                            ("Quantity", "\(resource.quantity)"),
                            ("Source", resource.type == .university ? "University" : "External Rental")
                        ] + (resource.type == .external ? [
                            ("Rental Cost", "₹\(String(format: "%.0f", resource.cost ?? 0))"),
                            ("Vendor", resource.vendorName ?? "N/A")
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
                    icon: "mappin.and.ellipse",
                    iconColor: .purple,
                    status: approval.status.rawValue,
                    details: [
                        ("Location", event?.location ?? "N/A"),
                        ("Event Date", formatDateShort(event?.startDate ?? Date()))
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
                    LeadItemApprovalCard(
                        title: budget.itemName,
                        icon: "indianrupeesign.circle.fill",
                        iconColor: .green,
                        status: budget.status.rawValue,
                        details: [
                            ("Unit Price", "₹\(String(format: "%.0f", budget.unitPrice))"),
                            ("Quantity", "\(budget.quantity)"),
                            ("Total", "₹\(String(format: "%.0f", budget.totalAmount))")
                        ],
                        approvalId: appSession.approvalStore.approvals.first(where: { $0.approvalRelatedId == budget.id })?.id,
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
    @State private var isShowingEditEvent = false
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.orange.gradient.opacity(0.1))
                    .frame(width: 60, height: 60)
                
                Text(String(club.name.prefix(1)))
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.orange)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(event.name)
                    .font(.headline)
                Text(club.name)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button("Edit") {
                isShowingEditEvent = true
            }
            .buttonStyle(.bordered)
            .controlSize(.small)
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
    let icon: String
    let iconColor: Color
    let status: String
    let details: [(String, String)]
    let approvalId: UUID? // Changed from [Remark]
    let onReply: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                HStack(spacing: 10) {
                    Image(systemName: icon)
                        .foregroundColor(iconColor)
                        .font(.title3)
                    
                    Text(title)
                        .font(.headline)
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
                    ForEach(details, id: \.0) { detail in
                        VStack(alignment: .leading, spacing: 2) {
                            Text(detail.0.uppercased())
                                .font(.system(size: 8, weight: .bold))
                                .foregroundColor(.secondary)
                            Text(detail.1)
                                .font(.subheadline.bold())
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
                
                Button(action: onReply) {
                    Label("Reply to Faculty", systemImage: "arrowshape.turn.up.left.fill")
                        .font(.caption.bold())
                        .foregroundColor(.blue)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 12)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(Capsule())
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
