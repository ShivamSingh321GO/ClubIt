import SwiftUI
import ClubItShared

struct PresidentSubgroupsView: View {
    @Environment(AppSession.self) var appSession
    
    var body: some View {
        NavigationStack {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    
                    // MARK: - Actions
                    VStack(spacing: 0) {
                        NavigationLink(destination: PresidentBudgetSubgroupsView()) {
                            QuickActionRow(icon: "indianrupeesign.circle", title: "Approval Management", color: .accentColor)
                        }
                        .buttonStyle(.plain)
                        
                        Divider().padding(.leading, 56)
                        
                        NavigationLink(destination: PresidentAssignSubgroupView()) {
                            QuickActionRow(icon: "plus.rectangle.on.folder", title: "Assign Subgroup", color: .accentColor)
                        }
                        .buttonStyle(.plain)
                        
                        Divider().padding(.leading, 56)
                        
                        NavigationLink(destination: PresidentRemoveVPView()) {
                            QuickActionRow(icon: "person.badge.minus", title: "Remove Subgroup", color: .red)
                        }
                        .buttonStyle(.plain)
                    }
                    .glassEffect(in: .rect(cornerRadius: 16))
                    .padding(.horizontal)
                    
                    // MARK: - Core Members
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Core Members")
                            .font(.title2)
                            .bold()
                        
                        VStack(spacing: 16) {
                            let coreMembers = MockData.allMockUsers.filter { $0.role == .subGroupLead || $0.role == .groupSubLead }
                            
                            ForEach(coreMembers.prefix(5)) { member in
                                NavigationLink(destination: MemberSubgroupsOverviewView(user: member)) {
                                    CoreMemberRow(user: member)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                .padding(.vertical)
            }
            .navigationTitle("Manage")
            .toolbarTitleDisplayMode(.inlineLarge)
        }
    }
}

// MARK: - Subviews
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
        .contentShape(Rectangle())
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
            
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .contentShape(Rectangle())
    }
}

#Preview {
    PresidentSubgroupsView()
        .environment(AppSession())
}
