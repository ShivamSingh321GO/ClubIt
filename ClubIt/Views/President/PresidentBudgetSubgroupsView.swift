import SwiftUI
import ClubItShared

struct PresidentBudgetSubgroupsView: View {
    @Environment(AppSession.self) var appSession
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                let allSubgroups = appSession.subgroupStore.allSubgroups
                
                if allSubgroups.isEmpty {
                    PresidentEmptyStateView(icon: "building.2.crop.circle.badge.exclamationmark", title: "No Subgroups Found", message: "There are no subgroups currently registered in the system.")
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(allSubgroups) { subgroup in
                            NavigationLink(destination: PresidentSubgroupBudgetDetailView(subgroup: subgroup)) {
                                PresidentSubgroupBudgetCard(subgroup: subgroup)
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

struct PresidentSubgroupBudgetCard: View {
    @Environment(AppSession.self) var appSession
    let subgroup: Subgroup
    
    var body: some View {
        let subgroupEvents = appSession.eventStore.events.filter { $0.subgroupId == subgroup.id }
        let subgroupEventIds = Set(subgroupEvents.map { $0.id })
        let pendingBudgets = appSession.approvalStore.budgets.filter { 
            subgroupEventIds.contains($0.eventId ?? UUID()) && $0.status == .pending 
        }
        let pendingCount = pendingBudgets.count
        
        let firstPendingEventId = pendingBudgets.first?.eventId
        let event = appSession.eventStore.events.first(where: { $0.id == firstPendingEventId })
        
        HStack(spacing: 16) {
            // Event/Subgroup Logo
            ZStack {
                if let bannerImage = event?.bannerImage, !bannerImage.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
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
                                    .fill(Color.accentColor.gradient.opacity(0.1))
                                    .frame(width: 60, height: 60)
                                Text(String((event?.name ?? subgroup.name).prefix(1).uppercased()))
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.accentColor)
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
                        .fill(Color.accentColor.gradient.opacity(0.1))
                        .frame(width: 60, height: 60)
                    Text(String((event?.name ?? subgroup.name).prefix(1).uppercased()))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.accentColor)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                if let event = event {
                    Text(event.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text(subgroup.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text(subgroup.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text(subgroup.category.rawValue)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 6) {
                if pendingCount > 0 {
                    Text("!")
                        .font(.title3.bold())
                        .foregroundColor(.accentColor)
                        .frame(width: 40, height: 40)
                        .background(Color.accentColor.opacity(0.1))
                        .clipShape(Circle())
                }
            }
            
            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundColor(.secondary.opacity(0.3))
        }
        .padding(16)
        .glassEffect(in: .rect(cornerRadius: 20))
    }
}

struct PresidentEmptyStateView: View {
    let icon: String
    let title: String
    let message: String
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 60))
                .foregroundColor(.secondary.opacity(0.5))
            
            Text(title)
                .font(.title3.bold())
            
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(40)
        .frame(maxWidth: .infinity)
    }
}

#Preview {
    NavigationStack {
        PresidentBudgetSubgroupsView()
            .environment(MockData.session(for: .groupLead))
    }
}
