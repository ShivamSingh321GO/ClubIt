import SwiftUI

struct PinnedChatItem: View {
    let name: String
    let icon: String
    let unreadCount: Int
    var onTogglePin: () -> Void
    var onDelete: () -> Void
    
    var body: some View {
        VStack(spacing: 8) {
            ZStack(alignment: .topTrailing) {
                // Avatar Circle
                if icon.contains("https") {
                    AsyncImage(url: URL(string: icon)) { image in
                        image
                            .resizable()
                            .scaledToFill()
                    } placeholder: {
                        Circle().fill(Color(.secondarySystemBackground))
                    }
                    .frame(width: 60, height: 60)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color(.separator), lineWidth: 0.5))
                } else if UIImage(named: icon) != nil {
                    Image(icon)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipShape(Circle())
                } else {
                    Image(systemName: icon)
                        .font(.title)
                        .foregroundStyle(.orange)
                        .frame(width: 60, height: 60)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(Circle())
                }
                
                // Pin sign indicator
                Image(systemName: "pin.fill")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.white)
                    .frame(width: 20, height: 20)
                    .background(Color.gray)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.chatBackground, lineWidth: 2))
                    .offset(x: -2, y: -2)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                
                // Unread Badge
                if unreadCount > 0 {
                    Text("\(unreadCount)")
                        .font(.caption2.bold())
                        .foregroundStyle(.white)
                        .frame(width: 22, height: 22)
                        .background(Color.goldenBrown)
                        .clipShape(Circle())
                        .overlay(Circle().stroke(.white, lineWidth: 2))
                        .offset(x: -2, y: 2)
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topTrailing)
                }
            }
            .frame(width: 60, height: 60)
            
            // Name label below
            Text(String(name.split(separator: " ").first ?? ""))
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .frame(width: 65)
        .contentShape(Rectangle())
        .contextMenu {
            Button {
                onTogglePin()
            } label: {
                Label("Unpin", systemImage: "pin.slash")
            }
            
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete Chat", systemImage: "trash")
            }
        }
    }
}
