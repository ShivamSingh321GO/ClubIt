import SwiftUI
import ClubItShared

struct PresidentBudgetClubsView: View {
    @Environment(AppSession.self) var appSession
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                let allClubs = appSession.clubStore.allClubs
                
                if allClubs.isEmpty {
                    PresidentEmptyStateView(icon: "building.2.crop.circle.badge.exclamationmark", title: "No Clubs Found", message: "There are no clubs currently registered in the system.")
                } else {
                    LazyVStack(spacing: 16) {
                        ForEach(allClubs) { club in
                            NavigationLink(destination: PresidentClubBudgetDetailView(club: club)) {
                                PresidentClubBudgetCard(club: club)
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

struct PresidentClubBudgetCard: View {
    @Environment(AppSession.self) var appSession
    let club: Club
    
    var body: some View {
        let clubEvents = appSession.eventStore.events.filter { $0.clubId == club.id }
        let clubEventIds = Set(clubEvents.map { $0.id })
        let pendingBudgets = appSession.approvalStore.budgets.filter { 
            clubEventIds.contains($0.eventId ?? UUID()) && $0.status == .pending 
        }
        let pendingCount = pendingBudgets.count
        
        let firstPendingEventId = pendingBudgets.first?.eventId
        let event = appSession.eventStore.events.first(where: { $0.id == firstPendingEventId })
        
        HStack(spacing: 16) {
            // Event/Club Logo
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
                                Text(String((event?.name ?? club.name).prefix(1).uppercased()))
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
                    Text(String((event?.name ?? club.name).prefix(1).uppercased()))
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.accentColor)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                if let event = event {
                    Text(event.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text(club.name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                } else {
                    Text(club.name)
                        .font(.headline)
                        .lineLimit(1)
                    
                    Text(club.category.rawValue)
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
        PresidentBudgetClubsView()
            .environment(MockData.session(for: .president))
    }
}
