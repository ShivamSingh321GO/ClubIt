import SwiftUI

struct FacultyResourceClubsView: View {
    @Environment(AppSession.self) var appSession
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                // Removed Title and Subheadline as per user request
                
                if let facultyId = appSession.currentUser?.id {
                    let assignedClubs = appSession.clubStore.allClubs.filter { $0.facultyId == facultyId }
                    let clubIds = Set(assignedClubs.map { $0.id })
                    
                    let eventsWithPending = appSession.eventStore.events.filter { event in
                        clubIds.contains(event.clubId) && (
                            appSession.approvalStore.resources.contains { $0.eventId == event.id && $0.status == .pending } ||
                            appSession.approvalStore.approvals.contains { $0.eventId == event.id && $0.type == .venue && $0.status == .pending }
                        )
                    }.sorted(by: { $0.startDate > $1.startDate })
                    
                    if eventsWithPending.isEmpty {
                        FacultyEmptyStateView(icon: "calendar.badge.exclamationmark", title: "No Pending Requests", message: "There are no resource or venue requests currently requiring your approval.")
                    } else {
                        LazyVStack(spacing: 16) {
                            ForEach(eventsWithPending) { event in
                                if let club = assignedClubs.first(where: { $0.id == event.clubId }) {
                                    NavigationLink(destination: ClubResourcesDetailView(club: club, event: event)) {
                                        FacultyEventResourceCard(event: event, club: club)
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                        .padding(.horizontal)
                    }
                }
            }
            .padding(.vertical)
        }
        .navigationTitle("Approval Management")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct FacultyEventResourceCard: View {
    @Environment(AppSession.self) var appSession
    let event: Event
    let club: Club
    
    var body: some View {
        let pendingResources = appSession.approvalStore.resources.filter { 
            $0.eventId == event.id && $0.status == .pending 
        }
        let pendingVenues = appSession.approvalStore.approvals.filter { 
            $0.eventId == event.id && $0.type == .venue && $0.status == .pending 
        }
        
        let pendingCount = pendingResources.count + pendingVenues.count
        
        HStack(spacing: 16) {
            // Club Logo/Initials
            ZStack {
                Circle()
                    .fill(Color.blue.gradient.opacity(0.1))
                    .frame(width: 60, height: 60)
                
                Text(String(club.name.prefix(1)))
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(.blue)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(event.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(club.name)
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 6) {
                HStack(spacing: 4) {
                    Image(systemName: "clock.badge.exclamationmark")
                    Text("\(pendingCount)")
                }
                .font(.subheadline.bold())
                .foregroundColor(pendingCount > 0 ? .orange : .secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(pendingCount > 0 ? Color.orange.opacity(0.1) : Color.secondary.opacity(0.1))
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
}

struct FacultyEmptyStateView: View {
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
        FacultyResourceClubsView()
            .environment(MockData.session(for: .faculty))
    }
}
