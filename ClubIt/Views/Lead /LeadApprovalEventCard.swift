import SwiftUI

struct LeadApprovalEventCard: View {
    @Environment(AppSession.self) var appSession
    let event: Event
    let approval: Approval
    
    var body: some View {
        let club = appSession.clubStore.allClubs.first(where: { $0.id == event.clubId })
        
        // 1. Pending Resources
        let pendingResources = appSession.approvalStore.resources.filter { 
            $0.eventId == event.id && $0.status == .pending 
        }
        
        // 2. Pending Venues
        let realVenueApprovals = appSession.approvalStore.approvals.filter { $0.eventId == event.id && $0.type == .venue }
        let pendingVenuesCount: Int = {
            if realVenueApprovals.isEmpty && !event.location.isEmpty {
                return 1 // Fake pending venue
            }
            return realVenueApprovals.filter { $0.status == .pending }.count
        }()
        
        // 3. Pending Budgets
        let pendingBudgets = appSession.approvalStore.budgets.filter { 
            $0.eventId == event.id && $0.status == .pending 
        }
        
        // 4. Pending VP Event Approval
        let pendingEventApprovalsCount: Int = {
            if let vpId = club?.vicePresidentId {
                let vpApproval = appSession.approvalStore.approvals.filter { 
                    $0.eventId == event.id && $0.type == .event && $0.receiverId == vpId 
                }.sorted(by: { $0.createdAt > $1.createdAt }).first
                
                if vpApproval?.status == .pending {
                    return 1
                }
            }
            return 0
        }()
        
        let totalPending = pendingResources.count + pendingVenuesCount + pendingBudgets.count + pendingEventApprovalsCount
        
        let isRejected = approval.status == .rejected || 
                         appSession.approvalStore.resources.contains { $0.eventId == event.id && $0.status == .rejected } ||
                         appSession.approvalStore.approvals.contains { $0.eventId == event.id && $0.type == .venue && $0.status == .rejected } ||
                         appSession.approvalStore.budgets.contains { $0.eventId == event.id && $0.status == .rejected }
        
        let isApproved = totalPending == 0 && !isRejected

        
        HStack(spacing: 16) {
            // Event Image
            ZStack {
                if let bannerImage = event.bannerImage, !bannerImage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    AsyncImage(url: URL(string: bannerImage)) { phase in
                        if let image = phase.image {
                            image
                                .resizable()
                                .scaledToFill()
                                .frame(width: 60, height: 60)
                                .clipShape(Circle())
                        } else if phase.error != nil {
                            ZStack {
                                Circle()
                                    .fill(isApproved ? Color.green.gradient.opacity(0.1) : (isRejected ? Color.red.gradient.opacity(0.1) : Color.orange.gradient.opacity(0.1)))
                                    .frame(width: 60, height: 60)
                                
                                Text(String(event.name.prefix(1).uppercased()))
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(isApproved ? .green : (isRejected ? .red : .orange))
                            }
                        } else {
                            Circle()
                                .fill(Color(.systemGray5))
                                .frame(width: 60, height: 60)
                                .overlay(ProgressView())
                        }
                    }
                } else {
                    Circle()
                        .fill(isApproved ? Color.green.gradient.opacity(0.1) : (isRejected ? Color.red.gradient.opacity(0.1) : Color.orange.gradient.opacity(0.1)))
                        .frame(width: 60, height: 60)
                    
                    Text(String(event.name.prefix(1).uppercased()))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(isApproved ? .green : (isRejected ? .red : .orange))
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(event.name)
                    .font(.headline)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)
                
                Text(club?.name ?? "Club")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                HStack(spacing: 8) {
                    if pendingEventApprovalsCount > 0 {
                        IndicatorTag(icon: "doc.text.fill", count: pendingEventApprovalsCount, color: .orange)
                    }
                    if pendingResources.count > 0 {
                        IndicatorTag(icon: "cart.fill", count: pendingResources.count, color: .blue)
                    }
                    if pendingVenuesCount > 0 {
                        IndicatorTag(icon: "mappin.and.ellipse", count: pendingVenuesCount, color: .purple)
                    }
                    if pendingBudgets.count > 0 {
                        IndicatorTag(icon: "indianrupeesign.circle.fill", count: pendingBudgets.count, color: .green)
                    }
                }
                .padding(.top, 2)
            }
            
            Spacer()
            
            VStack(alignment: .center, spacing: 6) {
                if isApproved {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.title3)
                        .foregroundColor(.green)
                    Text("Approved")
                        .font(.caption2.bold())
                        .foregroundColor(.green)
                        .textCase(.uppercase)
                } else if isRejected {
                    Image(systemName: "xmark.seal.fill")
                        .font(.title3)
                        .foregroundColor(.red)
                    Text("Rejected")
                        .font(.caption2.bold())
                        .foregroundColor(.red)
                        .textCase(.uppercase)
                } else {
                    Text("!")
                        .font(.title3.bold())
                        .foregroundColor(.orange)
                        .frame(width: 40, height: 40)
                        .background(Color.orange.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            .fixedSize(horizontal: true, vertical: false)

            
//            Image(systemName: "chevron.right")
//                .font(.caption.bold())
//                .foregroundColor(.secondary.opacity(0.3))
        }
        .padding(16)
        .glassEffect(in: .rect(cornerRadius: 20))
        .contentShape(.rect)
    }
}
