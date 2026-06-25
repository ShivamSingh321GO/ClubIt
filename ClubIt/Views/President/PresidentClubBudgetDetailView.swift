import SwiftUI
import ClubItShared

struct PresidentClubBudgetDetailView: View {
    @Environment(AppSession.self) var appSession
    let club: Club
    
    @State private var selectedBudgetForRemark: Budget?
    @State private var showingBudgetApprovalAlert = false
    @State private var budgetToApprove: Budget?
    
    // Reply states
    @State private var replyingToApprovalId: UUID? = nil
    @State private var replyText: String = ""
    
    var body: some View {
        let clubEvents = appSession.eventStore.events.filter { $0.clubId == club.id }
        let clubEventIds = Set(clubEvents.map { $0.id })
        let allClubBudgets = appSession.approvalStore.budgets.filter { clubEventIds.contains($0.eventId ?? UUID()) }
        
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                
                // MARK: - Club Header
                let pendingBudgets = allClubBudgets.filter { $0.status == .pending }
                
                Group {
                    if let firstEventId = pendingBudgets.first?.eventId,
                       let event = appSession.eventStore.events.first(where: { $0.id == firstEventId }) {
                        NavigationLink(destination: EventDetailView(event: event, isMyEvent: false)) {
                            HStack(spacing: 16) {
                                Circle()
                                    .fill(Color.accentColor.opacity(0.1))
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        Text(String(club.name.prefix(1)))
                                            .font(.title3.bold())
                                            .foregroundColor(.accentColor)
                                    )
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text(event.name)
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Text(club.name)
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.caption.bold())
                                    .foregroundColor(.secondary.opacity(0.3))
                            }
                            .padding()
                            .background(.ultraThinMaterial)
                            .cornerRadius(20)
                            .padding(.horizontal)
                        }
                        .buttonStyle(.plain)
                    } else {
                        HStack(spacing: 16) {
                            Circle()
                                .fill(Color.accentColor.opacity(0.1))
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Text(String(club.name.prefix(1)))
                                        .font(.title3.bold())
                                        .foregroundColor(.accentColor)
                                )
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text(club.name)
                                    .font(.title3.bold())
                                Text("Budget Approval Management")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                        }
                        .padding()
                        .background(.ultraThinMaterial)
                        .cornerRadius(20)
                        .padding(.horizontal)
                    }
                }
                
                // MARK: - Global Timestamp
                if let latestRequest = allClubBudgets.sorted(by: { $0.createdAt > $1.createdAt }).first {
                    HStack {
                        Image(systemName: "clock.fill")
                        Text("Requested on \(formatDate(latestRequest.createdAt))")
                    }
                    .font(.caption.bold())
                    .foregroundColor(.secondary)
                    .padding(.horizontal)
                    .padding(.top, -8)
                }
                
                // MARK: - Budget Summary Cards
                if !allClubBudgets.isEmpty {
                    let totalRequested = allClubBudgets.reduce(0) { $0 + $1.totalAmount }
                    let totalApproved = allClubBudgets.filter { $0.status == .approved }.reduce(0) { $0 + $1.totalAmount }
                    
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
                }
                
                // MARK: - Budget List
                if allClubBudgets.isEmpty {
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
                    VStack(spacing: 16) {
                        ForEach(allClubBudgets.sorted(by: { $0.createdAt > $1.createdAt })) { budget in
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
            .padding(.vertical)
        }
        .navigationTitle(club.name)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedBudgetForRemark) { budget in
            PresidentBudgetRemarkSheet(budget: budget)
        }
        .alert("Confirm Approval", isPresented: $showingBudgetApprovalAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Approve") {
                if let budget = budgetToApprove {
                    Task {
                        try? await appSession.approveBudgetAndCheckForwarding(budget: budget, status: .approved)
                    }
                }
            }
        } message: {
            if let budget = budgetToApprove {
                Text("Are you sure you want to approve the budget for '\(budget.itemName)'?")
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
    }
}

struct PresidentBudgetRequestCard: View {
    @Environment(AppSession.self) var appSession
    let budget: Budget
    let onReject: () -> Void
    let onApprove: () -> Void
    let onReply: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                HStack(spacing: 10) {
                    Image(systemName: "indianrupeesign.circle.fill")
                        .foregroundColor(.accentColor)
                        .font(.title3)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text(budget.itemName)
                            .font(.headline)
                            .foregroundColor(.primary)
                        
                        if let event = appSession.eventStore.events.first(where: { $0.id == budget.eventId }) {
                            Text(event.name)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Spacer()
                
                PresidentStatusBadge(status: budget.status)
            }
            
            Divider().opacity(0.3)
            
            VStack(alignment: .leading, spacing: 12) {
                HStack(alignment: .top, spacing: 20) {
                    PresidentDetailItem(icon: "tag.fill", label: "Unit Price", value: "₹\(String(format: "%.0f", budget.unitPrice))")
                    PresidentDetailItem(icon: "number.circle.fill", label: "Quantity", value: "\(budget.quantity)")
                }
                
                HStack(alignment: .top, spacing: 20) {
                    PresidentDetailItem(icon: "sum", label: "Total Amount", value: "₹\(String(format: "%.0f", budget.totalAmount))")
                    if let approvedAt = budget.approvedAt {
                        PresidentDetailItem(icon: "checkmark.shield.fill", label: "Approved At", value: formatDate(approvedAt))
                    }
                }
                
                if let approvalId = appSession.approvalStore.approvals.first(where: { $0.approvalRelatedId == budget.id })?.id {
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
                        Label(appSession.currentUser?.role == .subGroupLead ? "Reply" : "Reply to Lead", systemImage: "arrowshape.turn.up.left.fill")
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
            
            if budget.status == .pending && appSession.currentUser?.role == .groupLead {
                HStack(spacing: 12) {
                    Button(role: .destructive, action: onReject) {
                        Label("Reject", systemImage: "xmark.circle")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                    
                    Button(action: onApprove) {
                        Label("Approve", systemImage: "checkmark.circle.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(.green)
                    .controlSize(.large)
                }
                .padding(.top, 4)
            }
        }
        .padding(20)
        .glassEffect(in: .rect(cornerRadius: 24))
    }
    
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct PresidentStatusBadge: View {
    let status: ApprovalStatus
    
    var color: Color {
        switch status {
        case .pending: return .accentColor
        case .approved: return .green
        case .rejected: return .red
        }
    }
    
    var body: some View {
        Text(status.rawValue.uppercased())
            .font(.system(size: 10, weight: .bold))
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(color.opacity(0.1))
            .foregroundColor(color)
            .clipShape(Capsule())
    }
}

struct PresidentDetailItem: View {
    let icon: String
    let label: String
    let value: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(.accentColor)
                .font(.system(size: 14))
                .padding(.top, 2)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
                Text(value)
                    .font(.subheadline.bold())
                    .foregroundColor(.primary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct PresidentBudgetRemarkSheet: View {
    @Environment(AppSession.self) var appSession
    @Environment(\.dismiss) var dismiss
    let budget: Budget
    @State private var remark: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    TextEditor(text: $remark)
                        .frame(minHeight: 150)
                } header: {
                    Text("Add a remark for budget rejection")
                } footer: {
                    Text("Please explain why this budget item is being rejected.")
                }
                
            }
            .navigationTitle("Rejection Remark")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                    }
                }
                
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if let approvalId = appSession.approvalStore.approvals.first(where: { $0.approvalRelatedId == budget.id })?.id {
                            let finalRemark = remark
                            Task {
                                try? await appSession.approveBudgetAndCheckForwarding(budget: budget, status: .rejected)
                                try? await appSession.approvalStore.addRemark(
                                    approvalId: approvalId,
                                    authorId: appSession.currentUser?.id ?? UUID(),
                                    content: finalRemark
                                )
                            }
                        }
                        dismiss()
                    } label: {
                        Image(systemName: "checkmark")
                    }
                    .disabled(remark.trimmingCharacters(in: .whitespaces).isEmpty)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        PresidentClubBudgetDetailView(club: MockData.technoJamClub)
            .environment(MockData.session(for: .groupLead))
    }
}
