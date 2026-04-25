import SwiftUI

struct PresidentClubBudgetDetailView: View {
    @Environment(AppSession.self) var appSession
    let club: Club
    
    @State private var selectedBudgetForRemark: Budget?
    @State private var showingBudgetApprovalAlert = false
    @State private var budgetToApprove: Budget?
    
    var body: some View {
        let clubEvents = appSession.eventStore.events.filter { $0.clubId == club.id }
        let clubEventIds = Set(clubEvents.map { $0.id })
        let allClubBudgets = appSession.approvalStore.budgets.filter { clubEventIds.contains($0.eventId) }
        
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
                                    .fill(Color.orange.opacity(0.1))
                                    .frame(width: 50, height: 50)
                                    .overlay(
                                        Text(String(club.name.prefix(1)))
                                            .font(.title3.bold())
                                            .foregroundColor(.orange)
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
                                .fill(Color.orange.opacity(0.1))
                                .frame(width: 50, height: 50)
                                .overlay(
                                    Text(String(club.name.prefix(1)))
                                        .font(.title3.bold())
                                        .foregroundColor(.orange)
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
}

struct PresidentBudgetRequestCard: View {
    @Environment(AppSession.self) var appSession
    let budget: Budget
    let onReject: () -> Void
    let onApprove: () -> Void
    @State private var replyText: String = ""
    @State private var showingReply: Bool = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                HStack(spacing: 10) {
                    Image(systemName: "indianrupeesign.circle.fill")
                        .foregroundColor(.orange)
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
                    } else {
                        PresidentDetailItem(icon: "calendar", label: "Requested At", value: formatDate(budget.createdAt))
                    }
                }
                
                if !budget.remarks.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("REMARKS")
                            .font(.system(size: 8, weight: .bold))
                            .foregroundColor(.secondary)
                        
                        RemarkConversationView(remarks: budget.remarks)
                    }
                    .padding(.top, 4)
                }
                
                if showingReply {
                    ReplyInputView(replyText: $replyText, onSend: {
                        let newRemark = Remark(text: replyText, authorId: appSession.currentUser?.id ?? UUID(), authorName: appSession.currentUser?.name ?? "Faculty", createdAt: Date())
                        appSession.approvalStore.addRemarkToBudget(id: budget.id, remark: newRemark)
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
            }
            
            if budget.status == .pending {
                HStack(spacing: 12) {
                    Button(action: onReject) {
                        Label("Reject", systemImage: "xmark.circle")
                            .font(.subheadline.bold())
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.red.opacity(0.1))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                    
                    Button(action: onApprove) {
                        Label("Approve", systemImage: "checkmark.circle.fill")
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color.green)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .buttonStyle(.plain)
                }
                .padding(.top, 4)
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.white.opacity(0.2), lineWidth: 0.5)
                )
        )
        .shadow(color: .black.opacity(0.05), radius: 10, x: 0, y: 5)
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
        case .pending: return .orange
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
                .foregroundColor(.orange)
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
            VStack(alignment: .leading, spacing: 20) {
                Text("Add a remark for budget rejection")
                    .font(.headline)
                
                TextEditor(text: $remark)
                    .frame(height: 150)
                    .padding(8)
                    .background(Color.secondary.opacity(0.1))
                    .cornerRadius(12)
                
                Text("Please explain why this budget item is being rejected.")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                Spacer()
                
                Button(action: {
                    let newRemark = Remark(text: remark, authorId: appSession.currentUser?.id ?? UUID(), authorName: appSession.currentUser?.name ?? "President", createdAt: Date())
                    appSession.approvalStore.updateBudgetStatus(id: budget.id, status: .rejected, remark: newRemark)
                    dismiss()
                }) {
                    Text("Reject with Remark")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.red)
                        .cornerRadius(12)
                }
                .disabled(remark.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            .padding()
            .navigationTitle("Rejection Remark")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title3)
                            .foregroundColor(.secondary)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

#Preview {
    NavigationStack {
        PresidentClubBudgetDetailView(club: MockData.technoJamClub)
            .environment(MockData.session(for: .president))
    }
}
