import SwiftUI

struct PresidentClubsView: View {
    @Environment(AppSession.self) var appSession
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    
                    // MARK: - Stats Grid
                    LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 16) {
                        PresidentStatCard(
                            icon: "square.grid.2x2.fill",
                            title: "Total clubs",
                            value: "\(appSession.clubStore.allClubs.count)",
                            color: .purple
                        )
                        
                        PresidentStatCard(
                            icon: "person.3.fill",
                            title: "Total members",
                            value: "1,500+", // Mocked as seen in Figma
                            color: .cyan
                        )
                        
                        PresidentStatCard(
                            icon: "calendar.badge.clock",
                            title: "Events",
                            value: "\(appSession.eventStore.events.count)",
                            color: .red
                        )
                        
                        PresidentStatCard(
                            icon: "checkmark.seal.fill",
                            title: "Attendance",
                            value: "95%", // Mocked for premium feel
                            color: .blue
                        )
                    }
                    .padding(.horizontal)
                    
                    // MARK: - Quick Actions
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Quick Actions")
                            .font(.title2)
                            .bold()
                        
                        VStack(spacing: 0) {
                            QuickActionRow(icon: "pencil.and.outline", title: "Assign task", color: .orange)
                            Divider().padding(.leading, 56)
                            QuickActionRow(icon: "person.badge.minus", title: "Remove member Access", color: .red)
                        }
                        .glassEffect(in: .rect(cornerRadius: 16))
                    }
                    .padding(.horizontal)
                    
                    // MARK: - Core Members
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Core Members")
                            .font(.title2)
                            .bold()
                        
                        VStack(spacing: 16) {
                            let coreMembers = MockData.allMockUsers.filter { $0.role == .clubLead || $0.role == .vicePresident }
                            
                            ForEach(coreMembers.prefix(5)) { member in
                                CoreMemberRow(user: member)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Clubs")
            .toolbarTitleDisplayMode(.inlineLarge)
        }
    }
}

// MARK: - Subviews
struct PresidentStatCard: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.1))
                    .frame(width: 36, height: 36)
                Image(systemName: icon)
                    .font(.headline)
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(value)
                    .font(.title3)
                    .bold()
                    .foregroundColor(.primary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .glassEffect(in: .rect(cornerRadius: 16))
    }
}

struct QuickActionRow: View {
    let icon: String
    let title: String
    let color: Color
    var action: (() -> Void)? = nil
    
    var body: some View {
        Group {
            if let action = action {
                Button(action: action) {
                    rowContent
                }
                .buttonStyle(.plain)
            } else {
                rowContent
            }
        }
    }
    
    private var rowContent: some View {
        HStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 8)
                    .fill(color.opacity(0.1))
                    .frame(width: 32, height: 32)
                Image(systemName: icon)
                    .font(.subheadline)
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(.body)
                .foregroundColor(.primary)
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

struct CoreMemberRow: View {
    let user: User
    
    var body: some View {
        HStack(spacing: 16) {
            Circle()
                .fill(Color.gray.opacity(0.1))
                .frame(width: 44, height: 44)
                .overlay(
                    Text(String(user.name.prefix(1)))
                        .font(.headline)
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(user.name)
                    .font(.body)
                    .bold()
                Text(user.role.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Button(action: {}) {
                Image(systemName: "message")
                    .font(.body)
                    .foregroundColor(.secondary)
                    .padding(8)
                    .glassEffect(in: .circle)
            }
        }
    }
}

#Preview {
    PresidentClubsView()
        .environment(AppSession())
}
