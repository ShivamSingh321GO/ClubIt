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
    
    private var step1Color: Color {
        guard let approval = vpApproval else { return .orange }
        switch approval.status {
        case .pending: return .orange
        case .approved: return .green
        case .rejected: return .red
        }
    }
    
    private var step1Icon: String {
        guard let approval = vpApproval else { return "clock.fill" }
        switch approval.status {
        case .pending: return "clock.fill"
        case .approved: return "checkmark"
        case .rejected: return "xmark"
        }
    }
    
    private var step2Color: Color {
        if !hasVP || vpApproval?.status == .approved {
            return isAllApproved ? .green : .orange
        } else {
            return .secondary
        }
    }
    
    private var step2Icon: String {
        if !hasVP || vpApproval?.status == .approved {
            return isAllApproved ? "checkmark" : "clock.fill"
        } else {
            return "lock.fill"
        }
    }
    
    var body: some View {
        if let event = event, let club = club {

            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // Club Header
                    LeadDetailClubHeaderView(club: club, event: event)
                        .padding(.horizontal)
                    
                    // Two-Stage Approval Status Tracker
                    VStack(alignment: .leading, spacing: 16) {
                        Text("APPROVAL FLOW STATUS")
                            .font(.system(size: 10, weight: .bold))
                            .foregroundColor(.secondary)
                            .padding(.horizontal)
                        
                        VStack(alignment: .leading, spacing: 20) {
                            if hasVP {
                                // Step 1: Vice President Draft Review
                                HStack(alignment: .top, spacing: 12) {
                                    VStack {
                                        Circle()
                                            .fill(step1Color)
                                            .frame(width: 24, height: 24)
                                            .overlay(
                                                Image(systemName: step1Icon)
                                                    .font(.system(size: 10, weight: .bold))
                                                    .foregroundColor(.white)
                                            )
                                        
                                        Rectangle()
                                            .fill(step2Color.opacity(0.3))
                                            .frame(width: 2, height: 30)
                                    }
                                    
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text("Step 1: Vice President Draft Approval")
                                            .font(.subheadline.bold())
                                            .foregroundColor(step1Color)
                                        
                                        if let vp = vpUser {
                                            Text("Reviewer: \(vp.name)")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        
                                        if let approval = vpApproval {
                                            Text("Status: \(approval.status.rawValue.uppercased())")
                                                .font(.caption.bold())
                                                .foregroundColor(step1Color)
                                            
                                            // If rejected, show the remark
                                            if approval.status == .rejected {
                                                if let remark = vpRejectionRemark {
                                                    Text("Remark: \"\(remark)\"")
                                                        .font(.caption.italic())
                                                        .foregroundColor(.red)
                                                        .padding(.top, 4)
                                                }
                                            }
                                        } else {
                                            Text("Status: PENDING")
                                                .font(.caption.bold())
                                                .foregroundColor(.orange)
                                        }
                                    }
                                    Spacer()
                                }
                            }
                            
                            // Step 2: Faculty & President Final Approvals
                            HStack(alignment: .top, spacing: 12) {
                                Circle()
                                    .fill(step2Color)
                                    .frame(width: 24, height: 24)
                                    .overlay(
                                        Image(systemName: step2Icon)
                                            .font(.system(size: 10, weight: .bold))
                                            .foregroundColor(.white)
                                    )
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(hasVP ? "Step 2: Faculty & President Final Review" : "Final Review (Faculty & President)")
                                        .font(.subheadline.bold())
                                        .foregroundColor(step2Color)
                                    
                                    if !hasVP || vpApproval?.status == .approved {
                                        Text(isAllApproved ? "Event is fully approved and ready to publish!" : "Awaiting final budget, venue, and resource approvals.")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    } else {
                                        Text("Locked until Vice President approves the draft.")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
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
                        Text("Venue (\(allClubVenueApprovals.count))").tag("Venue")
                        Text("Budget (\(allClubBudgets.count))").tag("Budget")
                        Text("Resource (\(allClubResources.count))").tag("Resource")
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
