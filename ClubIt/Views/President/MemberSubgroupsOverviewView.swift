import SwiftUI
import ClubItShared

struct MemberSubgroupsOverviewView: View {
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
                
                // MARK: - Associated Subgroups
                VStack(alignment: .leading, spacing: 16) {
                    Text("Associated Subgroups")
                        .font(.title3.bold())
                    
                    let associatedSubgroups = getAssociatedSubgroups()
                    
                    if associatedSubgroups.isEmpty {
                        Text("No subgroups associated with this member.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.secondary.opacity(0.05))
                            .cornerRadius(12)
                    } else {
                        VStack(spacing: 12) {
                            ForEach(associatedSubgroups) { subgroup in
                                AssociatedSubgroupRow(subgroup: subgroup, role: user.role == .subGroupLead ? "Lead" : "Oversight")
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
    
    private func getAssociatedSubgroups() -> [Subgroup] {
        if user.role == .subGroupLead {
            return appSession.subgroupStore.allSubgroups.filter { $0.subgroupLeadId == user.id }
        } else if user.role == .groupSubLead {
            return appSession.subgroupStore.allSubgroups.filter { $0.vicePresidentId == user.id }
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

struct AssociatedSubgroupRow: View {
    let subgroup: Subgroup
    let role: String
    
    var body: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.1))
                    .frame(width: 44, height: 44)
                Text(String(subgroup.name.prefix(1)))
                    .font(.headline)
                    .foregroundColor(.accentColor)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(subgroup.name)
                    .font(.body.bold())
                Text(subgroup.category.rawValue)
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
    MemberSubgroupsOverviewView(user: MockData.allMockUsers.first { $0.role == .subGroupLead }!)
        .environment(MockData.session(for: .groupLead))
}
