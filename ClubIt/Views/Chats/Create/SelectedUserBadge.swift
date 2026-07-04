import SwiftUI
import ClubItShared

struct SelectedUserBadge: View {
    let user: User
    let onRemove: () -> Void
    
    var body: some View {
        VStack(spacing: 4) {
            ZStack(alignment: .topTrailing) {
                UserAvatarView(name: user.name, profileImg: user.profileImg, imageData: user.imageData, size: 50)
                
                Button(action: onRemove) {
                    Image(systemName: "xmark.circle.fill")
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(.white, .gray)
                        .font(.caption)
                }
                .offset(x: 2, y: -2)
            }
            
            Text(user.name)
                .font(.caption2)
                .lineLimit(1)
        }
    }
}

struct UserSelectionGridItem: View {
    @Environment(AppSession.self) private var appSession
    let user: User
    let isSelected: Bool
    let onToggle: () -> Void
    
    private var subgroupName: String {
        if let subgroupId = user.subgroupId,
           let subgroup = appSession.subgroupStore.allSubgroups.first(where: { $0.id == subgroupId }) {
            return subgroup.name
        }
        return roleName(for: user.role)
    }
    
    var body: some View {
        Button(action: onToggle) {
            VStack(spacing: 8) {
                ZStack(alignment: .bottomTrailing) {
                    UserAvatarView(name: user.name, profileImg: user.profileImg, imageData: user.imageData, size: 70)
                        .overlay {
                            if isSelected {
                                Circle()
                                    .stroke(Color.blue, lineWidth: 2)
                            }
                        }
                    
                    if isSelected {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.blue)
                            .background(Circle().fill(.white))
                            .offset(x: 2, y: 2)
                    }
                }
                
                VStack(spacing: 2) {
                    Text(user.name)
                        .font(.subheadline.bold())
                        .foregroundColor(.primary)
                        .lineLimit(1)
                    
                    Text(subgroupName)
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    private func roleName(for role: AppRole) -> String {
        switch role {
        case .superAdmin: return "SuperAdmin"
        case .admin: return "Admin"
        case .groupLead: return "Group Lead"
        case .groupSubLead: return "Group SubLead"
        case .subGroupLead: return "SubGroup Lead"
        case .subGroupMember: return "SubGroup Member"
        case .guest: return "Guest"
        }
    }
}

struct UserGridItem: View {
    @Environment(AppSession.self) private var appSession
    let user: User
    
    private var subgroupName: String {
        if let subgroupId = user.subgroupId,
           let subgroup = appSession.subgroupStore.allSubgroups.first(where: { $0.id == subgroupId }) {
            return subgroup.name
        }
        return roleName(for: user.role)
    }
    
    var body: some View {
        VStack(spacing: 8) {
            UserAvatarView(name: user.name, profileImg: user.profileImg, imageData: user.imageData, size: 70)
            
            VStack(spacing: 2) {
                Text(user.name)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                
                Text(subgroupName)
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
    }
    
    private func roleName(for role: AppRole) -> String {
        switch role {
        case .superAdmin: return "SuperAdmin"
        case .admin: return "Admin"
        case .groupLead: return "Group Lead"
        case .groupSubLead: return "Group SubLead"
        case .subGroupLead: return "SubGroup Lead"
        case .subGroupMember: return "SubGroup Member"
        case .guest: return "Guest"
        }
    }
}
