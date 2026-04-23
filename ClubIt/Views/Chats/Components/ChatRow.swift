import SwiftUI

struct ChatRow: View {
    let chat: Chat
    var onToggleExpansion: () -> Void
    var onTogglePin: () -> Void
    var onDelete: () -> Void
    var onAddChat: (() -> Void)? = nil
    
    var body: some View {
        HStack(spacing: 16) {
            // Avatar/Icon
            ZStack {
                chatIcon
            }
            .frame(width: 50, height: 50)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(chat.name)
                        .font(.headline)
                        .foregroundStyle(.primary)
                        .lineLimit(1)
                    
                    Spacer()
                    
                    if chat.type == .event {
                        Image(systemName: chat.isExpanded ? "chevron.up" : "chevron.down")
                            .font(.caption.bold())
                            .foregroundStyle(.secondary)
                    }
                }
                
                if !chat.lastMessage.isEmpty {
                    Text(chat.lastMessage)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }
            }
            
            if chat.unreadCount > 0 {
                Text("\(chat.unreadCount)")
                    .font(.caption2.bold())
                    .foregroundStyle(.white)
                    .frame(width: 20, height: 20)
                    .background(Color.goldenBrown)
                    .clipShape(Circle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .contentShape(Rectangle())
        // ... rest of contextMenu ...
    }
    
    @ViewBuilder
    private var chatIcon: some View {
        if let icon = chat.icon {
            if icon.contains("https") {
                AsyncImage(url: URL(string: icon)) { image in
                    image.resizable().scaledToFill()
                } placeholder: {
                    Circle().fill(Color(.secondarySystemBackground))
                }
                .frame(width: 50, height: 50)
                .clipShape(Circle())
            } else if UIImage(named: icon) != nil {
                Image(icon)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 50, height: 50)
                    .clipShape(Circle())
            } else {
                Image(systemName: icon)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(.white)
                    .frame(width: 50, height: 50)
                    .background(Color(.systemGray6))
                    .clipShape(Circle())
            }
        } else {
            Image(systemName: "person.3.fill")
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .foregroundStyle(.white)
                .frame(width: 50, height: 50)
                .background(Color(.systemGray6))
                .clipShape(Circle())
        }
    }
}
