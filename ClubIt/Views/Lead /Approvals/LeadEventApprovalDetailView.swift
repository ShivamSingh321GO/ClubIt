import SwiftUI
import ClubItShared

struct LeadEventApprovalDetailView: View {
    @Environment(AppSession.self) var appSession
    let eventId: UUID
    
    @State private var dynamicSteps: [ApprovalFlowStep] = []
    @State private var selectedTab: String = "Event"
    @State private var replyText: String = ""
    @State private var replyingToItemId: UUID? = nil
    @State private var replyingToType: ApprovalType? = nil
    
    var event: Event? {
        appSession.eventStore.events.first(where: { $0.id == eventId })
    }
    
    var subgroup: Subgroup? {
        guard let event = event else { return nil }
        return appSession.subgroupStore.allSubgroups.first(where: { $0.id == event.subgroupId })
    }

    private var allSubgroupEventApprovals: [Approval] {
        guard let event = event else { return [] }
        return appSession.approvalStore.approvals.filter { $0.eventId == event.id && $0.type == .event }
    }

    private var allSubgroupResources: [Resource] {
        guard let event = event else { return [] }
        return appSession.approvalStore.resources.filter { $0.eventId == event.id }
    }
    
    private var allSubgroupVenueApprovals: [Approval] {
        guard let event = event else { return [] }
        let realVenueApprovals = appSession.approvalStore.approvals.filter { $0.eventId == event.id && $0.type == .venue }
        if realVenueApprovals.isEmpty && !event.location.isEmpty {
            return [Approval(
                id: UUID(),
                type: .venue,
                senderId: event.createdBy,
                receiverId: subgroup?.facultyId ?? UUID(uuidString: "b02ff9cf-dce8-4be9-8fc6-a0d15c03ddad")!,
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
    
    private var allSubgroupBudgets: [Budget] {
        guard let event = event else { return [] }
        return appSession.approvalStore.budgets.filter { $0.eventId == event.id }
    }
    
    private var mainApproval: Approval? {
        guard let event = event else { return nil }
        return appSession.approvalStore.approvals.first(where: { $0.eventId == event.id && $0.type == .event })
    }
    
    private var isAnyRejected: Bool {
        let isMainRejected = mainApproval?.status == .rejected
        let isResRejected = allSubgroupResources.contains { $0.status == .rejected }
        let isVenueRejected = allSubgroupVenueApprovals.contains { $0.status == .rejected }
        let isBudgetRejected = allSubgroupBudgets.contains { $0.status == .rejected }
        return isMainRejected || isResRejected || isVenueRejected || isBudgetRejected
    }
    
    private var isAllApproved: Bool {
        let isMainApproved = mainApproval?.status == .approved
        let isResApproved = allSubgroupResources.isEmpty || allSubgroupResources.allSatisfy { $0.status == .approved }
        let isVenueApproved = allSubgroupVenueApprovals.isEmpty || allSubgroupVenueApprovals.allSatisfy { $0.status == .approved }
        let isBudgetApproved = allSubgroupBudgets.isEmpty || allSubgroupBudgets.allSatisfy { $0.status == .approved }
        return isMainApproved && isResApproved && isVenueApproved && isBudgetApproved
    }
    
    private var hasVP: Bool {
        guard let subgroup = subgroup else { return false }
        return subgroup.vicePresidentId != nil
    }
    
    private var vpUser: User? {
        guard let subgroup = subgroup, let vpId = subgroup.vicePresidentId else { return nil }
        return appSession.subgroupStore.allUsers.first(where: { $0.id == vpId })
    }
    
    private var allVpApprovals: [Approval] {
        guard let event = event, let subgroup = subgroup, let vpId = subgroup.vicePresidentId else { return [] }
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
        !allSubgroupBudgets.isEmpty
    }
    
    private var presidentUser: User? {
        let allUsers = appSession.subgroupStore.allUsers
        if let subgroup = subgroup {
            if let match = allUsers.first(where: { $0.role == .groupLead && $0.groupId == subgroup.groupId }) {
                return match
            }
        }
        return allUsers.first(where: {
            $0.role == .groupLead ||
            $0.name.lowercased().contains("group lead") ||
            $0.name.lowercased().contains("president") ||
            $0.email.lowercased().contains("grouplead") ||
            $0.email.lowercased().contains("president")
        })
    }
    
    private var facultyUser: User? {
        guard let subgroup = subgroup else { return nil }
        let facultyId = subgroup.facultyId
        return appSession.subgroupStore.allUsers.first(where: { $0.id == facultyId })
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
        
        let isAnyBudgetRejected = allSubgroupBudgets.contains { $0.status == .rejected }
        let isAllBudgetApproved = allSubgroupBudgets.allSatisfy { $0.status == .approved }
        
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
        let facultyId = subgroup?.facultyId ?? eventManagementTeamID
        
        let emtApprovals = appSession.approvalStore.approvals.filter { 
            $0.eventId == eventId && 
            ($0.type == .event || $0.type == .venue) && 
            ($0.receiverId == facultyId || $0.receiverId == appSession.currentUser?.id)
        }
        
        let isAnyEmtRejected = emtApprovals.contains { $0.status == .rejected } || 
                               allSubgroupResources.contains { $0.status == .rejected }
                               
        let isAllEmtApproved = !emtApprovals.isEmpty && 
                               emtApprovals.allSatisfy { $0.status == .approved } &&
                               allSubgroupResources.allSatisfy { $0.status == .approved }
                               
        if isAnyEmtRejected {
            return .rejected
        } else if isAllEmtApproved {
            return .approved
        } else {
            return .pending
        }
    }
    
    private var presidentRejectionRemark: String? {
        if let rejectedBudget = allSubgroupBudgets.first(where: { $0.status == .rejected }) {
            if let approval = appSession.approvalStore.approvals.first(where: { $0.approvalRelatedId == rejectedBudget.id }),
               let lastRemark = approval.remarks?.last?.content ?? appSession.approvalStore.remarkMessages[approval.id]?.last?.content {
                return "\(rejectedBudget.itemName): \(lastRemark)"
            }
        }
        return nil
    }
    
    private var emtRejectionRemark: String? {
        let eventManagementTeamID = UUID(uuidString: "b02ff9cf-dce8-4be9-8fc6-a0d15c03ddad")!
        let facultyId = subgroup?.facultyId ?? eventManagementTeamID
        
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
        
        if let rejectedResource = allSubgroupResources.first(where: { $0.status == .rejected }) {
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
        case .pending: return .accentColor
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
        if let event = event, let subgroup = subgroup {

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // Subgroup Header
                    LeadDetailSubgroupHeaderView(subgroup: subgroup, event: event, canEdit: true, isEditedAfterApproval: vpStepStatus == .pending && lastApprovedVpApproval != nil)
                        .padding(.horizontal)
                    
                    // Sequential Approval Status Tracker
                    VStack(alignment: .leading, spacing: 16) {
                        Text("APPROVAL FLOW STATUS")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        VStack(alignment: .leading, spacing: 20) {
                            if dynamicSteps.isEmpty {
                                HStack {
                                    Spacer()
                                    ProgressView("Loading flow steps...")
                                    Spacer()
                                }
                            } else {
                                ForEach(dynamicSteps) { step in
                                    HStack(alignment: .top, spacing: 12) {
                                        VStack {
                                            Circle()
                                                .fill(statusColor(for: step.status))
                                                .frame(width: 24, height: 24)
                                                .overlay(
                                                    Image(systemName: statusIcon(for: step.status))
                                                        .font(.system(size: 10, weight: .bold))
                                                        .foregroundColor(.white)
                                                )
                                            
                                            if step.stepNumber < dynamicSteps.count {
                                                let nextStep = dynamicSteps[step.stepNumber]
                                                Rectangle()
                                                    .fill(statusColor(for: nextStep.status).opacity(0.3))
                                                    .frame(width: 2, height: 30)
                                            }
                                        }
                                        
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Step \(step.stepNumber): \(step.title)")
                                                .font(.subheadline.bold())
                                            
                                            Text("Reviewer: \(step.reviewerName)")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                            
                                            HStack(spacing: 4) {
                                                Text("Status:")
                                                    .foregroundColor(.secondary)
                                                Text(statusText(for: step.status))
                                                    .foregroundColor(statusColor(for: step.status))
                                            }
                                            .font(.caption.bold())
                                            
                                            if step.status == .rejected, let remark = step.remark {
                                                Text("Remark: \"\(remark)\"")
                                                    .font(.caption.italic())
                                                    .foregroundColor(.red)
                                                    .padding(.top, 4)
                                            }
                                        }
                                        Spacer()
                                    }
                                }
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
                        Text("Event (\(allSubgroupEventApprovals.count))").tag("Event")
                        Text("Venue (\(allSubgroupVenueApprovals.count))").tag("Venue")
                        Text("Resource (\(allSubgroupResources.count))").tag("Resource")
                        Text("Budget (\(allSubgroupBudgets.count))").tag("Budget")
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)
                    
                    // Requested On
                    if let firstRequest = allSubgroupResources.sorted(by: { $0.createdAt > $1.createdAt }).first {
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
                        eventSection(allSubgroupEventApprovals)
                    case "Venue":
                        venueSection(allSubgroupVenueApprovals)
                    case "Resource":
                        resourceSection(allSubgroupResources)
                    case "Budget":
                        budgetSection(allSubgroupBudgets)
                    default:
                        EmptyView()
                    }
                }
                .padding(.vertical)
            }
            .refreshable {
                try? await appSession.approvalStore.fetchApprovals()
                try? await appSession.approvalStore.fetchBudgets(eventId: eventId)
                try? await appSession.approvalStore.fetchResources(eventId: eventId)
                try? await appSession.subgroupStore.fetchAllUsers()
                try? await appSession.subgroupStore.fetchAllSubgroups()
                
                let relevantApprovals = appSession.approvalStore.approvals.filter { $0.eventId == eventId }
                for approval in relevantApprovals {
                    try? await appSession.approvalStore.fetchRemarks(for: approval.id)
                }
                await loadDynamicSteps()
            }
            .task {
                await loadDynamicSteps()
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
                    let isVpDraft = (approval.id == vpApproval?.id)
                    let title = isVpDraft ? "VP Draft Review" : "Event Approval"
                    let reviewerName = isVpDraft ? (vpUser?.name ?? "N/A") : (appSession.subgroupStore.allUsers.first(where: { $0.id == approval.receiverId })?.name ?? "N/A")

                    LeadItemApprovalCard(
                        title: title,
                        icon: "doc.text.fill",
                        iconColor: .accentColor,
                        status: approval.status.rawValue,
                        details: [
                            (icon: nil, label: "Category", value: event?.category.rawValue.capitalized ?? "N/A"),
                            (icon: nil, label: "Reviewer", value: reviewerName)
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
                        iconColor: .accentColor,
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
    
    struct ApprovalFlowStep: Identifiable, Hashable {
        let id = UUID()
        let stepNumber: Int
        let title: String
        let reviewerName: String
        let status: StepStatus
        let remark: String?
        
        static func == (lhs: ApprovalFlowStep, rhs: ApprovalFlowStep) -> Bool {
            lhs.id == rhs.id
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }
    
    private func loadDynamicSteps() async {
        guard let event = event, let subgroup = subgroup else { return }
        let orgId = appSession.currentUser?.organizationId ?? appSession.currentUser?.instituteId ?? UUID(uuidString: "00000000-0000-0000-0000-000000000000")!
        
        var steps: [ApprovalFlowStep] = []
        var stepNum = 1
        
        // Step 1: Vice President Draft Approval (if configured/hasVP)
        if hasVP {
            let vpName = vpUser?.name ?? "Vice President"
            steps.append(ApprovalFlowStep(
                stepNumber: stepNum,
                title: "Vice President Draft Approval",
                reviewerName: vpName,
                status: vpStepStatus,
                remark: vpRejectionRemark
            ))
            stepNum += 1
        }
        
        let categories = ["Events", "Budget", "Resources", "Venue"]
        var isPrecedingApproved = hasVP ? (vpStepStatus == .approved) : true
        
        for category in categories {
            let categoryType: ApprovalType
            switch category {
            case "Events": categoryType = .event
            case "Budget": categoryType = .budget
            case "Resources": categoryType = .resource
            case "Venue": categoryType = .venue
            default: continue
            }
            
            // Check if there are no items for this category (e.g. no budgets or no resources requested)
            if category == "Budget" && allSubgroupBudgets.isEmpty {
                steps.append(ApprovalFlowStep(
                    stepNumber: stepNum,
                    title: "\(category) Approval",
                    reviewerName: "N/A",
                    status: .skipped,
                    remark: nil
                ))
                stepNum += 1
                continue
            }
            if category == "Resources" && allSubgroupResources.isEmpty {
                steps.append(ApprovalFlowStep(
                    stepNumber: stepNum,
                    title: "\(category) Approval",
                    reviewerName: "N/A",
                    status: .skipped,
                    remark: nil
                ))
                stepNum += 1
                continue
            }
            if category == "Venue" && allSubgroupVenueApprovals.isEmpty && event.location.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                steps.append(ApprovalFlowStep(
                    stepNumber: stepNum,
                    title: "\(category) Approval",
                    reviewerName: "N/A",
                    status: .skipped,
                    remark: nil
                ))
                stepNum += 1
                continue
            }
            
            // Determine approver IDs:
            // 1. Check existing approvals for this category & event first
            let existingApprovals = appSession.approvalStore.approvals.filter {
                $0.eventId == event.id && $0.type == categoryType
            }
            
            var approverIds: [UUID] = []
            if !existingApprovals.isEmpty {
                for appr in existingApprovals.sorted(by: { $0.createdAt < $1.createdAt }) {
                    if let rx = appr.receiverId, !approverIds.contains(rx) {
                        approverIds.append(rx)
                    }
                }
            }
            
            // 2. If no existing approval records found, try dynamic routing service
            if approverIds.isEmpty {
                approverIds = await appSession.routingService.resolveApprovers(
                    category: category,
                    subgroupId: subgroup.id,
                    groupId: subgroup.groupId,
                    orgId: orgId
                )
            }
            
            // 3. Fallback to default role assignees if routing returns empty but items exist
            if approverIds.isEmpty {
                if let fallbackId = fallbackApproverId(for: category) {
                    approverIds.append(fallbackId)
                }
            }
            
            // If still no approvers configured or found, mark skipped
            if approverIds.isEmpty {
                steps.append(ApprovalFlowStep(
                    stepNumber: stepNum,
                    title: "\(category) Approval",
                    reviewerName: "N/A",
                    status: .skipped,
                    remark: nil
                ))
                stepNum += 1
                continue
            }
            
            // Now resolve status for each sequential approver in this category
            for approverId in approverIds {
                let matchedUser = appSession.subgroupStore.allUsers.first(where: { $0.id == approverId })
                let reviewerName = matchedUser?.name ?? "Approver"
                
                // Find approval request for this type & receiverId
                let relevantApprovals = existingApprovals.filter { $0.receiverId == approverId }
                
                let stepStatus: StepStatus
                let remark: String?
                
                if let approval = relevantApprovals.first {
                    remark = approval.remarks?.last?.content ?? appSession.approvalStore.remarkMessages[approval.id]?.last?.content
                    switch approval.status {
                    case .pending:
                        stepStatus = .pending
                        isPrecedingApproved = false
                    case .approved:
                        stepStatus = .approved
                    case .rejected:
                        stepStatus = .rejected
                        isPrecedingApproved = false
                    }
                } else {
                    remark = nil
                    if isPrecedingApproved {
                        stepStatus = .pending
                        isPrecedingApproved = false
                    } else {
                        stepStatus = .locked
                    }
                }
                
                steps.append(ApprovalFlowStep(
                    stepNumber: stepNum,
                    title: "\(category) Approval",
                    reviewerName: reviewerName,
                    status: stepStatus,
                    remark: remark
                ))
                stepNum += 1
            }
        }
        
        self.dynamicSteps = steps
    }
    
    private func fallbackApproverId(for category: String) -> UUID? {
        let allUsers = appSession.subgroupStore.allUsers
        
        switch category {
        case "Events":
            if let vpId = subgroup?.vicePresidentId, allUsers.contains(where: { $0.id == vpId }) {
                return vpId
            }
            return allUsers.first(where: {
                $0.role == .groupSubLead ||
                $0.name.lowercased().contains("sublead") ||
                $0.email.lowercased().contains("sublead")
            })?.id
            
        case "Budget":
            return presidentUser?.id
            
        case "Resources":
            if let facId = subgroup?.facultyId, allUsers.contains(where: { $0.id == facId }) {
                return facId
            }
            return allUsers.first(where: {
                $0.name.lowercased().contains("admin two") ||
                $0.name.lowercased().contains("admin 2") ||
                $0.email.lowercased().contains("admin2") ||
                $0.name.lowercased().contains("resource")
            })?.id ?? allUsers.first(where: {
                $0.role == .admin || $0.role == .superAdmin
            })?.id
            
        case "Venue":
            if let facId = subgroup?.facultyId, allUsers.contains(where: { $0.id == facId }) {
                return facId
            }
            return allUsers.first(where: {
                $0.name.lowercased().contains("admin one") ||
                $0.name.lowercased().contains("admin 1") ||
                $0.email.lowercased().contains("admin1") ||
                $0.name.lowercased().contains("venue")
            })?.id ?? allUsers.first(where: {
                $0.role == .admin || $0.role == .superAdmin
            })?.id
            
        default:
            return nil
        }
    }
}

struct LeadDetailSubgroupHeaderView: View {
    @Environment(AppSession.self) var appSession
    let subgroup: Subgroup
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
                                .fill(Color.accentColor.gradient.opacity(0.1))
                                .frame(width: 60, height: 60)
                            Text(String(event.name.prefix(1).uppercased()))
                                .font(.system(size: 24, weight: .bold))
                                .foregroundColor(.accentColor)
                        @unknown default:
                            EmptyView()
                        }
                    }
                } else {
                    Circle()
                        .fill(Color.accentColor.gradient.opacity(0.1))
                        .frame(width: 60, height: 60)
                    
                    Text(String(event.name.prefix(1).uppercased()))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.accentColor)
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
                Text(subgroup.name)
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
            SummaryCard(title: "REQUESTED \(label)", amount: requested, icon: "clock.arrow.circlepath", color: .accentColor)
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
                                    .foregroundColor(.accentColor)
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
        case "pending": return .accentColor
        case "approved": return .green
        case "rejected": return .red
        default: return .secondary
        }
    }
}
