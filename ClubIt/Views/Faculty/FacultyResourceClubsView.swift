import SwiftUI

struct FacultyResourceClubsView: View {
    @Environment(AppSession.self) var appSession
    
    var body: some View {
        ScrollView(showsIndicators: false) {
            VStack(alignment: .leading, spacing: 24) {
                // Removed Title and Subheadline as per user request
                
                if let facultyId = appSession.currentUser?.id {
                    let assignedClubs = appSession.clubStore.allClubs.filter { $0.facultyId == facultyId }
                    
                    if assignedClubs.isEmpty {
                        FacultyEmptyStateView(icon: "person.crop.circle.badge.exclamationmark", title: "No Assigned Clubs", message: "You are not assigned to any clubs as a faculty member.")
                    } else {
                        LazyVStack(spacing: 16) {
                            ForEach(assignedClubs) { club in
                                NavigationLink(destination: ClubResourcesDetailView(club: club)) {
                                    FacultyClubResourceCard(club: club)
                                }
                                .buttonStyle(.plain)
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

struct FacultyClubResourceCard: View {
    @Environment(AppSession.self) var appSession
    let club: Club
    
    var body: some View {
        let clubEvents = appSession.eventStore.events.filter { $0.clubId == club.id }
        let clubEventIds = Set(clubEvents.map { $0.id })
        let pendingCount = appSession.approvalStore.resources.filter { 
            clubEventIds.contains($0.eventId) && $0.status == .pending 
        }.count
        
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
                let pendingResources = appSession.approvalStore.resources.filter { 
                    clubEventIds.contains($0.eventId) && $0.status == .pending 
                }
                
                if let firstPendingEventId = pendingResources.first?.eventId,
                   let event = appSession.eventStore.events.first(where: { $0.id == firstPendingEventId }) {
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
