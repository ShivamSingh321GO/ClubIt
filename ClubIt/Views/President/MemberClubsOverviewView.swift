import SwiftUI
import ClubItShared

struct MemberClubsOverviewView: View {
    @Environment(AppSession.self) var appSession
    let user: User
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // MARK: - Header
                VStack(spacing: 16) {
                    Circle()
                        .fill(Color.accentColor.opacity(0.1))
                        .frame(width: 80, height: 80)
                        .overlay(
                            Text(String(user.name.prefix(1)))
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.accentColor)
                        )
                    
                    VStack(spacing: 4) {
                        Text(user.name)
                            .font(.title2.bold())
                        Text(user.role.rawValue)
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    
                    HStack(spacing: 20) {
                        InfoStat(title: "Course", value: user.course ?? "N/A")
                        Divider().frame(height: 30)
                        InfoStat(title: "Year", value: user.year ?? "N/A")
                    }
                    .padding()
                    .background(Color.secondary.opacity(0.05))
                    .cornerRadius(12)
                }
                .frame(maxWidth: .infinity)
                .padding(.top)
                
                // MARK: - Associated Clubs
                VStack(alignment: .leading, spacing: 16) {
                    Text("Associated Clubs")
                        .font(.title3.bold())
                    
                    let associatedClubs = getAssociatedClubs()
                    
                    if associatedClubs.isEmpty {
                        Text("No clubs associated with this member.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.secondary.opacity(0.05))
                            .cornerRadius(12)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(associatedClubs) { club in
                                AssociatedClubRow(club: club, role: user.role == .clubLead ? "Lead" : "Oversight")
                            }
                        }
                    }
                }
                .padding(.horizontal)
            }
        }
        .navigationTitle("Member Profile")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    private func getAssociatedClubs() -> [Club] {
        if user.role == .clubLead {
            return appSession.clubStore.allClubs.filter { $0.clubLeadId == user.id }
        } else if user.role == .vicePresident {
            return appSession.clubStore.allClubs.filter { $0.vicePresidentId == user.id }
        }
        return []
    }
}

struct InfoStat: View {
    let title: String
    let value: String
    
    var body: some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
            Text(value)
                .font(.subheadline.bold())
        }
    }
}

struct AssociatedClubRow: View {
    let club: Club
    let role: String
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.1))
                    .frame(width: 44, height: 44)
                Text(String(club.name.prefix(1)))
                    .font(.headline)
                    .foregroundColor(.accentColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(club.name)
                    .font(.body.bold())
                Text(club.category.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(role)
                .font(.caption2.bold())
                .padding(.horizontal, 8)
                .padding(.vertical, 4)
                .background(Color.accentColor.opacity(0.1))
                .foregroundColor(.accentColor)
                .cornerRadius(4)
        }
        .padding()
        .background(Color.secondary.opacity(0.05))
        .cornerRadius(16)
    }
}

#Preview {
    MemberClubsOverviewView(user: MockData.allMockUsers.first { $0.role == .clubLead }!)
        .environment(MockData.session(for: .president))
}
