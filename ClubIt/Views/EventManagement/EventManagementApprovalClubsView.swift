import SwiftUI

struct EventManagementApprovalClubsView: View {
    @Environment(AppSession.self) var appSession
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                let allClubs = appSession.clubStore.allClubs
                
                if allClubs.isEmpty {
                    FacultyEmptyStateView(icon: "building.2.crop.circle.badge.exclamationmark", title: "No Clubs Found", message: "There are no clubs currently registered in the system.")
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(allClubs) { club in
                            NavigationLink(destination: EventManagementApprovalDetailView(club: club)) {
                                EventManagementClubApprovalCard(club: club)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding(.horizontal)
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Approval Management")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct EventManagementClubApprovalCard: View {
    @Environment(AppSession.self) var appSession
    let club: Club
    
    var body: some View {
        let clubEvents = appSession.eventStore.events.filter { $0.clubId == club.id }
        let clubEventIds = Set(clubEvents.map { $0.id })
        
        let pendingResources = appSession.approvalStore.resources.filter { 
            clubEventIds.contains($0.eventId) && $0.status == .pending 
        }
        let pendingVenues = appSession.approvalStore.approvals.filter { 
            clubEventIds.contains($0.eventId) && $0.type == .venue && $0.status == .pending 
        }
        let pendingBudgets = appSession.approvalStore.budgets.filter { 
            clubEventIds.contains($0.eventId) && $0.status == .pending 
        }
        
        let totalPending = pendingResources.count + pendingVenues.count + pendingBudgets.count
        
        HStack(spacing: 16) {
            // Club Logo/Initials
            ZStack {
                Circle()
                    .fill(Color.orange.gradient.opacity(0.1))
                    .frame(width: 60, height: 60)
                
                Text(String(club.name.prefix(1)))
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.orange)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                // Get the first pending event ID across all types
                let firstPendingEventId = pendingResources.first?.eventId ?? pendingVenues.first?.eventId ?? pendingBudgets.first?.eventId
                
                if let eventId = firstPendingEventId,
                   let event = appSession.eventStore.events.first(where: { $0.id == eventId }) {
                    Text(event.name)
                        .font(.headline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    
                    Text(club.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                } else {
                    Text(club.name)
                        .font(.headline)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                    
                    Text(club.category.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                        .minimumScaleFactor(0.5)
                }
                
                HStack(spacing: 8) {
                    if pendingResources.count > 0 {
                        IndicatorTag(icon: "cart.fill", count: pendingResources.count, color: .blue)
                    }
                    if pendingVenues.count > 0 {
                        IndicatorTag(icon: "mappin.and.ellipse", count: pendingVenues.count, color: .purple)
                    }
                    if pendingBudgets.count > 0 {
                        IndicatorTag(icon: "indianrupeesign.circle.fill", count: pendingBudgets.count, color: .green)
                    }
                }
                .padding(.top, 4)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 6) {
                Text("\(totalPending)")
                    .font(.subheadline.bold())
                    .foregroundColor(totalPending > 0 ? .orange : .secondary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(totalPending > 0 ? Color.orange.opacity(0.1) : Color.secondary.opacity(0.1))
                    .clipShape(Capsule())
                
                Text("Pending")
                    .font(.caption2.bold())
                    .foregroundColor(.secondary)
                    .textCase(.uppercase)
            }
            
            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundColor(.secondary.opacity(0.3))
        }
        .padding(16)
        .glassEffect(in: .rect(cornerRadius: 24))
        .contentShape(.rect)
    }
}

struct IndicatorTag: View {
    let icon: String
    let count: Int
    let color: Color
    
    var body: some View {
        HStack(spacing: 3) {
            Image(systemName: icon)
                .font(.system(size: 10))
            Text("\(count)")
                .font(.system(size: 10, weight: .bold))
        }
        .foregroundColor(color)
        .padding(.horizontal, 6)
        .padding(.vertical, 2)
        .background(color.opacity(0.1))
        .clipShape(Capsule())
    }
}

#Preview {
    NavigationStack {
        EventManagementApprovalClubsView()
            .environment(MockData.session(for: .faculty))
    }
}
