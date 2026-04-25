import SwiftUI

struct LeadEventApprovalDetailView: View {
    @Environment(AppSession.self) var appSession
    let eventId: UUID
    
    @State private var selectedTab: String = "Resource"
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
    
    var body: some View {
        if let event = event, let club = club {
            let allClubResources = appSession.approvalStore.resources.filter { $0.eventId == event.id }
            let allClubVenueApprovals = appSession.approvalStore.approvals.filter { 
                $0.eventId == event.id && $0.type == .venue 
            }
            let allClubBudgets = appSession.approvalStore.budgets.filter { $0.eventId == event.id }
            
            ScrollView(showsIndicators: false) {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // Club Header
                    LeadDetailClubHeaderView(club: club, event: event)
                    
                    // Overall Status Banner
                    let mainApproval = appSession.approvalStore.approvals.first(where: { $0.eventId == event.id && $0.type == .event })
                    let isAnyRejected = mainApproval?.status == .rejected ||
                                       allClubResources.contains { $0.status == .rejected } ||
                                       allClubVenueApprovals.contains { $0.status == .rejected } ||
                                       allClubBudgets.contains { $0.status == .rejected }
                    
                    let isAllApproved = mainApproval?.status == .approved &&
                                       (allClubResources.isEmpty || allClubResources.allSatisfy { $0.status == .approved }) &&
                                       (allClubVenueApprovals.isEmpty || allClubVenueApprovals.allSatisfy { $0.status == .approved }) &&
                                       (allClubBudgets.isEmpty || allClubBudgets.allSatisfy { $0.status == .approved })
                    
                    Group {
                        if isAllApproved {
                            HStack {
                                Image(systemName: "checkmark.seal.fill")
                                Text("Event Fully Approved")
                                    .font(.headline)
                                Spacer()
                            }
                            .padding()
                            .background(Color.green.opacity(0.1))
                            .foregroundColor(.green)
                            .cornerRadius(16)
                            .padding(.horizontal)
                        } else if isAnyRejected {
                            HStack {
                                Image(systemName: "xmark.seal.fill")
                                Text("Event Request Rejected")
                                    .font(.headline)
                                Spacer()
                            }
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .foregroundColor(.red)
                            .cornerRadius(16)
                            .padding(.horizontal)
                        }
                    }


                    
                    // Segmented Filter
                    Picker("Select Category", selection: $selectedTab) {
                        Text("Resource (\(allClubResources.count))").tag("Resource")
                        Text("Venue (\(allClubVenueApprovals.count))").tag("Venue")
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
        VStack(spacing: 20) {
            let totalRequestedRental = resources.filter { $0.type == .external }.reduce(0) { $0 + ($1.cost ?? 0) }
            let totalApprovedRental = resources.filter { $0.type == .external && $0.status == .approved }.reduce(0) { $0 + ($1.cost ?? 0) }
            
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
                        remarks: resource.remarks,
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
                    remarks: approval.remarks,
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
        VStack(spacing: 20) {
            let totalRequested = budgets.reduce(0) { $0 + $1.totalAmount }
            let totalApproved = budgets.filter { $0.status == .approved }.reduce(0) { $0 + $1.totalAmount }
            
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
                        remarks: budget.remarks,
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
        VStack(spacing: 0) {
            Divider()
            HStack(spacing: 12) {
                TextField("Type your reply...", text: $replyText)
                    .padding(10)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(12)
                
                Button(action: sendReply) {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(.white)
                        .padding(10)
                        .background(Color.blue)
                        .clipShape(Circle())
                }
                .disabled(replyText.trimmingCharacters(in: .whitespaces).isEmpty)
                
                Button(action: {
                    replyingToItemId = nil
                    replyingToType = nil
                    replyText = ""
                }) {
                    Image(systemName: "xmark")
                        .foregroundColor(.secondary)
                        .padding(10)
                }
            }
            .padding()
            .background(.ultraThinMaterial)
        }
    }
    
    private func sendReply() {
        guard let id = replyingToItemId, let type = replyingToType, let user = appSession.currentUser else { return }
        
        let newRemark = Remark(
            text: replyText,
            authorId: user.id,
            authorName: user.name,
            createdAt: Date()
        )
        
        switch type {
        case .resource:
            appSession.approvalStore.addRemarkToResource(id: id, remark: newRemark)
        case .venue:
            appSession.approvalStore.addRemarkToApproval(id: id, remark: newRemark)
        case .budget:
            appSession.approvalStore.addRemarkToBudget(id: id, remark: newRemark)
        case .event:
            appSession.approvalStore.addRemarkToApproval(id: id, remark: newRemark)
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
                    .font(.title3.bold())
                Text(club.name)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {
                isShowingEditEvent = true
            }) {
                Text("Edit")
                    .font(.subheadline.bold())
                    .foregroundColor(.blue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .glassEffect(in: .rect(cornerRadius: 12))
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal)
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
    let title: String
    let icon: String
    let iconColor: Color
    let status: String
    let details: [(String, String)]
    let remarks: [Remark]
    let onReply: () -> Void
    
    @State private var showAllRemarks = false
    
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
            
            Divider().opacity(0.3)
            
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
                
                if !remarks.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("REMARKS")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        RemarkConversationView(remarks: remarks)
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
