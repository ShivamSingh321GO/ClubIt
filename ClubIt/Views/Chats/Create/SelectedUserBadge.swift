import SwiftUI

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
    let user: User
    let isSelected: Bool
    let onToggle: () -> Void
    
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
                    
                    Text(getClubSubtitle(for: user.name))
                        .font(.caption2)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }
        }
        .buttonStyle(.plain)
    }
    
    private func getClubSubtitle(for name: String) -> String {
        switch name {
        case "Ayush", "Shivam": return "Quizzards"
        case "Mayank", "Ansh": return "TechnoJam"
        case "Kamakshi", "Anushka": return "NoteVeda"
        default: return "Club member"
        }
    }
}

struct UserGridItem: View {
    let user: User
    
    var body: some View {
        VStack(spacing: 8) {
            UserAvatarView(name: user.name, profileImg: user.profileImg, imageData: user.imageData, size: 70)
            
            VStack(spacing: 2) {
                Text(user.name)
                    .font(.subheadline.bold())
                    .lineLimit(1)
                
                Text(getClubName(for: user.name))
                    .font(.caption2)
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
        }
    }
    
    private func getClubName(for name: String) -> String {
        switch name {
        case "Ayush", "Shivam": return "Quizzards"
        case "Mayank", "Ansh": return "TechnoJam"
        case "Kamakshi", "Anushka": return "NoteVeda"
        default: return "Club member"
        }
    }
}
