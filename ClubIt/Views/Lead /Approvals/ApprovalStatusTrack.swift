import SwiftUI

struct ApprovalStatusTrack: View {
    @Environment(AppSession.self) private var appSession
    let approval: Approval
    
    var body: some View {
        let eventId = approval.eventId ?? UUID()
        let event = appSession.eventStore.events.first(where: { $0.id == eventId })
        let club = appSession.clubStore.allClubs.first(where: { $0.id == event?.clubId })
        
        let allApprovals = appSession.approvalStore.approvals.filter { $0.eventId == eventId }
        let allBudgets = appSession.approvalStore.budgets.filter { $0.eventId == eventId }
        let allResources = appSession.approvalStore.resources.filter { $0.eventId == eventId }
        
        // 1. VP Step Status
        let hasVP = club?.vicePresidentId != nil
        let vpStatusText = hasVP ? "VP" : "VP (N/A)"
        let vpApproved = !hasVP || 
            allApprovals.contains { $0.type == .event && $0.status == .approved && $0.receiverId == club?.vicePresidentId } ||
            !allBudgets.isEmpty ||
            allApprovals.contains { $0.type == .budget || $0.type == .resource || $0.type == .venue }
        
        // 2. President Step Status
        let hasBudget = !allBudgets.isEmpty
        let presidentStatusText = hasBudget ? "President" : "President (N/A)"
        let presidentApproved = vpApproved && (!hasBudget || 
            allBudgets.allSatisfy { $0.status == .approved } ||
            allApprovals.contains { $0.type == .resource || $0.type == .venue })
        
        // 3. EMT Step Status
        let emtApproved = presidentApproved && (
            allApprovals.filter { $0.type == .event && $0.receiverId == (club?.facultyId ?? UUID(uuidString: "b02ff9cf-dce8-4be9-8fc6-a0d15c03ddad")!) }.allSatisfy { $0.status == .approved } &&
            allResources.allSatisfy { $0.status == .approved } &&
            allApprovals.filter { $0.type == .venue }.allSatisfy { $0.status == .approved }
        )
        
        let steps = [
            ("Lead", true, "Initiated"),
            (vpStatusText, vpApproved, hasVP ? (vpApproved ? "Approved" : "Pending") : "Skipped"),
            (presidentStatusText, presidentApproved, hasBudget ? (presidentApproved ? "Approved" : "Pending") : "Skipped"),
            ("EMT", emtApproved, emtApproved ? "Approved" : "Pending")
        ]
        
        VStack(spacing: 8) {
            HStack {
                ForEach(steps.indices, id: \.self) { index in
                    StatusLabel(text: steps[index].0, color: steps[index].1 ? .green : .secondary)
                    if index < steps.count - 1 { Spacer() }
                }
            }
            
            ZStack {
                Rectangle()
                    .fill(Color.secondary.opacity(0.1))
                    .frame(height: 2)
                
                HStack {
                    ForEach(steps.indices, id: \.self) { index in
                        StatusDot(color: steps[index].1 ? .green : Color.secondary.opacity(0.1))
                        if index < steps.count - 1 { Spacer() }
                    }
                }
                
                // Progress line
                HStack {
                    Rectangle()
                        .fill(.green)
                        .frame(width: progressWidth(for: steps), height: 2)
                    Spacer()
                }
            }
            .padding(.horizontal, 10)
            
            HStack {
                ForEach(steps.indices, id: \.self) { index in
                    StatusLabel(
                        text: steps[index].2,
                        color: steps[index].1 ? .green : .secondary
                    )
                    if index < steps.count - 1 { Spacer() }
                }
            }
        }
        .padding(.top, 4)
    }
    
    private func progressWidth(for steps: [(String, Bool, String)]) -> CGFloat {
        let approvedCount = steps.filter { $0.1 }.count
        if approvedCount <= 1 { return 10 }
        if approvedCount == 2 { return 100 }
        if approvedCount == 3 { return 200 }
        return 300 // All 4 approved
    }
}

struct StatusLabel: View {
    let text: String
    let color: Color
    
    var body: some View {
        Text(text)
            .font(.caption)
            .foregroundColor(color)
            .frame(width: 60)
            .multilineTextAlignment(.center)
    }
}

struct StatusDot: View {
    let color: Color
    var body: some View {
        Circle()
            .fill(color)
            .frame(width: 10, height: 10)
    }
}

#Preview {
    ZStack {
        VStack {
            ApprovalStatusTrack(approval: MockData.sampleApprovals[0])
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
                .padding()
        }
    }
}
